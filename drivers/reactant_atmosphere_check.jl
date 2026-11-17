# Reactant check, atmosphere alone: SpeedyWeather PrimitiveWetModel gradient under Reactant vs
# plain Enzyme on CPU (Julia 1.11), following SpeedyWeather's test/reactant/differentation.jl and
# differentiation_primitive_wet.jl (which upstream CI does not run: the CPU Enzyme compile is slow).
# Loss: sum of squared vorticity after n steps; gradient w.r.t. the initial prognostic vorticity.
#
#   mkdir -p run/reactant-atmosphere && cp drivers/reactant_atmosphere_check.jl run/reactant-atmosphere/
#   cd run/reactant-atmosphere && caffeinate -i julia --project=../.. reactant_atmosphere_check.jl

#####
##### Settings
#####

truncation   = 32          # as in SpeedyWeather's tests (T32L8)
nsteps       = 6           # > 4 so Reactant keeps the traced while loop
spinup_steps = 5
checkpoint   = 2           # Reactant.Binomial budget
outfile      = "reactant_atmosphere_check.nc"

#####
##### Setup
#####

using SpeedyWeather, Reactant, Enzyme
using CUDA   # Reactant compiles KernelAbstractions kernels through its CUDA extension, even on CPU (deferred: CUDA.jl not yet in the environment)
using DifferentiableEarth: provenance, settings_block
using LinearAlgebra, NCDatasets, Printf
Reactant.set_default_backend("cpu")

# PrimitiveWet as in SpeedyWeather's tests: no convection, constant longwave transmissivity
# (Frierson radiation without convection amplifies ULP-level CPU/Reactant differences chaotically)
function create_model(arch)
    sg = SpectralGrid(; architecture = arch, nlayers = 8, truncation)
    transmissivity = ConstantLongwaveTransmissivity(sg)
    radiation = Radiation(sg, longwave = OneBandLongwave(sg; transmissivity))
    PrimitiveWetModel(sg; spectral_transform = SpectralTransform(sg), feedback = nothing,
                      initial_conditions = InitialConditions(sg, PrimitiveWetModel), radiation, convection = nothing)
end

sync!(sim_cpu, sim_rx) = SpeedyWeather.copy!(first(SpeedyWeather.unpack(sim_cpu)), first(SpeedyWeather.unpack(sim_rx)))

t_init = @elapsed begin
    sim_cpu = initialize!(create_model(SpeedyWeather.CPU()))
    sim_rx = initialize!(create_model(SpeedyWeather.ReactantDevice()))
    run!(sim_cpu, steps = spinup_steps); run!(sim_rx, steps = spinup_steps)
    sync!(sim_cpu, sim_rx)
    initialize!(sim_cpu, steps = 1); initialize!(sim_rx, steps = 1)
    sync!(sim_cpu, sim_rx)
end
@info "initialized CPU and Reactant simulations" t_init

vars_rx, model_rx = SpeedyWeather.unpack(sim_rx)
vars_cpu, model_cpu = SpeedyWeather.unpack(sim_cpu)

function loss_n_steps(vars, model, n, options = (;))
    SpeedyWeather.time_steps!(Simulation(vars, model), n; options...)
    return sum(abs2, vars.prognostic.vorticity.data)
end

opts = SpeedyWeather.reactant_compile_options(; raise_first = true)
function grad_rx(vars, model, n, options)
    dvars = Enzyme.make_zero(vars)
    @jit compile_options = opts Enzyme.autodiff(Reverse, loss_n_steps, Active,
        Duplicated(vars, dvars), Const(model), Const(n), Const(options))
    return Array(dvars.prognostic.vorticity.data)
end
function grad_cpu(vars, model, n)
    dvars = Enzyme.make_zero(vars)
    Enzyme.autodiff(set_runtime_activity(Reverse), loss_n_steps, Active,
        Duplicated(vars, dvars), Const(model), Const(n))
    return Array(dvars.prognostic.vorticity.data)
end

t_rx = @elapsed g_rx = grad_rx(deepcopy(vars_rx), model_rx, nsteps, (; checkpointing = Reactant.Binomial(checkpoint)))
@info "Reactant gradient (compile + run)" t_rx finite = all(isfinite, g_rx)
t_cpu = @elapsed g_cpu = grad_cpu(deepcopy(vars_cpu), model_cpu, nsteps)
@info "plain Enzyme CPU gradient (compile + run)" t_cpu finite = all(isfinite, g_cpu)
relerr = norm(g_rx - g_cpu) / norm(g_cpu)
@printf("PrimitiveWet T%d L8, %d steps: |g_reactant - g_enzyme| / |g_enzyme| = %.2e  (SpeedyWeather test tolerance 1e-3)\n",
        truncation, nsteps, relerr)

isfile(outfile) && rm(outfile)
NCDataset(outfile, "c") do ds
    for (k, v) in provenance(; driver = abspath(@__FILE__), settings = settings_block(@__FILE__),
                             title = "Reactant vs Enzyme gradient check, SpeedyWeather PrimitiveWetModel")
        ds.attrib[k] = v
    end
    ds.attrib["relerr_reactant_vs_enzyme"] = relerr
    ds.attrib["t_reactant_s"] = t_rx
    ds.attrib["t_enzyme_cpu_s"] = t_cpu
    defVar(ds, "grad_vorticity_reactant", vec(g_rx), ("coef",); attrib = Dict("long_name" => "d loss / d initial vorticity (spectral)"))
    defVar(ds, "grad_vorticity_enzyme", vec(g_cpu), ("coef",))
end

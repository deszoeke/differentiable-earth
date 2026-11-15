#####
##### ToyCoupled: Lorenz-96 atmosphere + slab ocean + recharge-oscillator ENSO
#####
# A cheap stand-in for the coupled Earth system model with the same three time scales:
# chaotic "weather" (days), ocean memory (months) and an ENSO-like oscillation (years).
# Model time unit = 1 Lorenz-96 time unit ≈ 5 days.
#
# State x = [X₁…X_K ; T₁…T_K ; Tₑ ; h]
#   X_k  atmosphere sector variable (Lorenz-96)
#   T_k  slab-ocean temperature anomaly under sector k
#   Tₑ   eastern equatorial Pacific temperature anomaly (recharge oscillator)
#   h    western Pacific thermocline depth anomaly (recharge oscillator)
#
#   dX_k/dt = (X_{k+1} − X_{k−2}) X_{k−1} − X_k + F + α T_k + αₑ p_k Tₑ
#   dT_k/dt = −λ T_k + β (X_k − X̄) + κ (T_{k+1} − 2T_k + T_{k−1})
#   dTₑ/dt  = R Tₑ + γ h + σ ξ − ϵ Tₑ³
#   dh/dt   = −r h − a (μ Tₑ + ξ)
# where ξ = mean over the "equatorial" sectors of (X_k − X̄) (wind-burst forcing), and p_k is
# a fixed teleconnection pattern. The code is written with whole-array operations
# (circshift, broadcasts, reductions, vcat), with no scalar indexing or data-dependent
# branches, so that Enzyme and Reactant can trace it.

"""
    ToyParams(; kwargs...)

Parameters of [`ToyCoupled`](@ref), in model time units (1 ≈ 5 days). Defaults give
Lorenz-96 chaos (F = 8), ocean damping of ~90 days, and an ENSO-like period of roughly
4 years. See the comments in `toy_coupled.jl` for the equations.
"""
Base.@kwdef struct ToyParams{FT}
    K::Int = 36            # number of sectors
    F::FT = 8.0            # Lorenz-96 forcing
    Xmean::FT = 2.3        # approximate climatological mean of X (for anomalies)
    α::FT = 0.5            # ocean → atmosphere forcing per K of T_k
    αₑ::FT = 1.0           # ENSO teleconnection amplitude
    λ::FT = 1 / 18         # slab-ocean damping (≈ 90 days)
    β::FT = 0.02           # atmosphere → ocean heat flux
    κ::FT = 0.05           # ocean diffusion between sectors
    R::FT = 0.002          # recharge oscillator: Bjerknes growth
    γ::FT = 0.02           # thermocline feedback
    σ::FT = 0.01           # wind-burst forcing of Tₑ
    ϵ::FT = 0.01           # cubic damping of Tₑ
    r::FT = 0.001          # thermocline damping
    a::FT = 0.022          # wind stress → thermocline
    μ::FT = 1.0            # Tₑ → wind stress coupling
    neq::Int = 4           # number of equatorial sectors (1:neq)
end

"""
    ToyCoupled(params = ToyParams(); dt = 0.05)

Toy coupled model (Lorenz-96 atmosphere, slab ocean, recharge-oscillator ENSO) with RK4
time stepping. `dt = 0.05` ≈ 6 hours.
"""
struct ToyCoupled{FT, V} <: AbstractPropagator
    params::ToyParams{FT}
    dt::FT
    eqmask::V       # 1 on equatorial sectors, 0 elsewhere (length K)
    pattern::V      # teleconnection pattern p_k (length K)
end

function ToyCoupled(params::ToyParams{FT} = ToyParams(); dt = FT(0.05)) where {FT}
    K = params.K
    k = 1:K
    eqmask = FT.(k .<= params.neq)
    pattern = FT.(cos.(2π .* (k .- 1) ./ K))   # wavenumber-1 teleconnection
    return ToyCoupled(params, FT(dt), eqmask, pattern)
end

state_length(m::ToyCoupled) = 2 * m.params.K + 2
timestep(m::ToyCoupled) = m.dt

function state_slices(m::ToyCoupled)
    K = m.params.K
    return (atmosphere = 1:K, ocean = (K + 1):(2K), Te = (2K + 1):(2K + 1), h = (2K + 2):(2K + 2))
end

"""
    tendency(m::ToyCoupled, x)

Right-hand side dx/dt of the toy model. Returns a new vector.
"""
function tendency(m::ToyCoupled, x)
    p = m.params
    K = p.K
    X = x[1:K]
    T = x[(K + 1):(2K)]
    Te = x[(2K + 1):(2K + 1)]      # 1-element slices: no scalar indexing
    h = x[(2K + 2):(2K + 2)]

    Xa = X .- p.Xmean
    ξ = sum(m.eqmask .* Xa) / p.neq          # equatorial wind-burst forcing (scalar)

    dX = (circshift(X, -1) .- circshift(X, 2)) .* circshift(X, 1) .- X .+ p.F .+
         p.α .* T .+ p.αₑ .* m.pattern .* Te
    dT = -p.λ .* T .+ p.β .* Xa .+ p.κ .* (circshift(T, -1) .- 2 .* T .+ circshift(T, 1))
    dTe = p.R .* Te .+ p.γ .* h .+ p.σ .* ξ .- p.ϵ .* Te .^ 3
    dh = -p.r .* h .- p.a .* (p.μ .* Te .+ ξ)

    return vcat(dX, dT, dTe, dh)
end

"""
    advance(m::ToyCoupled, x)

One fourth-order Runge–Kutta step of length `m.dt`.
"""
function advance(m::ToyCoupled, x)
    dt = m.dt
    k1 = tendency(m, x)
    k2 = tendency(m, x .+ (dt / 2) .* k1)
    k3 = tendency(m, x .+ (dt / 2) .* k2)
    k4 = tendency(m, x .+ dt .* k3)
    return x .+ (dt / 6) .* (k1 .+ 2 .* k2 .+ 2 .* k3 .+ k4)
end

"""
    initial_state(m::ToyCoupled; rng = Random.default_rng(), amplitude = 0.01)

A state near the Lorenz-96 rest point with small random perturbations, plus a small ENSO
anomaly. Spin up with `propagate` before using it as a nature-run start.
"""
function initial_state(m::ToyCoupled{FT}; rng = Random.default_rng(), amplitude = FT(0.01)) where {FT}
    K = m.params.K
    X = m.params.F .+ amplitude .* randn(rng, FT, K)
    T = amplitude .* randn(rng, FT, K)
    return vcat(X, T, FT[0.1], FT[0])
end

variable_metadata(m::ToyCoupled) = (
    atmosphere = (units = "1", long_name = "Lorenz-96 atmosphere sector variable X", dim = "sector"),
    ocean = (units = "K", long_name = "slab-ocean temperature anomaly T", dim = "sector"),
    Te = (units = "K", long_name = "eastern equatorial temperature anomaly (recharge oscillator)", dim = nothing),
    h = (units = "m", long_name = "western thermocline depth anomaly (recharge oscillator, nondimensional scale)", dim = nothing),
)

"""
    parameter_attributes(m::ToyCoupled)

Model parameters and time step as `param_*` global attributes for NetCDF output.
"""
function parameter_attributes(m::ToyCoupled)
    p = m.params
    d = Dict{String, Any}("param_$(f)" => getfield(p, f) for f in fieldnames(typeof(p)))
    d["param_dt"] = m.dt
    d["time_unit_days"] = 5.0
    return d
end

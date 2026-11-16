"""
    DifferentiableEarth

Coupled ocean–atmosphere predictability and targeted observations with a differentiable
Earth system model (NumericalEarth + SpeedyWeather + Oceananigans, via Reactant/Enzyme).
See `docs/plan.md`.
"""
module DifferentiableEarth

using Random
using Dates
using Pkg
using NCDatasets
using ReactantCore: @trace
using Enzyme

export AbstractPropagator, propagate, trajectory, advance, timestep, state_length, state_slices
export ToyCoupled, ToyParams, tendency, initial_state, parameter_attributes
export provenance, settings_block, write_trajectory, variable_metadata
export jvp, vjp, gradient_J, Component

include("propagator.jl")
include("toy/toy_coupled.jl")
include("io.jl")
include("diagnostics.jl")
include("ad.jl")

end # module

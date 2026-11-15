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

export AbstractPropagator, propagate, trajectory, advance, timestep, state_length, state_slices
export ToyCoupled, ToyParams, tendency, initial_state, parameter_attributes
export provenance, settings_block, write_trajectory, variable_metadata

include("propagator.jl")
include("toy/toy_coupled.jl")
include("io.jl")

end # module

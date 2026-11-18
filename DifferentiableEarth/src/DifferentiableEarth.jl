"""
    DifferentiableEarth

Coupled ocean–atmosphere predictability and targeted observations with a differentiable
Earth system model (NumericalEarth + SpeedyWeather + Oceananigans, via Reactant/Enzyme).
See `docs/plan.md`.
"""
module DifferentiableEarth

using Random
using Dates
using TOML
using NCDatasets
using ReactantCore: @trace
using Enzyme
using LinearAlgebra
using SparseArrays

export AbstractPropagator, propagate, trajectory, advance, timestep, state_length, state_slices
export ToyCoupled, ToyParams, tendency, initial_state, parameter_attributes
export provenance, settings_block, write_trajectory, variable_metadata
export jvp, vjp, gradient_J, Component
export slow_indices, forecast_metric_series, ensemble_fd_sensitivity, ensemble_mean_gradient
export regression_sensitivity, fit_lim, lim_sensitivity
export RegriddingWeights, regrid, regridding_checks, save_regridding_weights, load_regridding_weights
export build_coupled_model, regridding_weights
export predictable_components, predictive_information, pooled_forecast_covariance, lim_forecast_covariance

include("propagator.jl")
include("toy/toy_coupled.jl")
include("io.jl")
include("diagnostics.jl")
include("ad.jl")
include("sensitivity.jl")
include("coupled/regridding.jl")
include("predictability.jl")

end # module

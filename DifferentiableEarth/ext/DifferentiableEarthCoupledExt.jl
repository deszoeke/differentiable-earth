module DifferentiableEarthCoupledExt

# Coupled-model code that needs NumericalEarth, SpeedyWeather, Oceananigans and
# ConservativeRegridding. Loaded automatically when all four are loaded alongside
# DifferentiableEarth, so `using DifferentiableEarth` alone stays fast for toy-model work.

using DifferentiableEarth
using DifferentiableEarth: RegriddingWeights
import DifferentiableEarth: build_coupled_model, regridding_weights
using NumericalEarth, SpeedyWeather, Oceananigans, ConservativeRegridding
using SparseArrays

function build_coupled_model(; ocean_size = (180, 80, 20), ocean_latitude = (-80, 80), ocean_depth = 4000,
                             truncation = 31, nlayers = 8, stop_time = 5 * 86400.0)
    grid = LatitudeLongitudeGrid(Oceananigans.CPU(); size = ocean_size, halo = (7, 7, 4), longitude = (0, 360),
                                 latitude = ocean_latitude, z = (-ocean_depth, 0))
    ocean = NumericalEarth.Oceans.ocean_simulation(grid)
    Tᵢ(λ, φ, z) = 2 + 26 * cosd(φ)^2 * exp(z / 500)
    Oceananigans.set!(ocean.model, T = Tᵢ, S = 35)
    spectral_grid = SpeedyWeather.SpectralGrid(; NF = Float64, truncation, nlayers, Grid = FullClenshawGrid)
    atmosphere = NumericalEarth.atmosphere_simulation(spectral_grid; stop_time)
    earth_model = EarthSystemModel(; atmosphere, sea_ice = default_sea_ice(), ocean)
    Δt = convert(eltype(grid), atmosphere.model.time_stepping.Δt)
    return (; earth_model, ocean, atmosphere, grid, spectral_grid, Δt)
end

describe(grid::Oceananigans.Grids.AbstractGrid) = string("Oceananigans exchange grid ", summary(grid))
describe(sg::SpeedyWeather.SpectralGrid) = string("SpeedyWeather ", summary(sg.grid), ", T", sg.trunc)

function weights(r, src, dst)
    I = SparseMatrixCSC{Float64, Int}(r.intersections)
    return RegriddingWeights(I, Vector{Float64}(r.dst_areas), Vector{Float64}(r.src_areas), src, dst)
end

function regridding_weights(earth_model)
    ex = earth_model.interfaces.exchanger
    reg = ex.atmosphere.regridder
    spectral_grid = earth_model.atmosphere.model.spectral_grid
    atm, xg = describe(spectral_grid), describe(ex.grid)
    return (; from_atmosphere = weights(reg.from_atmosphere, atm, xg),
            to_atmosphere = weights(reg.to_atmosphere, xg, atm))
end

end # module

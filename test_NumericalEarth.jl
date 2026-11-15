using Oceananigans
using SpeedyWeather
using ConservativeRegridding
using NumericalEarth

using Oceananigans.Units

arch = Oceananigans.CPU()
stop_time = 5days
#atmos_arch = SpeedyWeather.CPU()

ocean_grid = LatitudeLongitudeGrid(arch; size=(180, 90, 20), longitude=(0, 360), latitude=(-80, 80), z=(-4000, 0))
ocean_grid = LatitudeLongitudeGrid(arch;
    size = (180, 90, 20),
    halo = (7, 7, 4),
    longitude = (0, 360),
    latitude = (-80, 80),
    z = (-4000, 0)
)
ocean = ocean_simulation(ocean_grid; Δt=20minutes)
# ocean_model = HydrostaticFreeSurfaceModel(ocean_grid; tracers=(:T, :S))
# ocean = Oceananigans.Simulation(ocean_model; Δt=20minutes, stop_time=stop_time)

spectral_grid = SpeedyWeather.SpectralGrid(;
    truncation = 63,
    nlayers = 8,
    Grid = FullClenshawGrid
)
atmos_model = PrimitiveWetModel(spectral_grid)
# atmos_sim = SpeedyWeather.initialize!(atmos_model)
atmos_sim = SpeedyWeather.Simulation(atmos_model) # newer Simulation generator
atmosphere = atmosphere_simulation(spectral_grid; stop_time=stop_time)

coupled_model = OceanSeaIceModel(ocean; atmosphere)

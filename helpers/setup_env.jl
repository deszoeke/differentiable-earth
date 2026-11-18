# Resolve the project environments on Julia 1.11 at the target versions in docs/plan.md.
# Run from the repository root:  julia +1.11 helpers/setup_env.jl
# Slow the first time (Reactant downloads several GB and precompiles for a long time).
using Pkg

VERSION.major == 1 && VERSION.minor == 11 || error("run with Julia 1.11 (julia +1.11), not $VERSION; see docs/julia_pin.md")

repo = dirname(@__DIR__)

# target versions (checked 2026-11-15)
model = [
    PackageSpec(name = "Reactant", version = "0.2.308"),
    PackageSpec(name = "Enzyme", version = "0.13.219"),
    PackageSpec(name = "Oceananigans", version = "0.117.2"),
    PackageSpec(name = "NumericalEarth", version = "0.9.3"),
    PackageSpec(name = "SpeedyWeather", version = "0.24.1"),
    PackageSpec(name = "ConservativeRegridding", version = "0.2.21"),
]
analysis = [
    PackageSpec(name = "KrylovKit", version = "0.10.4"),
    PackageSpec(name = "NCDatasets"),
    PackageSpec(name = "PrecompileTools"),
    PackageSpec(name = "LinearAlgebra"),
    PackageSpec(name = "SparseArrays"),
    PackageSpec(name = "Statistics"),
    PackageSpec(name = "Random"),
]

# package environment
Pkg.activate(joinpath(repo, "PredictableOcean"))
Pkg.add(vcat(model, analysis))

# main / driver environment: the package (path source) plus the model packages for drivers
Pkg.activate(repo)
Pkg.develop(path = joinpath(repo, "PredictableOcean"))
Pkg.add(vcat(model, [PackageSpec(name = "NCDatasets")]))

Pkg.precompile()
Pkg.status()
println("setup_env.jl done on Julia ", VERSION)

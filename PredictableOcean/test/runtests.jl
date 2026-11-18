using Test
using PredictableOcean
using Random
using Statistics
using LinearAlgebra

const TEST_REACTANT = get(ENV, "DE_TEST_REACTANT", "false") == "true"   # slow: loads and compiles Reactant
if TEST_REACTANT
    using Reactant
end

@testset "PredictableOcean" begin
    include("test_toy.jl")
    include("test_ad.jl")
    TEST_REACTANT && include("test_reactant.jl")
end

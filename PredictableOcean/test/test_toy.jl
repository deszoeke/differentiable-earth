@testset "ToyCoupled" begin
    m = ToyCoupled()
    K = m.params.K
    rng = Xoshiro(1)
    x0 = initial_state(m; rng)

    @testset "shapes and slices" begin
        @test length(x0) == state_length(m) == 2K + 2
        s = state_slices(m)
        @test sort(vcat(collect.(values(s))...)) == 1:state_length(m)
        @test length(tendency(m, x0)) == length(x0)
        @test length(advance(m, x0)) == length(x0)
    end

    @testset "uncoupled limit is Lorenz-96" begin
        p0 = ToyParams(α = 0.0, αₑ = 0.0)
        m0 = ToyCoupled(p0)
        x = initial_state(m0; rng = Xoshiro(2))
        X = x[1:K]
        dX96 = (circshift(X, -1) .- circshift(X, 2)) .* circshift(X, 1) .- X .+ p0.F
        @test tendency(m0, x)[1:K] ≈ dX96
    end

    @testset "deterministic and pure" begin
        x = copy(x0)
        y1 = propagate(m, x, 100)
        @test x == x0                       # step does not mutate its input
        @test propagate(m, x0, 100) == y1
    end

    @testset "bounded, chaotic atmosphere, slow ocean" begin
        xs = propagate(m, x0, 2000)         # spin-up, 100 time units ≈ 500 days
        X = trajectory(m, xs, 4000; every = 4)
        @test all(isfinite, X)
        s = state_slices(m)
        @test 1 < std(X[s.atmosphere, :]) < 10      # Lorenz-96 variability
        @test maximum(abs, X[s.Te, :]) < 10          # ENSO bounded by cubic damping

        # sensitivity to initial conditions: tiny perturbation grows in the atmosphere
        δ = 1e-8 .* randn(Xoshiro(3), length(xs))
        d = propagate(m, xs .+ δ, 400) .- propagate(m, xs, 400)   # 20 time units
        @test maximum(abs, d[s.atmosphere]) > 1e-4
    end
end

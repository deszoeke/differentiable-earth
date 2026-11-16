@testset "AD under Reactant matches plain Enzyme" begin
    m = ToyCoupled()
    x = propagate(m, initial_state(m; rng = Xoshiro(1)), 2000)
    N = state_length(m)
    v = randn(Xoshiro(2), N); λ = randn(Xoshiro(3), N); n = 56
    mr, xr, vr, λr = Reactant.to_rarray(m), Reactant.to_rarray(x), Reactant.to_rarray(v), Reactant.to_rarray(λ)
    prop_c = Reactant.@compile propagate(mr, xr, n)
    @test Array(prop_c(mr, xr, n)) ≈ propagate(m, x, n) rtol = 1e-10
    @test Array(xr) == x                          # input not overwritten (copy before @trace)
    jvp_c = Reactant.@compile jvp(mr, xr, vr, n, false)
    @test Array(jvp_c(mr, xr, vr, n, false)) ≈ jvp(m, x, v, n) rtol = 1e-9
    vjp_c = Reactant.@compile vjp(mr, xr, λr, n, true)   # with checkpointing
    @test Array(vjp_c(mr, xr, λr, n, true)) ≈ vjp(m, x, λ, n) rtol = 1e-9
end

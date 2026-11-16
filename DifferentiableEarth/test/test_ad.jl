@testset "AD: tangent-linear and adjoint (plain Enzyme)" begin
    m = ToyCoupled()
    x = propagate(m, initial_state(m; rng = Xoshiro(1)), 2000)
    N = state_length(m)
    v = randn(Xoshiro(2), N)
    λ = randn(Xoshiro(3), N)
    n = 56                                           # 2 weeks
    Lv = jvp(m, x, v, n)
    Lλ = vjp(m, x, λ, n)

    @test propagate(m, x, n) == propagate(m, x, n)   # pure: input not modified
    @test dot(Lv, λ) ≈ dot(v, Lλ) rtol = 1e-12       # dot-product (adjoint) test

    # finite differences converge to the JVP as ε shrinks
    fd(ε) = (propagate(m, x .+ ε .* v, n) .- propagate(m, x .- ε .* v, n)) ./ (2ε)
    errs = [norm(fd(ε) - Lv) / norm(Lv) for ε in (1e-5, 1e-6, 1e-7)]
    @test errs[3] < 1e-6
    @test errs[1] > errs[3]

    # gradient of a forecast metric equals the VJP of its (linear) gradient
    J = Component(state_slices(m).Te)
    e = zeros(N); e[state_slices(m).Te] .= 1
    @test gradient_J(J, m, x, n) ≈ vjp(m, x, e, n) rtol = 1e-14
end

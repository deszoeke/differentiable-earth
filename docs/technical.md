# Technical notes

Living document: the methods and implementation choices, written before each piece is built.
See `docs/plan.md` for the overall plan and `docs/julia_pin.md` for the Julia version pin.

References:
- Moses et al. (2026), *DJ4Earth: Differentiable, and performance-portable Earth system modeling via program transformations*, JAMES, doi:10.1029/2025ms005615.
- Reproduction code: github.com/DJ4Earth/differentiable-esm-components-2025.

## 1. The propagator interface
Every analysis is written against `AbstractPropagator` (`DifferentiableEarth/src/propagator.jl`). A propagator has:
- a flat state vector `x`;
- `advance(m, x)`, which takes one time step and returns a new vector without mutating `x`;
- `propagate(m, x, n)`, which takes n steps: the forecast map M(T) for lead time T = n·Δt;
- `state_slices(m)`, which names the parts of the state.

The toy model and, later, the coupled NumericalEarth model both implement this interface. Covariances, singular vectors, targeting and OSSEs therefore run unchanged on either.

## 2. The toy model: `ToyCoupled`
`DifferentiableEarth/src/toy/toy_coupled.jl`. A Lorenz-96 "atmosphere" of K = 36 sectors, coupled to a slab ocean under each sector and to a recharge-oscillator ENSO. It is meant to have the same three time scales as the real problem:

| Component | Variables | Time scale | Role |
|---|---|---|---|
| Lorenz-96 | X₁…X_K | days (chaotic; 1 model time unit ≈ 5 days) | weather noise, limits atmospheric predictability |
| slab ocean | T₁…T_K | ~90 days (λ⁻¹ = 18 units) | ocean memory, local SST persistence |
| recharge oscillator | Tₑ, h | years (period ≈ 3.7 years, irregularity CV ≈ 0.3) | ENSO-like predictable signal |

Equations:
- dX_k/dt = (X_{k+1} − X_{k−2}) X_{k−1} − X_k + F + α T_k + αₑ p_k Tₑ
- dT_k/dt = −λ T_k + β (X_k − X̄) + κ (T_{k+1} − 2T_k + T_{k−1})
- dTₑ/dt = R Tₑ + γ h + σ ξ − ϵ Tₑ³
- dh/dt = −r h − a (μ Tₑ + ξ)

where ξ is the mean of (X_k − X̄) over the "equatorial" sectors 1…n_eq (a wind-burst forcing) and p_k is a wavenumber-1 teleconnection pattern.

The coupling runs both ways:
- the ocean forces the atmosphere through α T_k;
- ENSO forces it through αₑ p_k Tₑ;
- the atmosphere forces the ocean through β and ξ.

So the full covariance has ocean–atmosphere cross-terms, as the real one will.

Time stepping is RK4 with Δt = 0.05 (≈ 6 h). The code uses only whole-array operations (`circshift`, broadcasts, `sum`, `vcat`, and 1-element slices instead of scalar indexing), with no data-dependent branches. That makes it traceable by Enzyme and by Reactant.

Why a toy model first:
- The analysis code (covariance B, singular vectors, targeting ΔVar, ETKF/OSSE) can be checked against exact answers in seconds.
- The Enzyme/Reactant workflow can be learned on a model small enough that its full Jacobian fits in memory (74 × 74), so every AD result can be checked against a brute-force one.

Status: implemented and tested (`DifferentiableEarth/test/test_toy.jl`). The tests cover the Lorenz-96 limit, purity, boundedness and sensitive dependence on initial conditions. **ENSO tuning (2026-11-15).** The first guess was a self-sustained oscillation: R = +0.002, γ = 0.02, σ = 0.01. Its period was ≈ 3.8 years, but it was too regular: the CV of cycle lengths was ≈ 0.1 over 300 years.
- The defaults are now a damped, noise-driven oscillator: **R = −0.006, γ = 0.0156, σ = 0.03**.
- That gives a CV of ≈ 0.3 (0.32 and 0.27 for two seeds over 300 years), about 3× the first guess, close to observed ENSO.
- Period: 3.6–3.8 years. std(Tₑ): ≈ 0.28.
- Sweeps: `drivers/toy_enso_sweep.jl`, run in `run/toy-enso-*`.
- Damping shortens the period, so γ was lowered to restore it (period ∝ 1/√(γa)).

## 3. Automatic differentiation: the approach (proposed, not yet implemented)
APIs were checked against the installed Reactant 0.2.308 and Enzyme 0.13.219 on 2026-11-15.

### 3.1 What we need from AD
Write M = `propagate(m, ·, n)` for the forecast map over lead time T = n·Δt, and **L** = ∂M/∂x(x₀) for its Jacobian along the trajectory from x₀. We never form **L** for the real model, which would be millions by millions. Instead we compute its products with vectors:
- **Tangent-linear model (TLM), a JVP:** δx(T) = **L** δx₀. This is how a small initial perturbation grows, to first order. In AD terms it is *forward mode*: one forward run carrying a tangent alongside the state.
- **Adjoint, a VJP:** λ₀ = **L**ᵀ λ_T. For a scalar forecast metric J(x(T)), such as Tₑ at lead T, the gradient ∂J/∂x₀ = **L**ᵀ ∇J. In AD terms it is *reverse mode*: run forward, then propagate sensitivities backward from T to 0. One reverse pass gives the sensitivity of J to **every** initial-state variable at once, which is why the targeting analysis is affordable.
- Singular vectors and the B-weighted analyses call these two products repeatedly, inside KrylovKit's Lanczos iterations.

### 3.2 Plain Enzyme
Enzyme differentiates the compiled LLVM code of ordinary Julia functions:
- **JVP:** `Enzyme.autodiff(Forward, x -> propagate(m, x, n), Duplicated(x₀, δx₀))[1]`. `Duplicated(x, v)` pairs the input with its tangent v, and the result is the output tangent **L** v.
- **VJP:** reverse mode needs a scalar output, so differentiate the scalar s(x) = λ·M(x). Its gradient is exactly **L**ᵀλ: `Enzyme.gradient(Reverse, x -> dot(λ, propagate(m, x, n)), x₀)[1]`. For J itself, `Enzyme.gradient(Reverse, x -> J(propagate(m, x, n)), x₀)[1]`.
- **Activities:** `Duplicated` (differentiated array, with a shadow), `Const` (not differentiated, e.g. the model parameters), `Active` (a differentiated scalar return).
- **Cost:** reverse mode stores the forward trajectory, so memory grows with n. That's fine for the toy, but this is why checkpointing exists.

### 3.3 Reactant
Reactant **traces** a Julia function into a compiler graph (MLIR/StableHLO), optimizes it, and compiles it with XLA for CPU (here) or GPU (HPC). Reactant's gradient is Enzyme run on that graph (EnzymeMLIR), so it is the same AD applied one level down.
1. **Convert inputs:** `xr = Reactant.to_rarray(x₀)` gives a `ConcreteRArray`. Scalars become `ConcreteRNumber` only if asked.
2. **Compile once:** `vjp_c = @compile vjp(m, xr, λr)` traces and compiles. Calling `vjp_c(m, xr2, λr2)` then runs at compiled speed for new inputs. `Array(result)` brings the result back.
3. **Loops must be traced.** A plain Julia `for` loop would be unrolled n times at trace time. `@trace for _ in 1:n ... end` becomes one compiled `while` loop. `@trace` does nothing outside Reactant, so the package's `propagate` can carry it and serve plain Julia, plain Enzyme and Reactant from **one code path**.
4. **Checkpointing:** `@trace checkpointing=... mincut=true for ...`.
   - `checkpointing=true` stores √n states and recomputes the rest.
   - `Reactant.Periodic(k)` stores k states.
   - `Reactant.Binomial(b)` uses the revolve algorithm with a budget of b states; it is recommended when n is a traced number.
5. **Baked-in constants:** a plain Julia value passed to `@compile` (Δt, the model parameters, a Julia `Int` n) is frozen into the compiled code. Calling it later with a different value silently uses the old one. To vary n without recompiling, pass `n` as `ConcreteRNumber` and use `Binomial` checkpointing. Our default instead compiles one function per lead time, which is simpler and cheap for the toy.
6. **Rules for traced code:** no scalar indexing without `@allowscalar` (the toy uses 1-element slices), and no data-dependent Julia `if` (use `@trace if`, or smooth the switch).

### 3.4 How we know the derivatives are right
Run on the toy for every propagator; the coupled model later gets the first four (`differentiable-code` skill):
1. **Finite differences:** (J(x+εv) − J(x−εv))/2ε ≈ ∇J·v over ε = 1e-2 … 1e-8.
2. **Dot-product test:** ⟨**L**δx, λ⟩ = ⟨δx, **L**ᵀλ⟩ to round-off. This shows the adjoint really is the transpose of the TLM.
3. **Reactant equals plain Enzyme** to round-off, which catches tracing bugs.
4. **TLM validity against lead time:** compare M(x+δx) − M(x) with **L**δx as T grows. The atmosphere's part should fail within a few weeks, because of chaos. ENSO-related directions should stay linear much longer. This sets where adjoint results can be trusted, and motivates the ensemble-averaged gradients in the plan.
5. **Toy only:** the full Jacobian (`Enzyme.jacobian`, 74×74) against all of the above.

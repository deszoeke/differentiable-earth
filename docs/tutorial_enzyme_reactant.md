# Tutorial: automatic differentiation with Enzyme and Reactant (toy model)

Goal: get from "what is a gradient of a forecast?" to working, verified tangent-linear and adjoint products of a time-stepping model, in plain Julia (Enzyme) and compiled (Reactant). Everything here runs on the toy model in a few minutes.
- **Code:** `PredictableOcean/src/ad.jl` and `propagator.jl`.
- **Driver:** `drivers/tutorial_ad.jl`, run in `run/tutorial-ad/`.
- **Plots:** `plots/tutorial_ad_pluto.jl`.
- **Tests:** `PredictableOcean/test/test_ad.jl` and `test_reactant.jl`.
- **Background:** `docs/technical.md` §3.

## 1. What we differentiate
M = `propagate(m, ·, n)` maps an initial state x(0) (74 numbers: X₁…₃₆, T₁…₃₆, Tₑ, h) to the forecast at lead τ = n × 6 h. Notation follows `docs/technical.md` (Notation). For a forecast metric J, for example Tₑ at lead τ (ENSO) or the slab-ocean T₁ (a marine-heat-wave-like quantity):
- the **sensitivity** g = ∂J(M(x(0)))/∂x(0) says how much J changes per unit change of each initial variable;
- **Tangent-linear model (TLM):** M′v, how a perturbation v grows. This is forward-mode AD.
- **Adjoint:** M′ᵀz. With z = ∇J, it gives g for all 74 initial variables in **one** backward pass. This is reverse-mode AD, and it is what makes targeting affordable for a model with millions of variables.

## 2. Plain Enzyme
```julia
using PredictableOcean
m  = ToyCoupled()
x0 = propagate(m, initial_state(m), 2000)          # a state on the attractor
Lv  = jvp(m, x0, v, 56)                             # TLM, 2 weeks
Lλ  = vjp(m, x0, λ, 56)                             # adjoint
g   = gradient_J(Component(state_slices(m).Te), m, x0, 56)   # ∂Tₑ(2 wk)/∂x(0)
```
Inside `ad.jl`:
- **JVP:** `Enzyme.autodiff(Forward, f, Const(m), Duplicated(x, v), Const(n), ...)[1]`. `Duplicated(x, v)` pairs the input with its tangent, and the result is the output tangent.
- **VJP:** `Enzyme.autodiff(Reverse, x -> λ⋅M(x), Active, ..., Duplicated(x, dx), ...)`. Reverse mode needs a scalar output, and the gradient of z⋅M(x) is exactly M′ᵀz. It accumulates into `dx` (started from zero with `make_zero`).
- **`Const`** marks arguments that are not differentiated: the model, n, z, J.

## 3. Reactant
```julia
using Reactant
mr, xr, λr = Reactant.to_rarray(m), Reactant.to_rarray(x0), Reactant.to_rarray(λ)
vjp_c = Reactant.@compile vjp(mr, xr, λr, 56, true)   # trace + compile once (n = 56 is baked in)
Lλ_r  = Array(vjp_c(mr, xr, λr, 56, true))              # run: fast; Array() brings it back
```
- Reactant traces the Julia function into MLIR, optimizes and compiles it with XLA. The gradient is Enzyme applied to that compiled graph.
- `propagate` uses `@trace for`, which is an ordinary loop outside Reactant and one compiled `while` loop inside it. The final `true` turns on checkpointing.
- Plain Julia values given to `@compile` (n, the checkpointing choice) are frozen into the compiled code. There is one compiled function per lead time.

## 4. Pitfalls we hit (and the fixes now in the code)
1. **A `@trace` loop overwrote its input.**
   - What happened: the loop-carried `x` is written back into the array it started from, so after a compiled `propagate` the caller's `xr` held the *final* state. The next JVP was then taken at the wrong point and was 100% wrong.
   - Fix: `propagate` copies `x0` first.
   - How it was caught: the Reactant-against-Enzyme test.
2. **Compiled functions take no keyword arguments.** Every AD function therefore has an all-positional method, e.g. `vjp(m, x, λ, n, checkpointing)`.
3. **`Reactant.@compile` is expanded when the code is parsed,** so `using Reactant` must run before a file that uses it is parsed. That's why the tests load it at the top of `runtests.jl`.
4. **Reactant differs from plain Enzyme by ~1e-12, not 1e-16,** because XLA reorders floating-point operations. Compare with `rtol ≈ 1e-9`.

## 5. How we know it is right
| Check | What it shows | Result (2 weeks, toy) |
|---|---|---|
| dot-product test ⟨M′v, z⟩ = ⟨v, M′ᵀz⟩ | the adjoint really is the transpose of the TLM | 2e-16 |
| centered finite differences, ε = 1e-5…1e-7 | the TLM is the derivative of the model | 6e-8 at ε = 1e-7, converging |
| full Jacobian (`Enzyme.jacobian`, 74×74) | JVP and VJP match the explicit matrix | 5e-16 |
| Reactant against plain Enzyme | tracing and compilation didn't change the math | forward 7e-14, JVP 3e-12, VJP (checkpointed) 2e-12 |

## 6. Results: sensitivities and TLM validity against lead time
From `run/tutorial-ad/tutorial_ad.nc` (driver output, 2026-11-15); plotted in `plots/tutorial_ad_pluto.jl`. J = Tₑ; first initial state for the checks; 20 initial states × 10 perturbations for TLM validity.

| lead | dot test | FD (ε = 1e-7) | Reactant vs Enzyme | TLM rel. error at δx = 0.01 s / 0.1 s / 0.3 s | Enzyme gradient | Reactant compile / run |
|---|---|---|---|---|---|---|
| 2 days | 2e-15 | 6e-9 | 2e-18 | 0.0013 / 0.013 / 0.03 | 0.2 ms | 19 s (first) / 0.07 ms |
| 2 weeks | 8e-16 | 5e-9 | 4e-15 | 2.1 / 8.4 / 12 | 1 ms | 2.5 s / 0.03 ms |
| 2 months | 7e-16 | 1.0 | 5e-7 | 3e8 / 3e9 / 6e9 | 5 ms | 2.5 s / 0.03 ms |
| 1 year | 6e-14 | 1.0 | 900 | ~1e56 … 1e58 | 40 ms | 2.6 s / 0.07 ms |

**What this means:**
1. **The AD is correct at every lead.** The dot-product test passes to round-off even at 1 year, so the adjoint is exactly the transpose of the TLM. The 2-month and 1-year failures of the finite differences and of Reactant-vs-Enzyme are not bugs:
   - The derivatives themselves grow like e^(λτ). λ is the Lorenz-96 leading Lyapunov exponent, with a doubling time of about 2 days.
   - So ε = 1e-7 is already a nonlinear perturbation at 2 months, and round-off differences of 1e-16 between Enzyme and XLA are amplified to O(1) by 1 year.
2. **The TLM is valid only for about a week for realistic perturbation sizes.** At 2 days it is excellent (errors under 3%). By 2 weeks, even a 1%-of-s perturbation grows nonlinear (error ≈ 2). This is the atmospheric predictability limit of the toy.
3. **Tₑ is sensitive to the atmosphere.** Tₑ is forced by the chaotic wind-burst term σξ, so its single-trajectory gradient is dominated by the atmosphere and explodes with lead (see the "where the sensitivity lives" figure). Tuning ENSO to be more irregular (larger σ) also made it more chaotically sensitive. Predictability and irregularity are linked.
4. **Reactant is about 30× faster than plain Enzyme per gradient at 2 weeks, and 600× at 1 year** (0.07 ms against 40 ms), after a few seconds of compiling. For the toy it doesn't matter; for the coupled model it will.

**Consequence for the project (as planned in `docs/plan.md`):** single-trajectory adjoints are only meaningful for leads within the TLM-valid window, about a week for this toy. For monthly-to-interannual targeting we need sensitivities that average out the atmospheric chaos. The next step tests these on the toy, where exact ensemble answers are cheap:
- **ensemble-averaged gradients:** the mean of ∂J/∂x(0) over an ensemble of atmospheric states with the same ocean;
- **ensemble sensitivity:** regression of J(τ) on x(0) across an ensemble;
- **gradients restricted to the slow (ocean/ENSO) variables,** taken over chained short windows.

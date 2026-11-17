---
name: differentiable-code
description: Checklist and test templates for writing and verifying differentiable code with Reactant.jl and Enzyme.jl in differentiable-earth (traced code rules, activity annotations, checkpointing, adjoint dot-product test, finite-difference test, Reactant-vs-Enzyme comparison). Use before writing or reviewing any code that will be compiled with Reactant or differentiated with Enzyme.
---

# Differentiable code: rules and tests

API details change between versions. Before relying on a signature, check it against the installed package with `code-reader`. Reference code: Oceananigans `test/reactant/hydrostatic_models.jl` (gradient, lines ~49-90) and `ext/OceananigansReactantExt/Simulations/run.jl`, SpeedyWeather `ext/SpeedyWeatherReactantExt.jl` (`time_steps!`) and `test/reactant/differentation.jl`, Reactant `docs/src/tutorials/automatic-differentiation.md`, NumericalEarth `examples/era5_forced_slab_land.jl`, DJ4Earth Channelanigans.

## Concepts (explain these to the user when they first come up)
- **Enzyme** differentiates compiled Julia (LLVM IR). `Enzyme.autodiff(Reverse, f, Active, Duplicated(x, dx), Const(p))`:
  - `Duplicated(x, dx)`: an input with a shadow buffer that receives the gradient.
  - `Const`: not differentiated.
  - `Active`: a scalar that is differentiated, returned by value.
  - `Forward` mode gives JVPs (tangent-linear model); `Reverse` gives VJPs (adjoint).
- **Reactant** traces Julia into MLIR/StableHLO, optimizes it, and runs it with XLA on CPU, GPU or TPU. Arrays become `ConcreteRArray`s (`Reactant.to_rarray`), and `@compile f(args...)` returns a compiled thunk. Reactant's gradient is **Enzyme applied to the traced MLIR**, so `Enzyme.autodiff` is called inside the function being compiled.
- **Tracing hazards:** Julia `if`/`for`/`while` on traced values are evaluated once, at trace time. Use `@trace if` and `@trace for`, or keep the control flow independent of the data. Scalars captured from the host become constants.
- **Checkpointing:** reverse mode must store or recompute the forward trajectory.
  - Use `@trace mincut=true checkpointing=true for i in 1:n ... end`.
  - Oceananigans and SpeedyWeather accept `checkpointing=Reactant.Periodic(k)` or `Reactant.Binomial(n)`.
  - With `Binomial`, a step count held on the device lets one compiled gradient handle any number of steps (this needs Oceananigans ≥ 0.118).

## Rules for traced code
- No host control flow on traced values, no scalar indexing (`x[i]` in a loop), no `@info`/`@warn`/`println`, no `try`, no mutation of host globals.
- Build constant operators on the host (for example the ConservativeRegridding weights, as sparse or banded matrices) and pass them in as arguments.
- Allocate outside the traced region. In-place updates of traced arrays are fine.
- **`copy` the input before a `@trace` loop.** The loop-carried variable is written back into the array it started from, so `x = advance(m, x)` inside `@trace for` overwrites the caller's input. This happens even with `donated_args = :none`. Found 2026-11-15, when it made the Reactant JVP 100% wrong. Reactant's own examples do `rk4_steps(copy(x), ...)`.
- **A compiled call advances the model object it is given** (Oceananigans: velocities, η, clock). For finite-difference checks or repeated evaluations, build a fresh model for every call. Otherwise each evaluation starts from the previous end state, and the finite differences stop converging as ε shrinks (2026-11-16; fixed, then 1e-12 agreement).
- **Compiled thunks take no keyword arguments.** Give every function that will be `@compile`d an all-positional method; keyword values are baked in at compile time.
- **Gradient check results (toy, 56 steps):** Reactant against plain Enzyme agrees to ~1e-12, not 1e-16, because XLA reorders floating-point operations. Use `rtol ≈ 1e-9`.
- Smooth non-differentiable switches where gradients matter (softplus or sigmoid with a sharpness parameter); keep the original as an option.
- For gradient checks on GPU, use Float64 or turn TF32 off: XLA uses TF32 for Float32 matrix products by default.

## Required tests (in `DifferentiableEarth/test/`)
Every propagator (toy, atmosphere, ocean, coupled) gets all four tests:
1. **Finite differences.** For a random direction `v`, check `(J(x+εv) − J(x−εv))/(2ε) ≈ ⟨∇J, v⟩`, with ε swept over about 1e-2 to 1e-8. Expect agreement in a V-shaped window. Use Float64.
2. **Dot-product (adjoint) test.** For random `δx` and `λ`, check `⟨M δx, λ⟩ ≈ ⟨δx, Mᵀ λ⟩` to near round-off, using the state metric W if adjoints are taken in a weighted norm.
3. **Reactant against plain Enzyme.** On a small case and on Julia 1.11, the gradients should agree to round-off. This catches tracing bugs.
4. **Linear-regime check (TLM validity).** Compare `M(x+δx) − M(x)` with `M' δx` as the amplitude and lead time grow. Report the lead time at which they diverge, because it bounds where the adjoint results are valid.

## Template sketches (adapt to the installed API)
```julia
# finite differences
J(x) = sum(abs2, propagate(x, p))
g = gradient_of_J(x, p)              # Reactant or Enzyme
v = randn(size(x)); v ./= norm(v)
for ε in 10.0 .^ (-2:-1:-8)
    fd = (J(x .+ ε .* v) - J(x .- ε .* v)) / (2ε)
    @show ε, fd, dot(g, v), abs(fd - dot(g, v)) / abs(fd)
end
# dot-product test
lhs = dot(jvp(x, δx), λ);  rhs = dot(δx, vjp(x, λ));  @test lhs ≈ rhs rtol=1e-10
```

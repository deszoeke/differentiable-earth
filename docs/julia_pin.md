# Julia version pin: 1.11

## What is pinned
- **Mac:** `juliaup override set 1.11` in the repo, so `julia` here starts 1.11.9.
- **HPC jobs:** `julia +1.11 ...` in every job script.
- **`[compat]`:** `julia = "~1.11"` in `Project.toml` and `DifferentiableEarth/Project.toml`.
- **`Manifest.toml`:** committed for the main environment, so every machine resolves identical Reactant/Enzyme/Oceananigans/SpeedyWeather versions.
- **Not pinned:** `plots/`, which has its own environment and Jupyter kernel ("Julia 1.11 (diff-earth)") and no committed Manifest.

## Why
1. **Plain-Enzyme cross-checks of Reactant gradients.** Plain Enzyme differentiates SpeedyWeather `PrimitiveWetModel` end-to-end only on Julia ≤ 1.11 (SpeedyWeather issue #1051; its Enzyme CI runs only 1.10 and 1.11). Comparing against plain Enzyme is our independent check that Reactant's traced gradients are right.
2. **NumericalEarth's Reactant CI runs on 1.11.9.** Its main CI uses 1.12.
3. **Nothing in the stack needs 1.12 or later.** All packages state only `julia ≥ 1.10`.

## What it costs
- A Julia version and depot cache separate from the user's other projects, which run 1.13. Precompiles are slower and more fragile, and there is one more Jupyter kernel.
- Julia 1.12/1.13 features and fixes are out of reach. For example, the 1.13 miscompile fix (JuliaLang/julia#60924) is in 1.13.4.

## Criteria for lifting the pin
`upstream-scout` checks these at the start of each phase. Lift the pin when **any** of them holds:
1. SpeedyWeather #1051 is closed, or its Enzyme CI includes 1.12 or later.
2. NumericalEarth's Reactant CI runs on 1.12 or later.
3. We no longer need plain-Enzyme cross-checks, because the Reactant gradients of the coupled model have been validated by finite differences and dot-product tests.
4. A package we need drops 1.11, or requires 1.12 or later.

**Procedure:**
1. Bump `[compat]` and the juliaup override and job scripts.
2. Re-resolve the Manifest.
3. Run the full gradient test suite.
4. Record the result in the log below.

If we go Reactant-only, 1.12.x is the conservative choice. 1.13.4 or later is plausible, since Oceananigans already runs its AD tests on 1.13.

## Log
| Date | Check | Result |
|---|---|---|
| 2026-11-15 | Initial pin | 1.11.9. #1051 open; NumericalEarth Reactant CI on 1.11.9; Reactant 0.2.308 and Enzyme 0.13.219 allow Julia ≥ 1.10. |

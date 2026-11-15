# Status

_Last updated 2026-11-15._

## Done
- Plan adopted (`docs/plan.md`).
- Julia 1.11.9 installed, with a juliaup override in this repo.
- Tools: `gh` (logged in), plus `jupytext` and `nbstripout` from the micromamba `nbtools` env, symlinked into `~/.local/bin`.
- Agents (`code-reader`, `upstream-scout`) and skills (`julia-env`, `differentiable-code`, `add-phenomenon`, `netcdf-output`) written.

- Main environment resolved on 1.11.9 at the target versions; Manifest committed (main, b856558).
- Branch `phase1-toy-model`:
  - `ToyCoupled` (Lorenz-96 + slab ocean + recharge oscillator) and the `AbstractPropagator` interface, with 11 passing tests;
  - `io.jl` (NetCDF with provenance);
  - `drivers/toy_nature_run.jl`;
  - `plots/` (readers, plotlib, `toy_nature_run` notebook).
- Toy nature run, `run/toy-nature/` (50 years daily, 9 s), with default parameters. Numbers from `plots/toy_nature_run.jl`:
  - peak Tₑ period ≈ 3.84 years;
  - std(Tₑ) = 0.382, skewness −0.09;
  - e-folding times: X₁ 2 days, T₁ 38 days, Tₑ 277 days.

## Next
1. The user reviews the nature-run notebook and possibly tunes the ENSO parameters.
2. The Enzyme/Reactant tutorial on the toy model (`docs/tutorial_enzyme_reactant.md`, `drivers/tutorial_ad.jl`). Agreed choices:
   - J = Tₑ at lead T, plus a slab-ocean T_k (MHW-like) as a second J;
   - leads of 2 days, 2 weeks, 2 months and 1 year;
   - `@trace` in the package `propagate`.
3. Build graphify graphs of the upstream package sources (`helpers/graph_package.sh`).
4. Coupled smoke test: update `test_NumericalEarth.jl` to `EarthSystemModel`.

## Open questions
- None right now.

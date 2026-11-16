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
- Toy ENSO tuned for 3× irregularity: R = −0.006, γ = 0.0156, σ = 0.03. Over 300 years the CV of cycle lengths is ≈ 0.3, against ≈ 0.1 before (`drivers/toy_enso_sweep.jl`; `docs/technical.md` §2).
- Toy nature run, `run/toy-nature/`, rerun with the new defaults (50 years). Numbers from `plots/toy_nature_run.jl`:
  - peak period 3.84 years;
  - 11 cycles, 4.3 ± 1.1 years, CV 0.265;
  - std(Tₑ) = 0.256, skewness +0.20;
  - e-folding times: X₁ 2 days, T₁ 45 days, Tₑ 244 days.

## Next
1. The user reviews the rerun nature-run notebook.
2. The Enzyme/Reactant tutorial on the toy model (`docs/tutorial_enzyme_reactant.md`, `drivers/tutorial_ad.jl`). Agreed choices:
   - J = Tₑ at lead T, plus a slab-ocean T_k (MHW-like) as a second J;
   - leads of 2 days, 2 weeks, 2 months and 1 year;
   - `@trace` in the package `propagate`.
3. Build graphify graphs of the upstream package sources (`helpers/graph_package.sh`).
4. Coupled smoke test: update `test_NumericalEarth.jl` to `EarthSystemModel`.

## Open questions
- None right now.

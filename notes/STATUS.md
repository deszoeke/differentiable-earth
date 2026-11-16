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

- Plotting: Pluto notebooks are the default (`plots/*_pluto.jl`); Jupyter is kept for the HPC. Heavy computation goes in drivers.
- AD layer (`src/ad.jl`: `jvp`, `vjp`, `gradient_J`, `Component`); `@trace` loop in `propagate` (copies its input first). Tests: 20 pass, including Reactant against Enzyme (`DE_TEST_REACTANT=true`).
- AD tutorial: `docs/tutorial_enzyme_reactant.md`, `drivers/tutorial_ad.jl` (run in `run/tutorial-ad/`), `plots/tutorial_ad_pluto.jl`. Findings:
  - the AD is correct at all leads;
  - the toy TLM is valid for only about 1 week; derivatives grow like e^(λT), with a doubling time of about 2 days;
  - single-trajectory adjoints are meaningless beyond about 2 weeks;
  - Reactant is 30–600× faster per gradient after compiling.

## Next
1. The user reviews the tutorial notebook.
2. Sensitivities that survive chaos, tested on the toy:
   - ensemble-averaged gradients;
   - ensemble sensitivity (regression);
   - gradients restricted to the ocean/ENSO variables, over chained short windows.

   Compare them with the exact ensemble response.
3. Build graphify graphs of the upstream package sources (`helpers/graph_package.sh`).
4. Coupled smoke test: update `test_NumericalEarth.jl` to `EarthSystemModel`.

## Open questions
- None right now.

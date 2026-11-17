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

- Toy sensitivity comparison, first run (`run/toy-sensitivity/`; `docs/technical.md` §4.1; `plots/sensitivity_comparison_pluto.jl`):
  - adjoints are excellent at 2 weeks and fail beyond;
  - the ensemble-mean adjoint does not converge;
  - regression is poor;
  - the LIM keeps skill: Tₑ pattern correlation 0.64 at 1 year;
  - but the truth is noise-dominated beyond about 2 months, so the run needs a redesign.

- Phase 2 (`phase2-coupled-model`):
  - coupled smoke test passes (`run/coupled-smoke/`);
  - regridding weights extracted, checked (transpose 4e-15, constant-preserving, identical to `ConservativeRegridding.regrid!`) and saved (`run/regrid-weights/`), through the `DifferentiableEarthCoupledExt` extension.
- Reactant atmosphere and ocean checks are written but need CUDA.jl (deferred).
- **Plan re-scoped** (`docs/plan.md`, "Re-scoped aims and phases"): ensembles plus the strongly coupled covariance (least-damped modes, PCA/APT, response operators), ML emulation with rigorous predictability, AD in supporting roles.

## Next
1. A multi-decade low-resolution coupled nature run, plus a timing study (with `caffeinate`).
2. Realism checks for the Tier 1 phenomena in the nature run.
3. Large ensembles, then the covariance and predictable modes.

## Open questions
- Add CUDA.jl to the root environment for the Reactant checks: deferred by the user.

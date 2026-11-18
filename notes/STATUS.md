# Status

_Last updated 2026-11-15._

## Done
- Plan adopted (`docs/plan.md`).
- Julia 1.11.9 installed, with a juliaup override in this repo.
- Tools: `gh` (logged in), plus `jupytext` and `nbstripout` from the micromamba `nbtools` env, symlinked into `~/.local/bin`.
- Agents (`code-reader`, `upstream-scout`) and skills (`julia-env`, `differentiable-code`, `add-phenomenon`, `netcdf-output`) written.

- Main environment resolved on 1.11.9 at the target versions; Manifest committed (main, b856558).
- Phase 1 (tag `phase1-toy-done`):
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

- Phase 2 (tag `phase2-regrid-done`; all work now on `main`):
  - coupled smoke test passes (`run/coupled-smoke/`);
  - regridding weights extracted, checked (transpose 4e-15, constant-preserving, identical to `ConservativeRegridding.regrid!`) and saved (`run/regrid-weights/`), through the `DifferentiableEarthCoupledExt` extension.
- Reactant checks pass against finite differences:
  - **ocean:** Oceananigans on a LatitudeLongitudeGrid with buoyancy and Coriolis, 1e-12 (`run/reactant-ocean/`);
  - **atmosphere:** SpeedyWeather PrimitiveWet T32L8 Float64, 3e-8 (`run/reactant-atmosphere/`).
- Plain Enzyme on SpeedyWeather segfaults on Julia 1.11, so unpin criterion 3 is met (`docs/julia_pin.md`).
- **Plan re-scoped** (`docs/plan.md`, "Re-scoped aims and phases"): ensembles plus the strongly coupled covariance (least-damped modes, PCA/APT, response operators), ML emulation with rigorous predictability, AD in supporting roles.

- **HPC smoke test** (2026-11-16, job 7432005, `rime`, an aarch64 GH200 node, Grace CPU only, 8 threads), `run/coupled-smoke-hpc/`:
  - build 223 s; first step 37.5 s (compilation);
  - **≈ 0.39 s per 40-minute coupled step** (179 steps in about 70 s);
  - SST identical to the Mac run.
- **Implied cost:**
  - about 1.4 h per member-year, about 17 simulated years per day per 8-core job, about 150 SYPD per 72-core node if members scale independently (unmeasured);
  - 2-year ensembles of 30 members × 4 seasons × 20 years (4800 member-years) ≈ 32 node-days;
  - a decadal check of 5 starts × 20 members × 10 years ≈ 7 node-days;
  - a 500-year nature run takes about 30 days of wall time as one 8-core job, so single long runs need speed-ups.
  - Likely speed-ups: a longer coupled Δt with the atmosphere sub-stepped (the ocean currently steps every 40 min); thread scaling; GPU.
- **Ensemble sampling** (user's point, 2026-11-17):
  - pooled over 4 seasons × 20 years of starts, the 30-member ensembles give about 2300 degrees of freedom for the **noise** covariance Σ(τ) at every lead (29 per start × 80 starts). That is ample for strongly coupled cross-covariances, though seasonal and state dependence reduce it (about 580 per season).
  - The **signal** covariance and the climatological C(0) and C(τ) have only about 80 correlated ensemble-mean samples, so the effective number is the count of independent slow states. These need the long nature run.
  - The coupled state is 10⁵–10⁶ variables, so analysis works in a reduced space of about 100–300 EOFs.
- **Decadal predictability** (idea, not yet in the plan):
  - extrapolate with the LIM, G(τ) = C(τ) C(0)⁻¹ = exp(Lτ), Q = −(L C(0) + C(0) Lᵀ), with the τ-test;
  - diagnostic potential predictability from a several-century control run with realistic geometry;
  - check against a few 10-year ensembles. Caveat: AMOC and decadal ocean physics at 2°.
- **Literature:** `docs/novelty.md` (assessment) and `docs/references.md` (56 AMS-style references with DOIs). Consensus thread: https://consensus.app/search/literature-review-to-assess-the-novelty-of-a-plann/uihD0upqS4-DK0PLLx3Jsg/ . The Elicit connector is unavailable (no API access on the plan).

## Next
1. A timing study: atmosphere and ocean cost per step; a longer coupled Δt with the atmosphere sub-stepped; thread scaling; later GPU. Then a multi-decade low-resolution coupled nature run.
2. Realism checks for the Tier 1 phenomena in the nature run.
3. Large ensembles, then the covariance and predictable modes.

## Open questions
- Unpin Julia 1.11 and move to 1.12 or 1.13? Criterion 3 is met; waiting for the user's decision.

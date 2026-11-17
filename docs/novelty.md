# What is novel? (working notes, 2026-11-16; to be revised)

Full citations with DOIs, in AMS style: `docs/references.md`.

Most individual components are established. The novelty lies in their combination, and in a perfect-model benchmark the field lacks. **Status: claims revised after a literature check on 2026-11-16 (Consensus search). See below.**

## Established (not novel by themselves)
- Strongly coupled data assimilation and coupled covariances (Penny & Hamill; Sluka et al., coupled SPEEDY–NEMO; Frolov et al. review).
- LIM/POP least-damped modes and non-normal optimal growth (Penland & Sardeshmukh; Newman).
- Predictable component analysis and average predictability time (Schneider & Griffies; DelSole & Tippett).
- Ocean-adjoint ENSO sensitivity and targeting (Moore & Kleeman; TPOS design studies).
- Perfect-model predictability studies.
- ML weather emulators and their known under-dispersion.

## Candidate novel contributions
1. **A ground-truth benchmark for ML predictability claims (strongest).**
   - The problem: emulators are verified against reanalysis, where the true predictability is unknown.
   - What's new: in a perfect-model coupled system, large physics ensembles give the true predictability (spread, predictable components, APT, optimal growth, by lead, season and phenomenon), including the coupled ocean–atmosphere covariance. Emulators are scored against it.
2. **Emulators whose spread cannot collapse, by construction.**
   - A stochastic residual with covariance Q = −(L C₀ + C₀ Lᵀ), from the fluctuation–dissipation relation for the strongly coupled covariance, refined by AD-calibrated noise (reparameterization trick).
   - This links LIM noise theory to ML emulators and targets their under-dispersion.
3. **The strongly coupled covariance through lead time, not only at analysis time.**
   - Do the least-damped coupled modes, the optimal-growth structures and the nonlinear predictable components agree, and where do they diverge?
   - Across phenomenon tiers, e.g. the effect of a poorly resolved MJO on ENSO and PNA predictability.
4. **A quantified answer to where coupled AD helps,** in a real coupled GCM:
   - the validity window of trajectory derivatives;
   - adjoint vs ensemble-mean adjoint vs regression vs covariance response, all against exact ensemble answers;
   - partly a negative result. The toy version is in `docs/technical.md` §4 and `docs/plan.md` "Design revision".
5. **Seasonal-to-interannual targeted observing, verified by OSSEs:**
   - ocean-adjoint siting against coupled-ensemble and covariance-based siting;
   - both verified with strongly coupled ensemble assimilation.
6. **Infrastructure (enabling, not scientific):** one open, GPU-portable, differentiable Julia system covering everything from physics ensembles to emulator training.

## Literature check (2026-11-16)
Searched with Consensus. Preprints are marked; they are not peer reviewed. These are not exhaustive. Next step: read the closest papers in full.

**1. Ground-truth benchmark for ML predictability: partly done; narrowed but still open.**
- *Closest:* Mahajan, Kelleher & Fan (2026, PASC), "Statistical equivalence of AI emulators and Earth system models: a large ensemble study with ultra-low-resolution E3SM", doi:10.1145/3815572.3815761.
  - A large perfect-model ensemble of an emulator against its parent E3SMv3, up to **10 days**.
  - They find the emulator is strongly under-dispersive, and that its multivariate error covariance differs significantly from E3SM's.
  - This confirms our premise. It is weather-range only, and uses spread and covariance tests, not predictability diagnostics.
- *Related:*
  - Brenowitz et al. (2025, GRL), a probabilistic benchmark using lagged ensembles against reanalysis;
  - ChaosBench (Nathaniel et al. 2024, NeurIPS): S2S benchmark against reanalysis, where emulators collapse to climatology;
  - Lütjens et al. (2025, JAMES): internal variability in emulator benchmarks;
  - Rodwell et al. (2025, Met. Apps): power spectra of physics and data-driven ensembles;
  - Böger et al. (2026, arXiv preprint): a response-theory test for learned stochastic simulators (Lorenz-63).
- **Remaining gap:** coupled ocean–atmosphere predictability at **S2S to interannual** leads, verified with predictability diagnostics (predictable components, APT, optimal growth, coupled cross-covariances) against perfect-model ground truth.

**2. FDT/LIM-constrained stochastic emulators: actively studied; novelty is narrow.**
- Falasca & Zanna (2026, arXiv preprint): neural drift initialized from a LIM, with a stochastic closure, validated by FDT, applied to ENSO.
- Falasca (2025, Phys. Rev. Research): neural stochastic emulators with multiplicative noise, judged by forced response.
- Giorgini, Falasca & Souza (2025, PNAS): generalized FDT with score-based generative models.
- Giorgini, Bischoff & Souza (2025, arXiv preprint): **parameter calibration by the generalized FDT without adjoints or tangent-linear models**. A direct alternative to our AD-based noise calibration, to compare against.
- Also: Agarwal et al. (2021, JAMES), hybrid linear plus deep-learning plus noise emulators of an ocean model; Lien et al. (2025, PRR), colored-noise LIM; Rescene (Cheon 2026, arXiv preprint), AR(1) noise with a fixed spectrum that restores emulator spread.
- **Remaining gap:**
  - applying the FDT-constrained residual to a high-dimensional **strongly coupled** GCM state, and judging it on *forecast* predictability rather than stationary statistics or forced response;
  - comparing AD calibration with GFDT calibration.

**3. Strongly coupled covariance through lead time: still plausibly open.**
- Coupled-covariance studies concentrate on assimilation-window leads, 6 h to 7 days:
  - Smith, Lawless & Nichols (2017, MWR);
  - Sandery et al. (2020, MWR), a 96-member coupled EnKF with 7-day forecasts;
  - Chen et al. (2020, MWR), tropical cyclones;
  - Wright et al. (2024, QJ);
  - Purcell et al. (2026, QJ).
- Bach et al. (2019, J. Climate) map local ocean↔atmosphere predictability with Granger causality, from observations.
- *Targeted follow-up (2026-11-16), which found partial overlap at seasonal-to-interannual leads:*
  - **O'Kane et al. (2018, J. Climate):** strongly coupled ensemble assimilation and multiyear ENSO prediction. Cross-domain covariances; bred vectors that project onto thermocline disturbances; bred-vector error growth that leads ENSO SST by about 6 months. The closest prior work.
  - **Lu, Liu, Zhang et al. (2015, MWR), "Leading averaged coupled covariance" (LACC):** uses *lagged*, time-averaged ocean–atmosphere covariances for strongly coupled data assimilation in a coupled GCM. Directly relevant to a covariance that depends on lead.
  - **Coupled growing modes for ENSO ensembles:** Yang et al. (2008, J. Climate), coupled bred vectors; Duan, Hu & Feng (2024, Sci. China Earth Sci.), coupled conditional nonlinear optimal perturbations (C-CNOP).
  - **Low-order coupled models:**
    - Tondeur et al. (2020, J. Stat. Phys.): time-scale separation, Lyapunov spectra and EnKF behaviour in the MAOOAM coupled model;
    - Demaeyer, Penny & Vannitsem (2022, JAMES): initializing ensembles from Koopman and Perron–Frobenius eigenfunctions (estimated by DMD) and adjoint covariant Lyapunov vectors. Related to our least-damped modes.
  - **A GCM ensemble against a reduced-model benchmark:** Mao et al. (2026, arXiv preprint), CESM2 SMYLE 20-member hindcasts to 24 months, scored against the extended nonlinear recharge oscillator (XRO) with ensemble sensitivity analysis. They find *state-dependent under-dispersion* of the GCM itself. Close in spirit to our "linear baseline vs physics ensemble" level, but using real-world hindcasts, not a perfect model.
  - **ML coupled model:** Ola (Wang et al. 2024, arXiv preprint), an ML ocean–atmosphere model with an internal ENSO.
- **Still open:** in a *perfect-model* setting, how the **full** coupled covariance's structure evolves with lead, and how its predictable modes, optimal growth, predictable components and APT relate to each other, used as ground truth for emulators. The novelty is narrower than first stated.
- **Tools:** Elicit cannot be used through the connector, because the user's Elicit plan has no API access (needs Pro). The checks so far use Consensus only.

**4. Where coupled AD helps: theory known; the forecast-lead quantification in a modern differentiable coupled GCM is new-ish.**
- Lea, Allen & Haine (2000, Tellus) and Lea et al. (2002, QJ):
  - adjoints diverge in chaotic systems;
  - an ensemble of adjoints over intermediate windows can estimate *time-mean climate* sensitivity to O(10–25%), but fails for variance.
  - Our toy result (the ensemble-mean adjoint fails for a *forecast* metric at 2 months) is consistent: it is a different quantity.
- Shadowing methods: Wang et al. (2014, JCP), LSS; Ni (2018), NILSAS; Thakur & Nadarajah (2025, JSC and an arXiv preprint).
- **Köhl et al. (2026, QJ), CESAM coupled adjoint:** nudges the atmosphere to ERA5 to suppress chaos, which makes a **39-year coupled adjoint** usable. This is an important alternative to our ocean-only adjoint (role 2) and should be considered.
- **Remaining contribution:** measuring the limits of initial-condition forecast sensitivity across methods (adjoint, ensemble-mean adjoint, regression, covariance response, nudged adjoint) against exact ensemble answers, in an AD-native coupled GCM.

**5. Targeted observing for ENSO: a large literature; the novelty is narrow.**
- Ensemble, particle-filter and CNOP/optimal-growth targeting with OSSEs:
  - Duan et al. (2018, Clim. Dyn.);
  - Zhang, Hu & Duan (2021, AOSL);
  - Hou et al. (2022, Clim. Dyn.);
  - Rao et al. (2023, Natl Sci. Rev.), an EnKF method for TPOS 2020;
  - Rao et al. (2025, JAMES), model-independent multi-model targeting;
  - Li et al. (2025, ERL), Indian Ocean observations for central-Pacific El Niño.
- Classic: Morss & Battisti (2004, J. Climate), OSSEs with a linear stochastic ENSO model, whose sensitive regions follow the leading singular vector.
- **Remaining gap:** comparing ocean-adjoint, ensemble-based and covariance-response siting within one perfect-model, *strongly coupled* system. That includes atmospheric observations updating the ocean through the cross-covariance in the OSSE, and siting for targets beyond ENSO (PDO, MHWs).

**6. Infrastructure:** builds on DJ4Earth (Moses et al. 2026, JAMES), NumericalEarth, SpeedyWeather and Oceananigans. It is enabling work, not a scientific novelty.

### Revised framing
The strongest remaining niche combines items 1 and 3:
- **a perfect-model ground truth for strongly coupled predictability at S2S-to-interannual leads,**
- used to benchmark linear (LIM/FDT) and ML (stochastic, FDT-constrained) emulators **on predictability diagnostics,** including the coupled cross-covariances.

This extends Mahajan et al. (2026), which covers 10-day spread and covariance, and Falasca & Zanna (2026), which covers stationary statistics and forced response, to *forecast* predictability in a coupled system. Items 2, 4 and 5 are supporting contributions.

### Full-text reading of the three closest papers (2026-11-16, by a subagent)
**Mahajan, Kelleher & Fan (2026, PASC).** Read from the OSTI author manuscript, a working draft dated 2025-12-13 that may differ from the published version.
- **Setup:**
  - E3SMv3 ultra-low resolution (ne4pg2, about 7–8°). It doesn't say whether the ocean is active or SST is prescribed.
  - The emulator holds only **20 atmospheric variables**.
  - A 1000-member perfect-model ensemble, **one start date, leads up to 10 days**.
- **Emulator:** a **deterministic** FourCastNet (AFNO), turned into an ensemble only by starting it from the E3SM members (no noise).
- **Results:**
  - spread at day 10 is 25–45% of E3SM's;
  - spread grows by a factor of 3–8 from day 1 to day 10 in E3SM, but only 0.9–2 in the emulator;
  - permutation tests reject equality of the 20×20 error covariance and correlation matrices;
  - upper tails are under-populated.
- **Future work they list:** stochastic or latent-variable emulators, diffusion ensembles, noise injection.
- **No predictability diagnostics** (signal-to-noise, PCA, APT, optimal growth), and no leads beyond 10 days.

**Falasca & Zanna (2026, arXiv:2602.13847 v5).**
- **Noise:** Σ is diagonal from residual standard deviations (idealized cases), or the **full residual-covariance Cholesky factor** (ENSO case), with optional multilevel non-Markovian layers. The Lyapunov/FDT relation is **not** used to constrain Q; FDT is used for response validation and causal masking.
- **Evaluation:** PDFs, autocorrelation, spectra and forced responses only. **No forecast skill, spread or predictability by lead.**
- **ENSO state space:** ORAS5 SST and SSH, 10 EOFs each (n = 20). Ocean only, with no atmosphere; the authors list the missing fast atmosphere as a limitation.
- **Future work they list:** using FDT response operators as calibration targets for pretrained emulators. That is close to our item 2, so cite it and distinguish ours early.

**Köhl et al. (2026, QJRMS), CESAM.**
- **Model:** MITgcm at 4° coupled to PlaSim at T21.
- **The nudging:** it nudges the atmosphere to hourly ERA5 in **both the forward and the adjoint model**, with time scales of 0.25–2 days. That makes the tangent-linear model stable, so a 39-year adjoint is possible.
- **Controls:** atmospheric parameters, initial ocean T/S, daily flux corrections, and GM/Redi diffusivities.
- **Not done:** no forecast initial-condition sensitivity and no targeting.
- **Their stated limits:**
  - the atmospheric adjoint memory is "effectively only a few days";
  - nudging breaks conservation;
  - the product is "best characterized as an ocean synthesis";
  - nudging can't be applied in forecasts, since there are no future data to nudge toward.
- **Implication (inferred):** this does not supersede our ocean-only adjoint (role 2). In effect it *is* an ocean adjoint with a damped atmosphere. Untested middle ground: nudge the atmosphere toward the ensemble mean or climatology to approximate a stochastically forced ocean adjoint.

**Wu et al. (2026, arXiv preprint 2608.10277), "Stochastic Emulation of a Fully Coupled Preindustrial E3SMv3 Simulation" (full citation in `docs/references.md`).** Read from the arXiv HTML, via WebFetch summaries, by a subagent on 2026-11-16.
- **Models:**
  - ACE2S atmosphere (1°, 8 levels, 6 h step) coupled to Samudra ocean and sea ice (1°, 19 levels, 5-day step);
  - trained on 90 years of an E3SMv3 preindustrial control;
  - exchanged fields: 5-day-mean fluxes and wind stress to the ocean; SST and sea ice to the atmosphere.
- **Stochasticity:**
  - noise is injected **in the atmosphere only** (ACE2S); "No additional noise is injected into" Samudra;
  - trained with fair CRPS (2 members) plus a spectral energy score, then the coupled system is fine-tuned jointly;
  - **no link to covariance or FDT.**
- **Evaluation:** free-running 500-year rollouts only.
  - Mean state, extremes, ENSO spectra and variability.
  - **No initialized forecasts and no predictability diagnostics.**
  - Stochastic training improves variability (e.g. Gulf Stream SST std: E3SMv3 1.27 K, deterministic 0.55 K, stochastic 0.74 K) but variability stays too low.
  - ENSO has up to 50% too little power at 1.5–2 years.
  - **One deterministic seed has a 6.6× too-strong, regular ENSO with good RMSE.** The authors: "mean-state metrics alone cannot detect this failure mode."
  - E3SMv3's own ENSO spectral peak varies about 4× between 40-year blocks.
- **Speed:** about 1100 simulated years per day on one H100.
- **Future work they list:** historical forcing; comparison with a large *historical* (forced, not initialized) ensemble; noise in the ocean emulator.
- **Code and data:** emulator code on Zenodo (doi:10.5281/zenodo.21878017); checkpoint, initial conditions and forcing on Hugging Face (allenai/SamudrACE-E3SMv3).
- **For us:**
  - **Not pre-empted.** No initialized, perfect-model predictability scoring and no FDT-constrained noise.
  - **Strong motivating evidence:** climate statistics and RMSE miss a wrong ENSO.
  - Cite it as the leading stochastic coupled emulator.
  - Our differences: initialized ensembles; a coupled noise covariance Q that includes the ocean; a differentiable model; lagged coupled covariances scored by lead.

### Updated assessment
- **(a) A perfect-model coupled predictability benchmark at S2S-to-interannual leads, using predictability diagnostics: still open.** Mahajan et al. supply the motivating result (deterministic emulators under-disperse) but stay atmosphere-only, deterministic, and within 10 days.
- **(b) An FDT/Lyapunov-constrained noise covariance for emulators: not done in Falasca & Zanna,** who fit Σ from residuals. But they name "FDT response as a calibration target" as future work, so this needs to be distinguished quickly.
- **(c) A nudged coupled adjoint is not a better route for forecast targeting.** It reduces to an ocean adjoint with a damped atmosphere, which supports role 2. Nudging toward the ensemble mean is a possible variant to test.
- **(d) Wu et al. 2026 (stochastic coupled emulator) does not pre-empt (a) or (b).** It strengthens the motivation, since a wrong ENSO can hide behind good RMSE and climate statistics.

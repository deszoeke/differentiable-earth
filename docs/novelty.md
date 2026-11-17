# What is novel? (working notes, 2026-11-16; to be revised)

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
- **I found no study** of how the coupled covariance's structure and predictable modes evolve at monthly-to-interannual leads in GCM ensembles. That needs a more targeted search (O'Kane et al.; Penny et al. on coupled predictability).

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

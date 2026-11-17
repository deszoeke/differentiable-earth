# References

The literature behind `docs/novelty.md` and `docs/plan.md`, in American Meteorological Society (AMS) style. Metadata comes from Crossref and DataCite, looked up by DOI on 2026-11-17. References with more than eight authors are listed as "First author, and Coauthors" (AMS convention). arXiv preprints are marked as not peer reviewed. Each entry has a one-line note on why it matters here, written from the Consensus searches and full-text readings in `docs/novelty.md`.

The same questions are also in a Consensus research thread: https://consensus.app/search/literature-review-to-assess-the-novelty-of-a-plann/uihD0upqS4-DK0PLLx3Jsg/

## Differentiable Earth system modeling

- Moses, W. S., and Coauthors, 2026: DJ4Earth: Differentiable, and Performance‐Portable Earth System Modeling via Program Transformations. J. Adv. Model. Earth Syst., 18, e2025MS005615, https://doi.org/10.1029/2025ms005615.  
  *DJ4Earth: Enzyme and Reactant with checkpointing give correct gradients for Oceananigans, SpeedyWeather, ShallowWaters and DJUICE, each run separately.*
- Gelbrecht, M., A. White, S. Bathiany, and N. Boers, 2023: Differentiable programming for Earth system modeling. Geosci. Model Dev., 16, 3123–3135, https://doi.org/10.5194/gmd-16-3123-2023.  
  *The case for differentiable ESMs: calibration, hybrid ML, and data-informed models.*
- Davenport, E. H., and Coauthors, 2026: JCM v1.1: a differentiable, intermediate-complexity atmospheric model. Geosci. Model Dev., 19, 6451–6466, https://doi.org/10.5194/gmd-19-6451-2026.  
  *JCM: SPEEDY physics in JAX, validated at T31; a cross-reference for which SPEEDY schemes differentiate cleanly.*
- Koldunov, N. V., and Coauthors, 2026: FESOM2-JAX v1.0: a differentiable shadow of the ocean-sea-ice model FESOM2, cast onto GPUs. arXiv, https://doi.org/10.48550/arxiv.2608.01546. (Preprint, not peer reviewed.)  
  *FESOM2-JAX: a differentiable ocean and sea-ice model on GH200 GPUs.*

## 1. Benchmarking ML emulators against ensemble ground truth

- Mahajan, S., M. Kelleher, and M. Fan, 2026: Statistical Equivalence of AI Emulators and Earth System Models: A Large Ensemble Study with Ultra-Low-Resolution E3SM. Proceedings of the Platform for Advanced Scientific Computing Conference, 1–11, https://doi.org/10.1145/3815572.3815761.  
  *Closest: 1000-member perfect-model E3SM ensemble against a deterministic FourCastNet, leads up to 10 days; the emulator is strongly under-dispersive and its error covariance differs.*
- Wu, E., and Coauthors, 2026: Stochastic Emulation of a Fully Coupled Preindustrial E3SMv3 Simulation. arXiv, https://doi.org/10.48550/arxiv.2608.10277. (Preprint, not peer reviewed.)  
  *Stochastic coupled emulator (ACE2S plus Samudra) of E3SMv3: climate statistics only, no initialized forecasts; a deterministic seed with a 6.6x too-strong ENSO still had good RMSE.*
- Brenowitz, N. D., and Coauthors, 2025: A Practical Probabilistic Benchmark for AI Weather Models. Geophys. Res. Lett., 52, e2024GL113656, https://doi.org/10.1029/2024gl113656.  
  *Probabilistic benchmark of AI weather models using lagged ensembles, against reanalysis.*
- Nathaniel, J., Y. Qu, T. Nguyen, S. Yu, J. Busecke, A. Grover, and P. Gentine, 2024: ChaosBench: A Multi-Channel, Physics-Based Benchmark for Subseasonal-to-Seasonal Climate Prediction. Advances in Neural Information Processing Systems 37, 43715–43729, https://doi.org/10.52202/079017-1386.  
  *ChaosBench: S2S benchmark; emulators collapse to climatology beyond about 15–20 days.*
- Lütjens, B., R. Ferrari, D. Watson‐Parris, and N. E. Selin, 2025: The Impact of Internal Variability on Benchmarking Deep Learning Climate Emulators. J. Adv. Model. Earth Syst., 17, e2024MS004619, https://doi.org/10.1029/2024ms004619.  
  *Internal variability distorts emulator benchmarks; larger ensembles change the conclusions.*
- Rodwell, M. J., M. C. A. Clare, S. Lock, K. Lonitz, and M. Chevallier, 2025: Power Spectra of Physics‐Based and Data‐Driven Ensembles. Meteor. Appl., 32, e70071, https://doi.org/10.1002/met.70071.  
  *Power spectra of spread and error in physics-based and data-driven ensembles.*
- Böger, J., S. Driscoll, N. Zagli, V. Lucarini, and F. C. Pereira, 2026: A Response Theory Probe for Learned Stochastic AI Simulators, Tested on Lorenz-63. arXiv, https://doi.org/10.48550/arxiv.2610.06798. (Preprint, not peer reviewed.)  
  *Response-theory test of learned stochastic simulators (Lorenz-63).*

## 2. Stochastic emulators, LIMs and fluctuation–dissipation

- Penland, C., and P. D. Sardeshmukh, 1995: The Optimal Growth of Tropical Sea Surface Temperature Anomalies. J. Climate, 8, 1999–2024, https://doi.org/10.1175/1520-0442(1995)008<1999:togots>2.0.co;2.  
  *LIM and non-normal optimal growth of tropical SST (ENSO).*
- Newman, M., 2007: Interannual to Decadal Predictability of Tropical and North Pacific Sea Surface Temperatures. J. Climate, 20, 2333–2356, https://doi.org/10.1175/jcli4165.1.  
  *LIM predictability of tropical and North Pacific SST at interannual to decadal leads; the model for extrapolating from 2-year to decadal leads.*
- Falasca, F., and L. Zanna, 2026: Physics constraints and response validation in discrete-time reduced-order modeling: from idealized turbulent systems to climate dynamics. arXiv, https://doi.org/10.48550/arxiv.2602.13847. (Preprint, not peer reviewed.)  
  *Closest: neural drift initialized from a LIM, stochastic closure fitted from residuals, validated by FDT (ENSO from ORAS5 SST/SSH); FDT is not used to constrain Q. Lists FDT calibration targets as future work.*
- Falasca, F., 2025: Probing forced responses and causality in data-driven climate emulators: Conceptual limitations and the role of reduced-order models. Phys. Rev. Res., 7, 043314, https://doi.org/10.1103/2f4r-k8lr.  
  *Neural stochastic emulators with multiplicative noise, judged by forced response.*
- Giorgini, L. T., F. Falasca, and A. N. Souza, 2025: Predicting forced responses of probability distributions via the fluctuation–dissipation theorem and generative modeling. Proc. Natl. Acad. Sci. USA, 122, e2509578122, https://doi.org/10.1073/pnas.2509578122.  
  *Generalized FDT with score-based generative models for nonlinear response.*
- Giorgini, L. T., T. Bischoff, and A. N. Souza, 2025: Statistical Parameter Calibration via the Generalized Fluctuation Dissipation Theorem and Generative Modeling. arXiv, https://doi.org/10.48550/arxiv.2509.19660. (Preprint, not peer reviewed.)  
  *Parameter calibration by generalized FDT, with no adjoint or tangent-linear model; an alternative to our AD noise calibration.*
- Agarwal, N., D. Kondrashov, P. Dueben, E. Ryzhov, and P. Berloff, 2021: A Comparison of Data‐Driven Approaches to Build Low‐Dimensional Ocean Models. J. Adv. Model. Earth Syst., 13, e2021MS002537, https://doi.org/10.1029/2021ms002537.  
  *Hybrid linear, deep-learning and stochastic emulators of an ocean model.*
- Lien, J., Y.-N. Kuo, H. Ando, and S. Kido, 2025: Colored linear inverse model: A data-driven method for studying dynamical systems with temporally correlated stochasticity. Phys. Rev. Res., 7, 023042, https://doi.org/10.1103/physrevresearch.7.023042.  
  *Colored-noise LIM.*
- Cheon, M., 2026: Rescene: stable century-long climate emulation from a frozen weather model. arXiv, https://doi.org/10.48550/arxiv.2608.09971. (Preprint, not peer reviewed.)  
  *Rescene: AR(1) noise with a fixed spectrum restores the spread of a frozen weather emulator.*

## 3. Strongly coupled covariance and coupled predictability

- Schneider, T., and S. M. Griffies, 1999: A Conceptual Framework for Predictability Studies. J. Climate, 12, 3133–3155, https://doi.org/10.1175/1520-0442(1999)012<3133:acffps>2.0.co;2.  
  *Predictable component analysis.*
- DelSole, T., and M. K. Tippett, 2009: Average Predictability Time. Part I: Theory. J. Atmos. Sci., 66, 1172–1187, https://doi.org/10.1175/2008jas2868.1.  
  *Average predictability time (APT).*
- Boer, G. J., 2004: Long time-scale potential predictability in an ensemble of coupled climate models. Climate Dyn., 23, 29–44, https://doi.org/10.1007/s00382-004-0419-8.  
  *Diagnostic potential predictability from long control runs.*
- Branstator, G., and H. Teng, 2010: Two Limits of Initial-Value Decadal Predictability in a CGCM. J. Climate, 23, 6292–6311, https://doi.org/10.1175/2010jcli3678.1.  
  *Perfect-model limits of initial-value decadal predictability in a CGCM.*
- Penny, S. G., and T. M. Hamill, 2017: Coupled Data Assimilation for Integrated Earth System Analysis and Prediction. Bull. Amer. Meteor. Soc., 98, ES169–ES172, https://doi.org/10.1175/bams-d-17-0036.1.  
  *Review of coupled data assimilation.*
- Sluka, T. C., S. G. Penny, E. Kalnay, and T. Miyoshi, 2016: Assimilating atmospheric observations into the ocean using strongly coupled ensemble data assimilation. Geophys. Res. Lett., 43, 752–759, https://doi.org/10.1002/2015gl067238.  
  *Strongly coupled EnKF in coupled SPEEDY–NEMO: atmospheric observations update the ocean.*
- Frolov, S., C. H. Bishop, T. Holt, J. Cummings, and D. Kuhl, 2016: Facilitating Strongly Coupled Ocean–Atmosphere Data Assimilation with an Interface Solver. Mon. Wea. Rev., 144, 3–20, https://doi.org/10.1175/mwr-d-15-0041.1.  
  *Interface solver for strongly coupled ocean–atmosphere DA.*
- Lu, F., Z. Liu, S. Zhang, Y. Liu, and R. Jacob, 2015: Strongly Coupled Data Assimilation Using Leading Averaged Coupled Covariance (LACC). Part II: CGCM Experiments*. Mon. Wea. Rev., 143, 4645–4659, https://doi.org/10.1175/mwr-d-15-0088.1.  
  *Leading averaged coupled covariance (LACC): lagged coupled covariances for strongly coupled DA in a CGCM.*
- O’Kane, T. J., and Coauthors, 2019: Coupled Data Assimilation and Ensemble Initialization with Application to Multiyear ENSO Prediction. J. Climate, 32, 997–1024, https://doi.org/10.1175/jcli-d-18-0189.1.  
  *Closest at seasonal-to-interannual leads: strongly coupled ensemble DA and multiyear ENSO prediction, cross-domain covariances, bred vectors.*
- Smith, P. J., A. S. Lawless, and N. K. Nichols, 2017: Estimating Forecast Error Covariances for Strongly Coupled Atmosphere–Ocean 4D-Var Data Assimilation. Mon. Wea. Rev., 145, 4011–4035, https://doi.org/10.1175/mwr-d-16-0284.1.  
  *Forecast-error cross-covariances for strongly coupled 4D-Var (single column).*
- Sandery, P. A., T. J. O’Kane, V. Kitsios, and P. Sakov, 2020: Climate Model State Estimation Using Variants of EnKF Coupled Data Assimilation. Mon. Wea. Rev., 148, 2411–2431, https://doi.org/10.1175/mwr-d-18-0443.1.  
  *96-member coupled EnKF; cross-covariance impacts over 7-day forecasts.*
- Chen, X., R. G. Nystrom, C. A. Davis, and C. M. Zarzycki, 2021: Dynamical Structures of Cross-Domain Forecast Error Covariance of a Simulated Tropical Cyclone in a Convection-Permitting Coupled Atmosphere–Ocean Model. Mon. Wea. Rev., 149, 41–63, https://doi.org/10.1175/mwr-d-20-0116.1.  
  *Cross-domain covariance of a tropical cyclone; 60–80 members needed.*
- Wright, A., A. S. Lawless, N. K. Nichols, D. J. Lea, and M. J. Martin, 2024: Assessment of short‐range forecast error atmosphere–ocean cross‐correlations from the Met Office coupled numerical weather prediction system. Quart. J. Roy. Meteor. Soc., 150, 2783–2797, https://doi.org/10.1002/qj.4735.  
  *Short-range ocean–atmosphere error cross-correlations in the Met Office coupled system.*
- Purcell, A., P. Brousseau, S. Malardel, and L. Berre, 2026: Background error covariances for a future coupled ocean–atmosphere data assimilation system: Case of tropical cyclone
                    <i>Batsirai</i>. Quart. J. Roy. Meteor. Soc., 152, e70118, https://doi.org/10.1002/qj.70118.  
  *Coupled background-error covariances (tropical cyclone Batsirai).*
- Bach, E., S. Motesharrei, E. Kalnay, and A. Ruiz-Barradas, 2019: Local Atmosphere–Ocean Predictability: Dynamical Origins, Lead Times, and Seasonality. J. Climate, 32, 7507–7519, https://doi.org/10.1175/jcli-d-18-0817.1.  
  *Local ocean–atmosphere predictability by Granger causality, from observations.*
- Yang, S.-C., C. Keppenne, M. Rienecker, and E. Kalnay, 2009: Application of Coupled Bred Vectors to Seasonal-to-Interannual Forecasting and Ocean Data Assimilation. J. Climate, 22, 2850–2870, https://doi.org/10.1175/2008jcli2427.1.  
  *Coupled bred vectors for seasonal-to-interannual ensembles.*
- Duan, W., L. Hu, and R. Feng, 2024: Coupled conditional nonlinear optimal perturbations and their application to ENSO ensemble forecasts. Sci. China Earth Sci., 67, 826–842, https://doi.org/10.1007/s11430-023-1273-1.  
  *Coupled CNOP initial perturbations for ENSO ensembles.*
- Tondeur, M., A. Carrassi, S. Vannitsem, and M. Bocquet, 2020: On Temporal Scale Separation in Coupled Data Assimilation with the Ensemble Kalman Filter. J. Stat. Phys., 179, 1161–1185, https://doi.org/10.1007/s10955-020-02525-z.  
  *Time-scale separation, Lyapunov spectra and EnKF in the MAOOAM coupled model.*
- Demaeyer, J., S. G. Penny, and S. Vannitsem, 2022: Identifying Efficient Ensemble Perturbations for Initializing Subseasonal‐To‐Seasonal Prediction. J. Adv. Model. Earth Syst., 14, e2021MS002828, https://doi.org/10.1029/2021ms002828.  
  *Ensemble initialization from Koopman eigenfunctions (DMD) and adjoint CLVs in a coupled low-order model.*
- Mao, Y., G. Zhang, H. Li, D. J. Amaya, S. G. Yeager, and S. Zhao, 2026: Precursors, Pathways, and State-Dependent Reliability of Long-range ENSO Prediction in the CESM2 Seasonal-to-Multiyear Large Ensemble. arXiv, https://doi.org/10.48550/arxiv.2609.25706. (Preprint, not peer reviewed.)  
  *CESM2 SMYLE 24-month ENSO hindcasts against the XRO reduced model; state-dependent under-dispersion.*
- Wang, C., M. S. Pritchard, N. Brenowitz, Y. Cohen, B. Bonev, T. Kurth, D. Durran, and J. Pathak, 2024: Coupled Ocean-Atmosphere Dynamics in a Machine Learning Earth System Model. arXiv, https://doi.org/10.48550/arxiv.2406.08632. (Preprint, not peer reviewed.)  
  *Ola: ML coupled ocean–atmosphere model with an internal ENSO.*

## 4. Adjoint sensitivity in chaotic and coupled models

- Lea, D. J., M. R. Allen, and T. W. N. Haine, 2000: Sensitivity analysis of the climate of a chaotic system. Tellus A, 52, 523, https://doi.org/10.3402/tellusa.v52i5.12283.  
  *Adjoints diverge in chaotic systems; an ensemble of adjoints estimates time-mean climate sensitivity to about 10%.*
- Lea, D. J., T. W. N. Haine, M. R. Allen, and J. A. Hansen, 2002: Sensitivity analysis of the climate of a chaotic ocean circulation model. Quart. J. Roy. Meteor. Soc., 128, 2587–2605, https://doi.org/10.1256/qj.01.180.  
  *Same in a chaotic ocean model: ensemble adjoint error about 25% for the mean, and it fails for variance.*
- Wang, Q., R. Hu, and P. Blonigan, 2014: Least Squares Shadowing sensitivity analysis of chaotic limit cycle oscillations. J. Comput. Phys., 267, 210–224, https://doi.org/10.1016/j.jcp.2014.03.002.  
  *Least-squares shadowing (LSS).*
- Ni, A., 2018: Adjoint shadowing directions in hyperbolic systems for sensitivity analysis. arXiv, https://doi.org/10.48550/arxiv.1807.05568. (Preprint, not peer reviewed.)  
  *Adjoint shadowing directions (the basis of NILSAS).*
- Thakur, P., and S. Nadarajah, 2025: Adjoint of Least Squares Shadowing: Existence, Uniqueness and Coarse Domain Discretization. J. Sci. Comput., 105, 47, https://doi.org/10.1007/s10915-025-03075-w.  
  *Adjoint LSS: existence, uniqueness and convergence.*
- Thakur, P., and S. Nadarajah, 2025: A stabilized march approach to adjoint-based sensitivity analysis of chaotic flows. arXiv, https://doi.org/10.48550/arxiv.2505.00838. (Preprint, not peer reviewed.)  
  *Stabilized-march adjoint shadowing.*
- Köhl, A., I. Polkova, G. Lyu, F. Lunkeit, A. Banerjee, S. Schubert, and D. Stammer, 2026: A pilot variational coupled reanalysis based on the CESAM climate model. Quart. J. Roy. Meteor. Soc., 152, e70092, https://doi.org/10.1002/qj.70092.  
  *CESAM: a 39-year coupled adjoint made possible by nudging the atmosphere to ERA5; in effect an ocean synthesis, and not usable for forecasts.*
- Moore, A. M., and R. Kleeman, 1996: The dynamics of error growth and predictability in a coupled model of ENSO. Quart. J. Roy. Meteor. Soc., 122, 1405–1446, https://doi.org/10.1002/qj.49712253409.  
  *Error growth and predictability in a coupled ENSO model.*

## 5. Targeted observing for ENSO

- Morss, R. E., and D. S. Battisti, 2004: Evaluating Observing Requirements for ENSO Prediction: Experiments with an Intermediate Coupled Model. J. Climate, 17, 3057–3073, https://doi.org/10.1175/1520-0442(2004)017<3057:eorfep>2.0.co;2.  
  *OSSEs with a linear stochastic ENSO model; sensitive regions follow the leading singular vector.*
- Duan, W., X. Li, and B. Tian, 2018: Towards optimal observational array for dealing with challenges of El Niño-Southern Oscillation predictions due to diversities of El Niño. Climate Dyn., 51, 3351–3368, https://doi.org/10.1007/s00382-018-4082-x.  
  *Optimal-growth (CNOP) targeting for the two types of El Niño.*
- Zhang, J., S. Hu, and W. Duan, 2021: On the sensitive areas for targeted observations in ENSO forecasting. Atmos. Ocean. Sci. Lett., 14, 100054, https://doi.org/10.1016/j.aosl.2021.100054.  
  *Sensitive areas from initial-error growth against a particle filter.*
- Hou, M., Y. Tang, W. Duan, and Z. Shen, 2023: Toward an optimal observational array for improving two flavors of El Niño predictions in the whole Pacific. Climate Dyn., 60, 831–850, https://doi.org/10.1007/s00382-022-06342-w.  
  *Particle-filter targeting across the whole Pacific.*
- Rao, W., and Coauthors, 2023: A new ensemble-based targeted observational method and its application in the TPOS 2020. Natl. Sci. Rev., 10, nwad231, https://doi.org/10.1093/nsr/nwad231.  
  *EnKF targeted observing for TPOS 2020.*
- Rao, W., Y. Tang, Y. Wu, and X. Li, 2025: A Model‐Independent Strategy for the Targeted Observation Analysis and Its Application in ENSO Prediction. J. Adv. Model. Earth Syst., 17, e2024MS004742, https://doi.org/10.1029/2024ms004742.  
  *Model-independent multi-model targeting, verified with OSSEs.*
- Li, X., Y. Tang, M. J. McPhaden, L. Zhou, Y. Li, X. Song, T. Lian, and D. Chen, 2025: Quantifying the role of tropical Indian Ocean observations to central Pacific El Niño prediction. Environ. Res. Lett., 20, 074023, https://doi.org/10.1088/1748-9326/addbf3.  
  *Indian Ocean observations for central-Pacific El Niño prediction.*

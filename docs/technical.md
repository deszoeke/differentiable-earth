# Technical notes

Living document: the methods and implementation choices, written before each piece is built.
See `docs/plan.md` for the overall plan and `docs/julia_pin.md` for the Julia version pin.

References:
- Moses et al. (2026), *DJ4Earth: Differentiable, and performance-portable Earth system modeling via program transformations*, JAMES, doi:10.1029/2025ms005615.
- Reproduction code: github.com/DJ4Earth/differentiable-esm-components-2025.

## Notation (used in all project documents)
One symbol per quantity; time dependence is always an argument in parentheses (no subscript 0). Full references: `docs/references.md`.

**Times**
| Symbol | Meaning |
|---|---|
| t | absolute (model or calendar) time, e.g. a start date; month(t) is its season |
| τ | time separation: lag in nature-run statistics, and lead in forecasts (time since the reference time t) |
| ℓ | the fixed LIM fitting lag, as in L = (1/ℓ) log G(ℓ) |
| n | number of model time steps; Δt is the model time step, so τ = n Δt |

**State, members, averages**
| Symbol | Meaning |
|---|---|
| x | anomaly state vector (departure from the nature run's seasonal climatology) |
| x_k | ensemble member k; x̄ is the ensemble mean (average of x_k over k) |
| ⟨·⟩ | an average; always stated "over t" (in the nature run) or "over k" (over members) |
| ᵀ | transpose |

**Covariances and operators**
| Symbol | Meaning |
|---|---|
| C(τ) | nature-run lag covariance ⟨x(t+τ) x(t)ᵀ⟩ over t (the model's own climate, not observations); C(0) is the nature-run covariance. Seasonal version: C(τ; month), averaged only over t in that calendar month |
| Σ(τ; t) | forecast (ensemble) covariance at lead τ for the ensemble started at t: ⟨(x_k(t+τ) − x̄(t+τ)) (x_k(t+τ) − x̄(t+τ))ᵀ⟩ over k. Σ(0; t) is the initial-uncertainty (analysis-error) covariance. The start argument t is dropped when it is clear |
| Σ(τ, 0) | ensemble cross-covariance between member deviations at lead τ and at the start |
| S(τ) | signal covariance: covariance over starts t of the ensemble means x̄(t+τ). C(0) = ⟨Σ(τ; t)⟩ over t + S(τ) |
| M(τ) | the forecast map: the nonlinear model run for lead τ |
| M′(τ) | tangent-linear propagator (Jacobian of M along a trajectory); M′(τ)ᵀ is the adjoint |
| z | adjoint (cotangent) vector, as in z(0) = M′(τ)ᵀ z(τ) |
| L | LIM generator: dx/dt = L x + noise |
| G(τ) | propagator of the expected forecast, C(τ) C(0)⁻¹ = exp(Lτ); also estimated from ensembles, as G(τ; x) = Σ(τ, 0) Σ(0)⁻¹ conditioned on the start state x, or G(τ; month) seasonally |
| Q | noise covariance, −(L C(0) + C(0) Lᵀ); seasonal: Q(t) = dC/dt − L(t) C(t) − C(t) L(t)ᵀ |
| N(τ) | covariance added by noise since the start, C(0) − G(τ) C(0) G(τ)ᵀ, so Σ(τ) = G(τ) Σ(0) G(τ)ᵀ + N(τ) |
| A | tendency Jacobian ∂f/∂x evaluated at a fixed basic state (for linear stochastic models) |
| J | scalar forecast metric, e.g. Niño-3.4 at lead τ |
| g | sensitivity ∂J/∂x(0); for the expected forecast, g = ∂⟨J(M(x(0) + ε))⟩/∂x(0), averaged over ε ~ N(0, Σ(0)) |
| W | weighting matrix defining a norm |
| H, R | observation operator and observation-error covariance (targeting and assimilation) |
| s | climatological standard deviation of each variable, √diag C(0) |
| λ | Lyapunov exponent (error growth rate) |

Toy-model parameters (F, α, β, λ for slab damping, R, γ, σ, ϵ, r, a, μ, …) are named in §2 only and are not project notation.

## 1. The propagator interface
Every analysis is written against `AbstractPropagator` (`DifferentiableEarth/src/propagator.jl`). A propagator has:
- a flat state vector `x`;
- `advance(m, x)`, which takes one time step and returns a new vector without mutating `x`;
- `propagate(m, x, n)`, which takes n steps: the forecast map M(τ) for lead τ = n Δt;
- `state_slices(m)`, which names the parts of the state.

The toy model and, later, the coupled NumericalEarth model both implement this interface. Covariances, singular vectors, targeting and OSSEs therefore run unchanged on either.

## 2. The toy model: `ToyCoupled`
`DifferentiableEarth/src/toy/toy_coupled.jl`. A Lorenz-96 "atmosphere" of K = 36 sectors, coupled to a slab ocean under each sector and to a recharge-oscillator ENSO. It is meant to have the same three time scales as the real problem:

| Component | Variables | Time scale | Role |
|---|---|---|---|
| Lorenz-96 | X₁…X_K | days (chaotic; 1 model time unit ≈ 5 days) | weather noise, limits atmospheric predictability |
| slab ocean | T₁…T_K | ~90 days (λ⁻¹ = 18 units) | ocean memory, local SST persistence |
| recharge oscillator | Tₑ, h | years (period ≈ 3.7 years, irregularity CV ≈ 0.3) | ENSO-like predictable signal |

Equations:
- dX_k/dt = (X_{k+1} − X_{k−2}) X_{k−1} − X_k + F + α T_k + αₑ p_k Tₑ
- dT_k/dt = −λ T_k + β (X_k − X̄) + κ (T_{k+1} − 2T_k + T_{k−1})
- dTₑ/dt = R Tₑ + γ h + σ ξ − ϵ Tₑ³
- dh/dt = −r h − a (μ Tₑ + ξ)

where ξ is the mean of (X_k − X̄) over the "equatorial" sectors 1…n_eq (a wind-burst forcing) and p_k is a wavenumber-1 teleconnection pattern.

**Model statement: what the variables represent.** All variables are anomalies and nondimensional (nominal units in the NetCDF files); one model time unit ≈ 5 days.
- **X_k (k = 1…36):** a Lorenz-96 "atmosphere" variable in longitude sector k around a latitude circle, such as a wind or geopotential anomaly. X (no subscript) is the vector of all 36. X̄ = 2.3 is its approximate climatological mean, used to form anomalies. Sectors 1…n_eq (n_eq = 4) are labelled "equatorial".
- **T_k:** the surface (thermodynamic, slab-ocean mixed-layer) temperature anomaly under sector k. It is damped (λ), forced by an atmospheric heat flux β(X_k − X̄), diffused zonally (κ), and feeds back on the atmosphere through α T_k.
- **Tₑ:** the eastern equatorial Pacific SST anomaly, a Niño-3-like ENSO index, as in Jin's (1997) recharge oscillator. It is *not* a basin-mean temperature or heat content. It is the eastern Pacific surface temperature, set by **upwelling** of subsurface water whose temperature depends on the thermocline depth.
  - In the toy, the upwelling enters as the thermocline feedback γ h (a deeper thermocline means warmer upwelled water). R Tₑ represents the Bjerknes wind–SST feedback combined with damping.
  - The nonlinearity of upwelling is represented only crudely, by the symmetric cubic damping −ϵ Tₑ³. That term bounds the oscillation but gives no El Niño/La Niña asymmetry.
  - A quadratic nonlinear-upwelling term, such as a nonlinear dynamical-heating term ∝ Tₑ² or ∝ Tₑ h, would add the observed asymmetry if needed.
- **h:** the western equatorial Pacific thermocline-depth anomaly, i.e. the equatorial heat content to be discharged or recharged. It responds only to the basin-scale zonal wind stress τ = μ Tₑ + ξ (dh/dt = −r h − a τ). Tₑ is driven by the thermocline feedback γ h, the Bjerknes growth/damping R, the wind bursts σ ξ and cubic damping ϵ Tₑ³.
- **ξ:** the mean of (X_k − X̄) over the equatorial sectors: atmospheric "wind bursts", the stochastic forcing of ENSO.
- **Couplings.** atmosphere → ENSO through ξ; ENSO → atmosphere through the teleconnection αₑ p_k Tₑ (wavenumber 1); ocean ↔ atmosphere locally through α and β.
- **Simplifications to keep in mind:**
  - Tₑ is *not* the slab-ocean temperature of the equatorial sectors: T₁…T₄ and Tₑ are separate variables, linked only through the atmosphere.
  - The model has no zonal basin geometry: "eastern" and "western" are labels on Tₑ and h, not locations among the sectors.

The coupling runs both ways:
- the ocean forces the atmosphere through α T_k;
- ENSO forces it through αₑ p_k Tₑ;
- the atmosphere forces the ocean through β and ξ.

So the full covariance has ocean–atmosphere cross-terms, as the real one will.

Time stepping is RK4 with Δt = 0.05 (≈ 6 h). The code uses only whole-array operations (`circshift`, broadcasts, `sum`, `vcat`, and 1-element slices instead of scalar indexing), with no data-dependent branches. That makes it traceable by Enzyme and by Reactant.

Why a toy model first:
- The analysis code (covariances C and Σ, singular vectors, targeting ΔVar, ETKF/OSSE) can be checked against exact answers in seconds.
- The Enzyme/Reactant workflow can be learned on a model small enough that its full Jacobian fits in memory (74 × 74), so every AD result can be checked against a brute-force one.

Status: implemented and tested (`DifferentiableEarth/test/test_toy.jl`). The tests cover the Lorenz-96 limit, purity, boundedness and sensitive dependence on initial conditions. **ENSO tuning (2026-11-15).** The first guess was a self-sustained oscillation: R = +0.002, γ = 0.02, σ = 0.01. Its period was ≈ 3.8 years, but it was too regular: the CV of cycle lengths was ≈ 0.1 over 300 years.
- The defaults are now a damped, noise-driven oscillator: **R = −0.006, γ = 0.0156, σ = 0.03**.
- That gives a CV of ≈ 0.3 (0.32 and 0.27 for two seeds over 300 years), about 3× the first guess, close to observed ENSO.
- Period: 3.6–3.8 years. std(Tₑ): ≈ 0.28.
- Sweeps: `drivers/toy_enso_sweep.jl`, run in `run/toy-enso-*`.
- Damping shortens the period, so γ was lowered to restore it (period ∝ 1/√(γa)).

## 3. Automatic differentiation: the approach (proposed, not yet implemented)
APIs were checked against the installed Reactant 0.2.308 and Enzyme 0.13.219 on 2026-11-15.

### 3.1 What we need from AD
Write M(τ) = `propagate(m, ·, n)` for the forecast map over lead τ = n Δt, and M′(τ) = ∂M/∂x for its Jacobian along the trajectory from x(0). We never form M′ for the real model, which would be millions by millions. Instead we compute its products with vectors:
- **Tangent-linear model (TLM), a JVP:** δx(τ) = M′(τ) δx(0). This is how a small initial perturbation grows, to first order. In AD terms it is *forward mode*: one forward run carrying a tangent alongside the state.
- **Adjoint, a VJP:** z(0) = M′(τ)ᵀ z(τ). For a scalar forecast metric J(x(τ)), such as Tₑ at lead τ, the gradient g = ∂J/∂x(0) = M′(τ)ᵀ ∇J. In AD terms it is *reverse mode*: run forward, then propagate sensitivities backward from τ to 0. One reverse pass gives the sensitivity of J to **every** initial-state variable at once, which is why the targeting analysis is affordable.
- Singular vectors and the Σ(0)-weighted analyses call these two products repeatedly, inside KrylovKit's Lanczos iterations.

### 3.2 Plain Enzyme
Enzyme differentiates the compiled LLVM code of ordinary Julia functions:
- **JVP:** `Enzyme.autodiff(Forward, x -> propagate(m, x, n), Duplicated(x, v))[1]`. `Duplicated(x, v)` pairs the input with its tangent v, and the result is the output tangent M′ v.
- **VJP:** reverse mode needs a scalar output, so differentiate the scalar z·M(x). Its gradient is exactly M′ᵀz: `Enzyme.gradient(Reverse, x -> dot(z, propagate(m, x, n)), x)[1]`. For J itself, `Enzyme.gradient(Reverse, x -> J(propagate(m, x, n)), x)[1]`.
- **Activities:** `Duplicated` (differentiated array, with a shadow), `Const` (not differentiated, e.g. the model parameters), `Active` (a differentiated scalar return).
- **Cost:** reverse mode stores the forward trajectory, so memory grows with n. That's fine for the toy, but this is why checkpointing exists.

### 3.3 Reactant
Reactant **traces** a Julia function into a compiler graph (MLIR/StableHLO), optimizes it, and compiles it with XLA for CPU (here) or GPU (HPC). Reactant's gradient is Enzyme run on that graph (EnzymeMLIR), so it is the same AD applied one level down.
1. **Convert inputs:** `xr = Reactant.to_rarray(x)` gives a `ConcreteRArray`. Scalars become `ConcreteRNumber` only if asked.
2. **Compile once:** `vjp_c = @compile vjp(m, xr, zr)` traces and compiles. Calling `vjp_c(m, xr2, zr2)` then runs at compiled speed for new inputs. `Array(result)` brings the result back.
3. **Loops must be traced.** A plain Julia `for` loop would be unrolled n times at trace time. `@trace for _ in 1:n ... end` becomes one compiled `while` loop. `@trace` does nothing outside Reactant, so the package's `propagate` can carry it and serve plain Julia, plain Enzyme and Reactant from **one code path**.
4. **Checkpointing:** `@trace checkpointing=... mincut=true for ...`.
   - `checkpointing=true` stores √n states and recomputes the rest.
   - `Reactant.Periodic(k)` stores k states.
   - `Reactant.Binomial(b)` uses the revolve algorithm with a budget of b states; it is recommended when n is a traced number.
5. **Baked-in constants:** a plain Julia value passed to `@compile` (Δt, the model parameters, a Julia `Int` n) is frozen into the compiled code. Calling it later with a different value silently uses the old one. To vary n without recompiling, pass `n` as `ConcreteRNumber` and use `Binomial` checkpointing. Our default instead compiles one function per lead time, which is simpler and cheap for the toy.
6. **Rules for traced code:** no scalar indexing without `@allowscalar` (the toy uses 1-element slices), and no data-dependent Julia `if` (use `@trace if`, or smooth the switch).

### 3.4 How we know the derivatives are right
Run on the toy for every propagator; the coupled model later gets the first four (`differentiable-code` skill):
1. **Finite differences:** (J(x+εv) − J(x−εv))/2ε ≈ ∇J·v over ε = 1e-2 … 1e-8.
2. **Dot-product test:** ⟨M′δx, z⟩ = ⟨δx, M′ᵀz⟩ to round-off. This shows the adjoint really is the transpose of the TLM.
3. **Reactant equals plain Enzyme** to round-off, which catches tracing bugs.
4. **TLM validity against lead time:** compare M(x+δx) − M(x) with M′δx as τ grows. The atmosphere's part should fail within a few weeks, because of chaos. ENSO-related directions should stay linear much longer. This sets where adjoint results can be trusted, and motivates the ensemble-averaged gradients in the plan.
5. **Toy only:** the full Jacobian (`Enzyme.jacobian`, 74×74) against all of the above.

## 4. Sensitivities that survive chaos (toy comparison, phase 1)
**Why.** The tutorial (`docs/tutorial_enzyme_reactant.md` §6) showed that a single-trajectory adjoint grows like e^(λτ), with a doubling time of about 2 days. Beyond about 2 weeks it says nothing about the forecast we actually care about. For targeting at monthly-to-interannual leads, the right object is the sensitivity of the **expected** forecast to the **slow** initial state (the ocean T_k, Tₑ and h: 38 variables). The expectation is taken over the analysis uncertainty, which is dominated by the chaotic atmosphere:

  gᵢ = ∂⟨J(M(x(0) + ε))⟩ / ∂xᵢ(0), averaged over ε ~ N(0, Σ(0)), with i over the slow variables.

**Truth (exact ensemble answer).** For each slow variable i, centered finite differences of the ensemble mean, using paired ("common random number") ensembles:

  gᵢ ≈ ( ⟨J(M(x(0) + δᵢ eᵢ + ε_k))⟩ − ⟨J(M(x(0) − δᵢ eᵢ + ε_k))⟩ ) / 2δᵢ, averages over members k = 1…N.

The step is δᵢ = 0.5 sᵢ: large enough to beat the sampling noise, and smooth because of the ensemble average. Its standard error comes from the member-by-member differences. Cost: 38 × 2 × N forecasts per initial state. That's cheap for the toy and impossible for the real model; it exists to judge the estimators below.

**Estimators** (all affordable for the coupled model):
1. **Single-trajectory adjoint** ∂J/∂x(0) at x(0): one reverse pass. Expected to fail beyond about 2 weeks.
2. **Ensemble-mean adjoint:** the mean over members of ∂J/∂x(0) at x(0) + ε_k, with N reverse passes. Its expectation equals gᵢ, but in chaotic systems its variance grows like e^(2λτ), so it may not converge at long leads (Lea, Allen & Haine 2000, *Tellus*).
3. **Ensemble (regression) sensitivity:** regress J(τ) on the initial slow perturbations across an ensemble drawn from Σ(0) (Ancell & Hakim 2007). With a diagonal Σ(0) this estimates gᵢ directly, using N forward runs and no adjoint.
4. **LIM (linear inverse model):** fit dx/dt = L x on the slow variables from the nature run, with G(ℓ) = C(ℓ) C(0)⁻¹ and L = (1/ℓ) log G(ℓ). Then g = the row of exp(Lτ) for J. It is statistical and state-independent, uses no model runs, and is the basis of the "modes from the covariance" analysis.

**Initial uncertainty Σ(0) (diagonal):** atmosphere 0.1 s; ocean T_k, Tₑ and h 0.05 s, where s is the climatological standard deviation of each variable. (Earlier text and the tutorial notebook called it σ or s_clim; the drivers' NetCDF variables keep the names `sigma_clim` and `s_clim`.)

**Leads:** 2 weeks, 2 months, 6 months, 1 year, 2 years. **Initial states:** several, at different ENSO phases.

**Scores against the truth, by lead:** pattern correlation and relative RMS error over the 38 slow variables, plus the components for Tₑ and h, and cost.

Code: `DifferentiableEarth/src/sensitivity.jl`, `drivers/toy_sensitivity_comparison.jl`, `plots/sensitivity_comparison_pluto.jl`.

### 4.1 First results (2026-11-16, `run/toy-sensitivity/`)
4 initial states; truth from 200 paired members with δ = 0.5 s; ensemble-mean adjoint from the same 200 members; regression from 400 members; LIM fit to 50 years.

Pattern correlation with the truth (J = Tₑ), pooled over states, at leads 2 wk / 2 mo / 6 mo / 1 yr / 2 yr:

| estimator | 2 wk | 2 mo | 6 mo | 1 yr | 2 yr |
|---|---|---|---|---|---|
| single-trajectory adjoint | 0.98 | 0.10 | −0.22 | −0.11 | −0.21 |
| ensemble-mean adjoint | 1.00 | −0.21 | −0.11 | −0.04 | −0.13 |
| regression | 0.41 | 0.12 | 0.11 | −0.05 | 0.01 |
| LIM | 0.99 | 0.89 | 0.66 | 0.64 | 0.41 |

| truth signal/noise, rms(truth)/rms(s.e.) | 2 wk | 2 mo | 6 mo | 1 yr | 2 yr |
|---|---|---|---|---|---|
| J = Tₑ | 49 | 2.3 | 1.6 | 1.3 | 1.2 |
| J = T₁ | 24 | 1.1 | 1.1 | 0.9 | 1.0 |

What it shows:
1. **At 2 weeks, the adjoints are excellent.** The ensemble-mean adjoint has a relative error of 0.04. The LIM is almost as good (0.13).
2. **Beyond 2 weeks, both adjoints fail completely.** Their relative errors are 1e6 at 2 months and 1e50 or more at 1 year. The ensemble-mean adjoint does **not** converge, as Lea et al. (2000) predict: its variance grows like e^(2λT).
3. **Regression is poor at every lead.** The initial slow-variable spread is small (0.05 s), so the regression signal is buried in atmosphere-driven variance of J. This is an intrinsic weakness of ensemble sensitivity when analysis errors in the slow variables are small.
4. **The LIM is the only estimator that keeps skill at long leads** (Tₑ: 0.89 at 2 months, 0.64 at 1 year).
5. **Caveat: the truth is noise-dominated beyond about 2 months** (signal/noise ≈ 1–2, and ≈ 1 for T₁). The long-lead scores therefore under-state every estimator, and the T₁ results beyond 2 weeks can't be interpreted. The truth needs a redesign (§4.2).

### 4.2 Next: a resolvable truth (proposed)
Estimate the expected-forecast sensitivity along a few **directions** instead of 38 individual variables, with many more members:
- **Directions:** Tₑ, h, and the leading slow-variable patterns (LIM/EOF modes).
- **Members:** about 2000.

Score the estimators by projecting them onto the same directions. Optionally add a hybrid estimator: an adjoint over the short TLM-valid window (about a week), then the LIM beyond it.

---
name: add-phenomenon
description: Steps for adding a new phenomenon (ENSO, PDO, NAM, SAM, PNA, MJO, MHW, AR, a seasonal regional outcome, ...) to the PredictableOcean phenomenon registry, so it can be selected, filtered, skill-scored, and used in predictability and targeting analyses. Use whenever a new target index or pattern is requested.
---

# Adding a phenomenon

Every analysis (covariance, predictability, targeting, OSSE) is written against the `Phenomenon` interface in `PredictableOcean/src/phenomena/`. Adding a target means adding one definition plus a test, without touching the analysis code.

## 1. Define it: `src/phenomena/<name>.jl`
A `struct <Name> <: Phenomenon` holding its parameters, plus methods for the interface:
- `variables(p)`: the state fields it needs, e.g. `(:sst,)` or `(:u850, :u200, :olr)`.
- `region(p)`: lon/lat box(es) or a mask.
- `filter(p)`: time handling, e.g. seasonal mean, band-pass (20–100 days for the MJO), or running mean, plus spatial smoothing and the start months or seasons it applies to.
- `index(p, x)`: the scalar index **J(x)**. It must be **differentiable and Reactant-safe** (follow the `differentiable-code` skill), since its gradient seeds the adjoint.
- `pattern(p)`: a spatial pattern for projecting B and ensembles. Learn it from the **model's own nature run** (EOF or regression), then save it to NetCDF and load it, rather than recomputing it.
- `tier(p)`:
  - 1: coarse and likely resolved (ENSO, PDO, NAM/AO, SAM, PNA, seasonal means);
  - 2: marginal (MJO/BSISO, NAO, blocking);
  - 3: local or extreme (MHW, AR).
- `resolved(p, nature_run)`: a diagnostic of whether the model produces the phenomenon (spectrum, pattern, seasonality), returning numbers, not just true/false.

Register it in `src/phenomena/registry.jl` with a symbol (`:enso`, `:sam`, ...) so drivers can call `run_analysis(phenomena=[:enso, :sam], ...)`.

## 2. Test it: `test/phenomena/test_<name>.jl`
- The index is correct on a synthetic field whose answer is known, e.g. a uniform +1 K anomaly in the Niño-3.4 box gives an index of +1 K.
- The gradient of `index` passes a finite-difference check, and the Reactant result matches plain Enzyme.
- The filter preserves a test signal inside its band and removes one outside it.

## 3. Document it
- Add a row to the phenomenon table in `docs/technical.md`: definition, variables, filter, pattern source, tier.
- When results exist, record skill and whether it is resolved in `docs/results.md`, linking the NetCDF file and the driver.

## 4. Plot it (optional)
Add a configurable plotting function in `plots/plotlib.jl` only if the standard figures (index time series, skill against lead, lead–season map, pattern map) aren't enough. Follow `plots/CLAUDE.md`.

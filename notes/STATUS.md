# Status

_Last updated 2026-11-15._

## Done
- Plan adopted (`docs/plan.md`).
- Julia 1.11.9 installed, with a juliaup override in this repo.
- Tools: `gh` (logged in), plus `jupytext` and `nbstripout` from the micromamba `nbtools` env, symlinked into `~/.local/bin`.
- Agents (`code-reader`, `upstream-scout`) and skills (`julia-env`, `differentiable-code`, `add-phenomenon`, `netcdf-output`) written.

## Next
1. Resolve the main environment on 1.11.9: `DifferentiableEarth` package skeleton plus the target versions in `docs/plan.md`. Commit the Manifest.
2. Build graphify graphs of the upstream package sources (`helpers/graph_package.sh`).
3. Build the toy model (`ToyCoupled`, using the `AbstractPropagator` interface), with tests.
4. Write the Enzyme/Reactant tutorial on the toy model (`docs/tutorial_enzyme_reactant.md`, `drivers/tutorial_ad.jl`).
5. Coupled smoke test: update `test_NumericalEarth.jl` to `EarthSystemModel`.

## Open questions
- None right now.

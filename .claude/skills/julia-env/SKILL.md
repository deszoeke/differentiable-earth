---
name: julia-env
description: How to run, test, precompile and inspect Julia in the predictable-ocean project (Julia 1.11 pin, project environments, time limits, package versions). Use before running any julia command here, or when packages fail to load or recompile.
---

# Julia in predictable-ocean

## Versions
- **Julia 1.11.9 is pinned.** A juliaup override applies in this repo, so `julia` starts 1.11 here. In scripts and jobs, write `julia +1.11` explicitly. Rationale and unpin criteria: `docs/julia_pin.md`. Never change the pin casually.
- Check with `julia --version` (expect 1.11.9) and `juliaup status`.
- **The override applies only inside this repo.** From any other directory (e.g. a scratch folder), plain `julia` starts the default 1.13, which recompiles everything for minutes and can fail (2026-11-15: `MbedTLS_jll` is a 1.11 stdlib, absent in 1.13). Outside the repo, always write `julia +1.11`.

## Environments
| Environment | Path | Contents |
|---|---|---|
| main / drivers | `Project.toml` (repo root) | `PredictableOcean` (path source), Reactant, Enzyme, model packages. Manifest **committed**. |
| package | `PredictableOcean/Project.toml` | package deps and `[compat]` bounds; tests in `PredictableOcean/test/` |
| plotting | `plots/Project.toml` | CairoMakie, GeoMakie, NCDatasets, Revise, IJulia; no model packages; Manifest not committed |

## Commands
| To | Run |
|---|---|
| instantiate on a new machine | `julia --project=. -e 'using Pkg; Pkg.instantiate()'` |
| run the package tests | `julia --project=PredictableOcean -e 'using Pkg; Pkg.test()'` |
| run one test file quickly | `julia --project=. PredictableOcean/test/<file>.jl` |
| run a driver | `cd run/<name> && julia --project=../.. <driver>.jl` |
| package versions in use | `julia --project=. -e 'using Pkg; Pkg.status()'` |
| where a package's source is | `julia --project=. -e 'using Pkg; println(pkgdir(Base.require(Main, :Oceananigans)))'` |
| what would recompile | `julia --project=. -e 'using Pkg; Pkg.precompile()'` (slow the first time) |

## Time limits and etiquette
- I may run unit tests and smoke tests under about 2 minutes. Give the Bash tool a `timeout`. Run longer jobs (`Pkg.add`/`instantiate`/first precompile of Reactant, which take many minutes) with `run_in_background`, and tell the user.
- The user runs experiments. Don't re-run anything to verify unless asked.
- **Long local runs: prefix `caffeinate -i`** (e.g. `caffeinate -i julia --project=../.. driver.jl`). Without it, macOS throttles or suspends background runs when the machine idles or sleeps. On 2026-11-16 a 5-day coupled smoke test used 23% CPU over 43 min, and two truth computations took about 3.5 h instead of 70 s.
- Reactant's first `@compile` of a function takes seconds to minutes. Recompiling after a code change is expected and acceptable.

## Changing packages
- Ask before adding a dependency. Add it to the right environment, then set `[compat]` to the resolved version (`~x.y.z` for fragile AD packages: Reactant, Enzyme, Oceananigans, SpeedyWeather, NumericalEarth).
- After a change, commit `Manifest.toml` when asked, and note the change in `notes/STATUS.md`.
- Before upgrading Reactant, Enzyme or Oceananigans, ask `upstream-scout` for a compatibility check.

## HPC (later)
- Use Slurm only, never the head node. Use `julia +1.11` in job scripts. The user-level `~/.config/julia/arch_env.sh` sets the CPU target and depot.
- For Reactant on GPU nodes, set `[preferences.Reactant_jll] gpu = "cuda"` so login nodes without `libcuda` don't pick the CPU build.
- **Never run `ssh`, `scp` or `rsync` yourself unless the user explicitly asks.**

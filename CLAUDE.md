# differentiable-earth

A perfect-model study of coupled ocean–atmosphere predictability, from months to years, using a differentiable NumericalEarth + SpeedyWeather + Oceananigans model, differentiated with Reactant and Enzyme. Two aims:
- build the strongly coupled covariance matrix and find modes of variability from it;
- an idealized system that suggests where and when to take targeted observations.

- **Plan:** `docs/plan.md`.
- **Picking up the work:** read `notes/STATUS.md` first, and keep it current.
- **For any plot, figure or notebook task:** read `plots/CLAUDE.md` first.

## Environment
- **Julia 1.11 is pinned:** a juliaup override on the Mac, and `julia +1.11` in job scripts. Why, and when to lift it: `docs/julia_pin.md`. Don't change the pin without checking the criteria there.
- `Manifest.toml` is committed for the main environment, so the laptop and the HPC run identical Reactant/Enzyme versions. `plots/` has its own environment, unpinned, and its Manifest is not committed.
- **Commands:** run `julia --project=.` in the repo. Run tests with `julia --project=PredictableOcean -e 'using Pkg; Pkg.test()'`. More in the `julia-env` skill.
- **HPC path:** `/ceoas/deszoeks/projects/differentiable-earth`. Slurm only; never compile on the head node.

## Rules
- **Never run `ssh`, `scp`, `sftp` or remote `rsync` unless the user explicitly asks.** This holds in auto mode too.
- Re-read a file right before editing it, and keep edits small and targeted. The user edits and runs code between turns.
- **Running code:** I may run unit tests and smoke tests that finish in under ~2 minutes. The user runs experiments. Don't re-run anything to verify unless asked.
- Numbers that matter come from saved, rerunnable code (a driver, test or plotting function), never from scratch scripts.
- **Heavy computation goes in non-interactive driver scripts** (`drivers/`, copied into `run/<name>/`, later Slurm) that write NetCDF. Notebooks (Pluto by default, Jupyter for the HPC) read and plot. Only the toy model may be computed inside a notebook.
- **Explain first:** before implementing each Enzyme or Reactant piece, explain the approach in chat and in `docs/technical.md`. Ask questions rather than assume; the user is new to Enzyme and Reactant.
- **Commits:** commit and push only when asked. Work on `main` on every machine (Mac and HPC push and pull the same branch). Mark phase milestones with annotated tags (`phaseN-...`, pushed with `git push origin --tags`). Use a branch only for a genuinely risky experiment, and delete it when done. Close Pluto notebooks before any branch switch: Pluto re-saves files git is changing.
- **Install nothing without asking.** Tools live in micromamba envs, symlinked into `~/.local/bin`: `gh`, `jupytext`, `nbstripout`. `graphify` is a uv tool.

## Code standards
- Type-stable functions, no globals, dispatch rather than branching on keyword values, docstrings on exported API, Blue style.
- Aqua and JET run in the tests.
- **Reactant-safe traced code:** no host control flow on traced values, no scalar indexing, no logging inside traced functions; loops written with `@trace`. Constants such as regridding weights are passed in. See the `differentiable-code` skill.
- **Output:** NetCDF only, with provenance attributes (git commit and dirty flag, settings, Julia and package versions, host). See the `netcdf-output` skill.
- **Notebooks:** Pluto `.jl` files are the default. Jupyter `.ipynb` files are paired with percent `.jl` files, and I never write an `.ipynb` (see `plots/CLAUDE.md`).

## Who reads code
- **File and line already known:** read them directly.
- **Anything else** (finding code, tracing calls, reading upstream package sources such as NumericalEarth and its extensions, Oceananigans and its Reactant/Enzyme extensions, SpeedyWeather, Reactant): use the `code-reader` agent. It runs on Haiku and is read-only. For hard questions (Reactant/MLIR internals, adjoint bugs), call it with `model: "sonnet"`.
- **Upstream releases, CI, issues and PRs:** use the `upstream-scout` agent, at the start of each phase and before any upgrade.
- **Judgment, planning and editing** stay with the main session.

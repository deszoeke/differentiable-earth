# plots/

All plotting for predictable-ocean. The root `CLAUDE.md` covers the project's rules; this file covers how plots are made.

## Environment
- `plots/Project.toml`: CairoMakie, FFTW, NCDatasets, Revise, IJulia, Statistics, and Pluto, PlutoUI, PlutoLinks. It has no model packages, so it loads fast and runs on the Mac or the HPC.
- **What runs where:** heavy computation belongs in non-interactive **driver scripts** (`drivers/`, run in `run/<name>/`, later on Slurm), which write NetCDF. Notebooks read NetCDF and plot. The toy model is cheap enough to compute inside a notebook; the coupled model is not.
- The Manifest is not committed. Run `Pkg.instantiate()` once on each machine.
- The Julia version is not pinned here. The juliaup override for the repo applies, so locally it runs 1.11.
- **Pluto (default for interactive work on the Mac).** From the repo, run `julia --project=plots -e 'using Pluto; Pluto.run(auto_reload_from_file = true)'`, then open `plots/<topic>_pluto.jl` from Pluto's start page.
- **Jupyter (kept for the HPC Jupyter service).** Kernel "Julia": the juliaup launcher with `--project=@.`, which finds `plots/Project.toml`.

## Files
- **`readers.jl`:** readers that return plain arrays with coordinates and attributes, e.g. `read_toy_run(path)`. Also small array helpers (`block_mean`, `autocorrelation`, `efolding_lag`). No plotting library is loaded here.
- **`plotlib.jl`:** user-configurable plotting functions. Each one:
  - takes plain arrays, so units and anomalies are computed visibly in the notebook;
  - has keyword defaults (`title`, `labels`, `colorrange`, `size`, ...);
  - returns its handles, `(; fig, ax, hm, cb, lines, ...)`, so later cells can restyle (`r.ax.title = ...`, `r.hm.colorrange = (lo, hi)`, `xlims!(r.ax, ...)`);
  - has a docstring with its signature, kept current.
- **Pluto notebooks: `<topic>_pluto.jl`.** These are plain `.jl` files and the primary notebooks.
  - Libraries are loaded with `RD = @ingredients("readers.jl")` and `PL = @ingredients("plotlib.jl")`, so edits to them re-run the dependent cells.
  - The first cell runs `Pkg.activate(@__DIR__)`, which turns off Pluto's own package manager.
  - Outputs are not stored, so no stripping is needed.
- **Jupyter notebooks: `<topic>.ipynb`, paired by Jupytext with `<topic>.jl` in percent format.** For the HPC Jupyter service; outputs are stripped on commit by nbstripout. The percent `.jl` can also be run cell by cell in VS Code (`# %%`).
- **Notebooks so far:** `toy_nature_run` (Pluto and Jupyter): the toy nature run's ENSO period, amplitude, irregularity and time scales.

## Adding a plotting function
1. Put it in `plotlib.jl`, in the right section: helpers or figures.
2. Use plain-array arguments and keyword defaults. Choose behaviour by dispatch on argument types, never by branching on keyword values. For one series versus many, add a method rather than an `if`.
3. Return a NamedTuple of handles.
4. Write a docstring with the signature, listing the keywords and what is returned.
5. Keep analysis that matters, such as anomalies, filters and statistics, in the notebook or in `readers.jl` helpers, where it is visible and rerunnable, not hidden in a plot function.

## Editing notebooks
- **Never write an `.ipynb`.** VS Code keeps open notebooks in memory, and a rewritten file on disk goes stale there. Edit the percent `.jl` instead. The user regenerates the `.ipynb` when needed with `jupytext --to ipynb --update plots/<topic>.jl`. Never Read or grep `.ipynb` JSON.
- **Pluto files can be edited by both of us.** Pluto reloads external edits (`auto_reload_from_file`) and re-runs only the changed cells and their dependents. The rules:
  - Re-read the file right before editing.
  - Tell the user which cells you are changing; the last write to a cell wins.
  - Keep the format valid: each cell starts with `# ╔═╡ <uuid>`, and every cell appears in the `# ╔═╡ Cell order:` list at the end (`╠═` shows the code, `╟─` hides it, for markdown).
  - New cells need fresh UUIDs.
  - Each variable is defined in exactly one cell; use `begin ... end` for several statements and `let` for local scratch.
  - Qualify names that clash between Makie and PlutoUI, e.g. `PlutoUI.Slider`.
  - **Put each `@bind` widget in its own plain cell, not inside `md"..."`.** Pluto's markdown parser cuts `$(...)` interpolations at `;` and at `_` (e.g. `show_value`). Similarly, build tables with `Markdown.parse(...)` in a `let` block, not with nested strings in `md`.
- **Check:** after editing a Pluto notebook, run it headlessly and confirm no cells error (`Pluto.SessionActions.open(Pluto.ServerSession(), path; run_async = false)`, then check `cell.errored`).

## Working rules
- The user runs the notebooks and looks at the plots. Don't re-run them to verify unless asked.
- Numbers quoted in replies or in `notes/STATUS.md` come from a notebook cell or a function. If a number was read off a plot, say so.
- Display settings that depend on the platform (dpi, `CairoMakie.activate!(type = "svg")`) go in each notebook's first cell.

# plots/

All plotting for differentiable-earth. The root `CLAUDE.md` covers the project's rules; this file covers how plots are made.

## Environment
- `plots/Project.toml`: CairoMakie, FFTW, NCDatasets, Revise, IJulia, Statistics. It has no model packages, so it loads fast and runs on the Mac or the HPC Jupyter service.
- The Manifest is not committed. Run `Pkg.instantiate()` once on each machine.
- The Julia version is not pinned here. The juliaup override for the repo applies, so locally it runs 1.11.
- Kernel: "Julia" (the juliaup launcher with `--project=@.`, which finds `plots/Project.toml`).

## Files
- **`readers.jl`:** readers that return plain arrays with coordinates and attributes, e.g. `read_toy_run(path)`. Also small array helpers (`block_mean`, `autocorrelation`, `efolding_lag`). No plotting library is loaded here.
- **`plotlib.jl`:** user-configurable plotting functions. Each one:
  - takes plain arrays, so units and anomalies are computed visibly in the notebook;
  - has keyword defaults (`title`, `labels`, `colorrange`, `size`, ...);
  - returns its handles, `(; fig, ax, hm, cb, lines, ...)`, so later cells can restyle (`r.ax.title = ...`, `r.hm.colorrange = (lo, hi)`, `xlims!(r.ax, ...)`);
  - has a docstring with its signature, kept current.
- **Notebooks:** `<topic>.ipynb`, each paired by Jupytext with `<topic>.jl` in percent format. Commit the `.jl` file and edit it, not the JSON. After editing the `.jl`, run `jupytext --sync plots/<topic>.jl`; never Read or grep `.ipynb` JSON.
  - `toy_nature_run`: the toy nature run, checking its ENSO period and amplitude and its time scales.

## Adding a plotting function
1. Put it in `plotlib.jl`, in the right section: helpers or figures.
2. Use plain-array arguments and keyword defaults. Choose behaviour by dispatch on argument types, never by branching on keyword values. For one series versus many, add a method rather than an `if`.
3. Return a NamedTuple of handles.
4. Write a docstring with the signature, listing the keywords and what is returned.
5. Keep analysis that matters, such as anomalies, filters and statistics, in the notebook or in `readers.jl` helpers, where it is visible and rerunnable, not hidden in a plot function.

## Working rules
- The user runs the notebooks and looks at the plots. Don't re-run them to verify unless asked.
- Numbers quoted in replies or in `notes/STATUS.md` come from a notebook cell or a function. If a number was read off a plot, say so.
- Display settings that depend on the platform (dpi, `CairoMakie.activate!(type = "svg")`) go in each notebook's first cell.

---
name: netcdf-output
description: NetCDF file conventions for predictable-ocean (file naming, CF metadata, provenance attributes, stored regridding weights, results files). Use when writing or reading any project output file, or adding a new output type.
---

# NetCDF output conventions

All output is NetCDF, written through `PredictableOcean/src/io.jl` (NCDatasets). JLD2 is not used. `plots/readers.jl` reads these conventions.

## Files
- **Location:** run output goes in `run/<name>/`; shared assets (regridding weights, phenomenon patterns) go in `assets/`. Neither is committed.
- **Names:** `<kind>_<config>_<period-or-tag>.nc`, e.g. `nature_T31L8-o2eq05_y0001-0050.nc`, `gradient_enso_T09_start05.nc`, `targeting_enso_T09_start05.nc`, `regrid_T31-to-o2eq05.nc`.

## Required global attributes (provenance)
Written automatically by `io.jl` (`write_provenance!`):
- `git_commit`, `git_dirty` (true or false), `git_branch`;
- `settings`, the driver's `##### Settings` block as text;
- `driver`, the path of the driver copy that produced the file;
- `julia_version` and `packages`: name=version for Reactant, Enzyme, Oceananigans, SpeedyWeather, NumericalEarth, ConservativeRegridding and PredictableOcean;
- `host`, `arch` and `created` (ISO date);
- `Conventions = "CF-1.10"`, `title`, `history`.

## Variables
- CF attributes on every variable: `units`, `long_name`, and `standard_name` where one exists.
- Coordinates: `lon`, `lat`, `z` or `pressure`, `time`, with CF time units.
- Extra dimensions: `member`, `lead`, `start_month`, `mode`, `obs`.
- For gradients and sensitivities, the units are those of J per unit of the state variable. Record the norm or metric used (`metric = "total_energy"`).
- Name variables in ASCII (`sst`, `u`, `T`, `q`, `lnps`, `vor`, `div`).

## Stored regridding weights (`regrid_<src>-to-<dst>.nc`)
- COO sparse matrix: `row`, `col` (1-based Int32) and `weight` (Float64), plus `n_src`, `n_dst`, and `src_area` and `dst_area` vectors.
- Attributes:
  - `src_grid_hash` and `dst_grid_hash`, which are checked on load;
  - `method = "conservative"` and the `ConservativeRegridding` version.
- Conservation checks before saving: `sum(W * src_area)` matches, and row sums against areas. The weights are recomputed only if the hashes differ.

## Reading
Readers return plain arrays together with their coordinates and attributes; they never hide computations. Use `NCDataset(path)` with a `do` block and close files promptly. Processes are fine; threads writing NetCDF are not, since NetCDF-C/HDF5 isn't thread-safe.

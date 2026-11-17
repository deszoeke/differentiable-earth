#####
##### Precomputed conservative regridding weights (docs/plan.md phase 4, netcdf-output skill)
#####
# ConservativeRegridding stores a regridder as the sparse matrix of intersection areas
# I[i, j] = area(dst cell i ∩ src cell j), with dst and src cell areas. Regridding a field f is
# f_dst = (I f_src) ./ dst_areas. Because I for src→dst is the transpose of I for dst→src, the
# adjoint of conservative regridding (in area-weighted inner products) is the reverse regridding.
# Stored once, these become constant linear operators for a Reactant-compiled coupled step.

"""
    RegriddingWeights(intersections, dst_areas, src_areas, src_grid, dst_grid)

Conservative regridding operator from grid `src_grid` to grid `dst_grid` (descriptive strings,
used to check that stored weights match the model): sparse `intersections` (dst × src cell
intersection areas) and the cell areas. Apply with [`regrid`](@ref).
"""
struct RegriddingWeights{T}
    intersections::SparseMatrixCSC{T, Int}
    dst_areas::Vector{T}
    src_areas::Vector{T}
    src_grid::String
    dst_grid::String
end

"""
    regrid(w::RegriddingWeights, f)

Conservatively regrid the source-grid values `f` (vector over source cells) to the destination
grid: (intersections * f) ./ dst_areas. A plain sparse matrix–vector product (differentiable).
"""
regrid(w::RegriddingWeights, f::AbstractVector) = (w.intersections * f) ./ w.dst_areas

"""
    regridding_checks(forward, reverse)

Consistency checks for a pair of regridders between the same two grids:
- `transpose`: ‖I_fwd − I_revᵀ‖ / ‖I_fwd‖ (intersection areas are symmetric, so the adjoint of
  one direction is the other);
- `dst_coverage`, `src_coverage`: extrema of the fraction of each cell's area covered by the
  other grid (1 for fully overlapped cells; < 1 where the grids do not overlap, e.g. poleward of
  the ocean grid's latitude limits);
- `constant`: extrema of `regrid(forward, ones)` on fully covered destination cells (should be 1).
"""
function regridding_checks(fwd::RegriddingWeights, rev::RegriddingWeights)
    I = fwd.intersections
    transpose_err = norm(I - sparse(rev.intersections')) / norm(I)
    dst_cov = vec(sum(I; dims = 2)) ./ fwd.dst_areas
    src_cov = vec(sum(I; dims = 1)) ./ fwd.src_areas
    full = dst_cov .> 1 - 1e-8
    c = regrid(fwd, ones(length(fwd.src_areas)))[full]
    return (; transpose = transpose_err, dst_coverage = extrema(dst_cov), src_coverage = extrema(src_cov),
            constant = isempty(c) ? (NaN, NaN) : extrema(c), n_full_dst = count(full))
end

"""
    save_regridding_weights(path, w::RegriddingWeights; attributes = Dict())

Write `w` to NetCDF in COO form (`row`, `col`, `intersection`, plus `dst_area`, `src_area`) with
the grid descriptions as attributes (see the netcdf-output skill).
"""
function save_regridding_weights(path::AbstractString, w::RegriddingWeights; attributes = Dict{String, Any}())
    rows, cols, vals = findnz(w.intersections)
    NCDataset(path, "c") do ds
        for (k, v) in attributes
            ds.attrib[k] = v
        end
        ds.attrib["src_grid"] = w.src_grid
        ds.attrib["dst_grid"] = w.dst_grid
        ds.attrib["method"] = "conservative (ConservativeRegridding.jl intersection areas)"
        ds.attrib["apply"] = "f_dst = (sparse(row, col, intersection, n_dst, n_src) * f_src) ./ dst_area"
        defDim(ds, "n_dst", length(w.dst_areas))
        defDim(ds, "n_src", length(w.src_areas))
        defVar(ds, "row", Int32.(rows), ("nnz",))
        defVar(ds, "col", Int32.(cols), ("nnz",))
        defVar(ds, "intersection", vals, ("nnz",); attrib = Dict("units" => "m2"))
        defVar(ds, "dst_area", w.dst_areas, ("n_dst",); attrib = Dict("units" => "m2"))
        defVar(ds, "src_area", w.src_areas, ("n_src",); attrib = Dict("units" => "m2"))
    end
    return path
end

"""
    load_regridding_weights(path)

Read [`RegriddingWeights`](@ref) written by [`save_regridding_weights`](@ref).
"""
function load_regridding_weights(path::AbstractString)
    NCDataset(path) do ds
        nd, ns = ds.dim["n_dst"], ds.dim["n_src"]
        I = sparse(Int.(ds["row"][:]), Int.(ds["col"][:]), Float64.(ds["intersection"][:]), nd, ns)
        RegriddingWeights(I, Float64.(ds["dst_area"][:]), Float64.(ds["src_area"][:]),
                          String(ds.attrib["src_grid"]), String(ds.attrib["dst_grid"]))
    end
end

# Implemented in the DifferentiableEarthCoupledExt extension (load NumericalEarth, SpeedyWeather,
# Oceananigans and ConservativeRegridding to activate it).

"""
    build_coupled_model(; ocean_size, ocean_latitude, ocean_depth, truncation, nlayers, stop_time)

Build the coarse CPU coupled model (SpeedyWeather PrimitiveWetModel + Oceananigans through
NumericalEarth's `EarthSystemModel`) with an idealized ocean, as in `drivers/coupled_smoke.jl`.
Returns `(; earth_model, ocean, atmosphere, grid, spectral_grid, Δt)`. Requires the extension.
"""
function build_coupled_model end

"""
    regridding_weights(earth_model)

Extract the atmosphere↔exchange-grid conservative regridders of a coupled model as
`(; from_atmosphere, to_atmosphere)` [`RegriddingWeights`](@ref). Requires the extension.
"""
function regridding_weights end

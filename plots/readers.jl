# Readers for differentiable-earth NetCDF output, plus small array helpers. Readers return plain
# arrays with their coordinates and attributes; computations stay visible in the notebook.
# No plotting library here (plotlib.jl does the plotting).

using NCDatasets, Statistics

"""
    read_toy_run(path)

Read a ToyCoupled trajectory file (e.g. `run/toy-nature/toy_nature_run.nc`). Returns a
NamedTuple: `t` (days), `years` (t / 365), `sector`, `X` and `T` (sector × time), `Te`, `h`
(time series), and `attrs` (global attributes as a Dict, including `param_*` and provenance).
"""
function read_toy_run(path::AbstractString)
    NCDataset(path) do ds
        t = Float64.(ds["time"].var[:])       # raw numbers (days since start), not DateTimes
        (; t, years = t ./ 365, sector = Int.(ds["sector"][:]),
         X = Array(ds["atmosphere"][:, :]), T = Array(ds["ocean"][:, :]),
         Te = Array(ds["Te"][:]), h = Array(ds["h"][:]),
         attrs = Dict(k => ds.attrib[k] for k in keys(ds.attrib)))
    end
end

"""
    block_mean(x, n)

Means of consecutive blocks of `n` samples of a vector (a trailing partial block is dropped),
e.g. `block_mean(Te, 30)` for 30-day means of a daily series.
"""
block_mean(x::AbstractVector, n::Integer) = [mean(@view x[(i - 1) * n + 1:i * n]) for i in 1:(length(x) ÷ n)]

"""
    autocorrelation(x, lags)

Sample autocorrelation of vector `x` at integer `lags` (in samples).
"""
function autocorrelation(x::AbstractVector, lags)
    xa = x .- mean(x)
    v = sum(abs2, xa)
    return [sum(@view(xa[1:end - l]) .* @view(xa[1 + l:end])) / v for l in lags]
end

"""
    efolding_lag(r, lags)

First lag at which the autocorrelation `r` (at `lags`) drops below 1/e; `nothing` if it never does.
"""
function efolding_lag(r::AbstractVector, lags)
    i = findfirst(<(exp(-1)), r)
    return i === nothing ? nothing : lags[i]
end

# Readers for predictable-ocean NetCDF output, plus small array helpers. Readers return plain
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

"""
    cycle_stats(x, dt; smooth = 5)

Oscillation statistics of series `x` sampled every `dt`: after a `smooth`-sample centered running
mean, cycles are intervals between upward crossings of the mean. Returns
`(; lengths, mean, std, cv)`, `cv = std/mean` (irregularity). Same as
`PredictableOcean.cycle_stats` (copied so plots/ needs no model packages).
"""
function cycle_stats(x::AbstractVector, dt::Real; smooth::Integer = 5)
    h = smooth ÷ 2
    N = length(x)
    xa = x .- mean(x)
    y = [mean(@view xa[max(1, i - h):min(N, i + h)]) for i in 1:N]
    up = [i for i in 1:(N - 1) if y[i] < 0 && y[i + 1] >= 0]
    tc = [(i - 1 + y[i] / (y[i] - y[i + 1])) * dt for i in up]
    L = diff(tc)
    return (; lengths = L, mean = mean(L), std = std(L), cv = std(L) / mean(L))
end

"""
    read_tutorial_ad(path)

Read `run/tutorial-ad/tutorial_ad.nc` (drivers/tutorial_ad.jl). Returns a NamedTuple with
`lead_days`, `amplitude`, `metric` (names), `sigma_clim` (state), `grad` (state × start × lead ×
metric), `tlm_relerr` (amplitude × lead × metric), the checks `dot_test`, `fd_relerr`,
`reactant_relerr` and timings `t_enzyme`, `t_reactant_compile`, `t_reactant_run` (by lead), and
`attrs`.
"""
function read_tutorial_ad(path::AbstractString)
    NCDataset(path) do ds
        g(k) = Array(ds[k][:])
        (; lead_days = g("lead_days"), amplitude = g("amplitude"), metric = String.(ds["metric"][:]),
         sigma_clim = g("sigma_clim"), grad = Array(ds["grad"][:, :, :, :]),
         tlm_relerr = Array(ds["tlm_relerr"][:, :, :]), dot_test = g("dot_test"), fd_relerr = g("fd_relerr"),
         reactant_relerr = g("reactant_relerr"), t_enzyme = g("t_enzyme"),
         t_reactant_compile = g("t_reactant_compile"), t_reactant_run = g("t_reactant_run"),
         attrs = Dict(k => ds.attrib[k] for k in keys(ds.attrib)))
    end
end

"""
    read_sensitivity_comparison(path)

Read `run/toy-sensitivity/toy_sensitivity_comparison.nc` (drivers/toy_sensitivity_comparison.jl).
Sensitivities are `slow × lead × metric × start` (`lim`: `slow × lead × metric`); scores `corr`
and `relerr` are `estimator × lead × metric`.
"""
function read_sensitivity_comparison(path::AbstractString)
    NCDataset(path) do ds
        g(k) = Array(ds[k][:])
        a4(k) = Array(ds[k][:, :, :, :])
        (; lead_days = g("lead_days"), slow = g("slow"), metric = String.(ds["metric"][:]),
         estimator = String.(ds["estimator"][:]), s_clim = g("s_clim"),
         truth = a4("truth"), truth_se = a4("truth_se"), single_adjoint = a4("single_adjoint"),
         ensemble_mean_adjoint = a4("ensemble_mean_adjoint"), ensemble_mean_adjoint_se = a4("ensemble_mean_adjoint_se"),
         regression = a4("regression"), lim = Array(ds["lim"][:, :, :]),
         corr = Array(ds["corr"][:, :, :]), relerr = Array(ds["relerr"][:, :, :]),
         attrs = Dict(k => ds.attrib[k] for k in keys(ds.attrib)))
    end
end

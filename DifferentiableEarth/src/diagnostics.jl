#####
##### Time-series diagnostics (shared by drivers; plots/readers.jl has a copy of cycle_stats)
#####

"""
    running_mean(x, n)

Centered running mean of odd window `n` (ends shortened to the available samples).
"""
function running_mean(x::AbstractVector, n::Integer)
    isodd(n) || throw(ArgumentError("window must be odd"))
    h = n ÷ 2
    N = length(x)
    return [sum(@view x[max(1, i - h):min(N, i + h)]) / (min(N, i + h) - max(1, i - h) + 1) for i in 1:N]
end

"""
    cycle_stats(x, dt; smooth = 5)

Statistics of the oscillation in series `x` sampled every `dt` (e.g. monthly means of Tₑ with
`dt` in years): after a `smooth`-sample running mean, cycles are the intervals between upward
crossings of the mean. Returns `(; lengths, mean, std, cv)` with `cv = std/mean`, the
irregularity measure used to tune the toy ENSO.
"""
function cycle_stats(x::AbstractVector, dt::Real; smooth::Integer = 5)
    y = running_mean(x .- sum(x) / length(x), smooth)
    up = [i for i in 1:(length(y) - 1) if y[i] < 0 && y[i + 1] >= 0]
    # interpolate crossing times
    tc = [(i - 1 + y[i] / (y[i] - y[i + 1])) * dt for i in up]
    L = diff(tc)
    μ = sum(L) / length(L)
    σ = sqrt(sum(abs2, L .- μ) / (length(L) - 1))
    return (; lengths = L, mean = μ, std = σ, cv = σ / μ)
end

"""
    monthly_means(x, steps_per_month)

Means of consecutive blocks of `steps_per_month` samples.
"""
monthly_means(x::AbstractVector, n::Integer) = [sum(@view x[(i - 1) * n + 1:i * n]) / n for i in 1:(length(x) ÷ n)]

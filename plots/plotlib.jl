# User-configurable plotting functions for predictable-ocean (CairoMakie). Each function takes
# plain arrays, has keyword defaults, and returns its handles (fig, ax, plot objects, colorbar) so a
# notebook cell can restyle the figure afterwards (ax.title = ..., hm.colorrange = ..., xlims!(ax, ...)).
# Conventions: plots/CLAUDE.md. Data readers: readers.jl.

using CairoMakie, FFTW, Statistics

set_theme!(fontsize = 16)

#####
##### Helpers
#####

"Symmetric color range (-m, m) with m the largest finite |A|."
symmetric_range(A) = (m = maximum(abs, filter(isfinite, A)); (-m, m))

"""
    periodogram(x, dt)

Periodogram of the vector `x` sampled every `dt` (mean removed, Hann window). Returns
`(; period, power)` for frequencies above zero, with `period` in the units of `dt`.
"""
function periodogram(x::AbstractVector, dt::Real)
    n = length(x)
    w = 0.5 .- 0.5 .* cos.(2π .* (0:(n - 1)) ./ (n - 1))
    X = rfft(w .* (x .- mean(x)))
    f = (1:(length(X) - 1)) ./ (n * dt)
    return (; period = 1 ./ f, power = abs2.(X[2:end]) ./ n)
end

#####
##### Figures
#####

"""
    plot_series(t, ys; labels, xlabel = "time", ylabel = "", title = "", size = (900, 350))

Line plot of the vectors in `ys` (a vector of vectors, or one vector) against `t`.
Returns `(; fig, ax, lines)`.
"""
function plot_series(t, ys::AbstractVector{<:AbstractVector}; labels = fill("", length(ys)),
                     xlabel = "time", ylabel = "", title = "", size = (900, 350))
    fig = Figure(; size)
    ax = Axis(fig[1, 1]; xlabel, ylabel, title)
    lines = [lines!(ax, t, y; label) for (y, label) in zip(ys, labels)]
    any(!isempty, labels) && axislegend(ax; position = :rt)
    return (; fig, ax, lines)
end
plot_series(t, y::AbstractVector{<:Real}; kw...) = plot_series(t, [y]; kw...)

"""
    plot_hovmoller(t, k, A; colormap = :balance, colorrange = symmetric_range(A),
                   xlabel = "time", ylabel = "sector", title = "", units = "", size = (900, 350))

Hovmöller diagram of `A` (k × t). Returns `(; fig, ax, hm, cb)`.
"""
function plot_hovmoller(t, k, A::AbstractMatrix; colormap = :balance, colorrange = symmetric_range(A),
                        xlabel = "time", ylabel = "sector", title = "", units = "", size = (900, 350))
    fig = Figure(; size)
    ax = Axis(fig[1, 1]; xlabel, ylabel, title)
    hm = heatmap!(ax, t, k, permutedims(A); colormap, colorrange, rasterize = true)
    cb = Colorbar(fig[1, 2], hm; label = units)
    return (; fig, ax, hm, cb)
end

"""
    plot_spectra(series, dt; labels, units = "years", title = "", size = (700, 450))

Periodograms of the vectors in `series` (sampled every `dt`, in `units`) on log–log axes
against period. Returns `(; fig, ax, lines)`.
"""
function plot_spectra(series::AbstractVector{<:AbstractVector}, dt::Real; labels = fill("", length(series)),
                      units = "years", title = "", size = (700, 450))
    fig = Figure(; size)
    ax = Axis(fig[1, 1]; xscale = log10, yscale = log10, xlabel = "period ($units)", ylabel = "power", title,
              xreversed = true)
    lines = map(zip(series, labels)) do (x, label)
        p = periodogram(x, dt)
        lines!(ax, p.period, p.power; label)
    end
    any(!isempty, labels) && axislegend(ax; position = :lb)
    return (; fig, ax, lines)
end

"""
    plot_autocorrelation(lags, rs; labels, xlabel = "lag", title = "", size = (700, 400))

Autocorrelation curves `rs` (vector of vectors) against `lags`, with the 1/e line.
Returns `(; fig, ax, lines)`.
"""
function plot_autocorrelation(lags, rs::AbstractVector{<:AbstractVector}; labels = fill("", length(rs)),
                              xlabel = "lag", title = "", size = (700, 400))
    fig = Figure(; size)
    ax = Axis(fig[1, 1]; xlabel, ylabel = "autocorrelation", title)
    hlines!(ax, [exp(-1), 0]; color = :gray, linestyle = :dash)
    lines = [lines!(ax, lags, r; label) for (r, label) in zip(rs, labels)]
    any(!isempty, labels) && axislegend(ax; position = :rt)
    return (; fig, ax, lines)
end

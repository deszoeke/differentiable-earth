# -*- coding: utf-8 -*-
# ---
# jupyter:
#   jupytext:
#     formats: ipynb,jl:percent
#     text_representation:
#       extension: .jl
#       format_name: percent
#       format_version: '1.3'
#       jupytext_version: 1.19.6
#   kernelspec:
#     display_name: Julia
#     language: julia
#     name: julia
# ---

# %% [markdown]
# # Toy nature run
# ToyCoupled = Lorenz-96 atmosphere + slab ocean + recharge-oscillator ENSO, from
# `drivers/toy_nature_run.jl` (run in `run/toy-nature/`). 1 model time unit ≈ 5 days; saved daily.
# Questions: is the ENSO-like oscillation there, with a period of a few years and a sensible
# amplitude? Are the three time scales (weather, ocean memory, ENSO) separated?

# %%
using Pkg; Pkg.activate(@__DIR__)
using Revise
includet(joinpath(@__DIR__, "readers.jl"))
includet(joinpath(@__DIR__, "plotlib.jl"))
CairoMakie.activate!(type = "png", px_per_unit = 2)
rundir = joinpath(@__DIR__, "..", "run", "toy-nature")
r = read_toy_run(joinpath(rundir, "toy_nature_run.nc"))
println(r.attrs["title"], ", ", r.attrs["git_commit"][1:8], r.attrs["git_dirty"] == "true" ? " (dirty)" : "")
println(length(r.t), " days; params: ", join(["$k=$(r.attrs[k])" for k in sort(collect(keys(r.attrs))) if startswith(k, "param_")], ", "))

# %% [markdown]
# ## ENSO: Tₑ and h

# %%
f_enso = plot_series(r.years, [r.Te, r.h]; labels = ["Tₑ", "h"], xlabel = "year", title = "recharge oscillator")
f_enso.fig

# %%
println("std Tₑ = ", round(std(r.Te), sigdigits = 3), ",  std h = ", round(std(r.h), sigdigits = 3),
        ",  skewness Tₑ = ", round(mean((r.Te .- mean(r.Te)) .^ 3) / std(r.Te)^3, sigdigits = 3))

# %% [markdown]
# ## Spectra (30-day means): ENSO period

# %%
Te_m = block_mean(r.Te, 30)
T1_m = block_mean(r.T[1, :], 30)
X1_m = block_mean(r.X[1, :], 30)
dt_yr = 30 / 365
f_spec = plot_spectra([Te_m, T1_m, X1_m], dt_yr; labels = ["Tₑ", "T₁ (slab ocean)", "X₁ (atmosphere)"],
                      title = "periodograms of 30-day means")
f_spec.fig

# %%
p = periodogram(Te_m, dt_yr)
println("peak Tₑ period ≈ ", round(p.period[argmax(p.power)], sigdigits = 3), " years")

# %% [markdown]
# ## ENSO irregularity: cycle lengths
# Cycles = intervals between upward zero crossings of 5-month-smoothed monthly Tₑ.
# Irregularity = CV of cycle lengths (tuned to ≈ 0.3 with `drivers/toy_enso_sweep.jl`; observed ENSO ≈ 0.3–0.4).

# %%
c = cycle_stats(Te_m, dt_yr)
println("cycles: ", length(c.lengths), ",  mean ", round(c.mean, digits = 2), " ± ", round(c.std, digits = 2),
        " yr,  CV = ", round(c.cv, digits = 3))
f_cyc = Figure(size = (600, 350)); ax_cyc = Axis(f_cyc[1, 1]; xlabel = "cycle length (years)", ylabel = "count")
hist!(ax_cyc, c.lengths; bins = 0:0.5:8)
f_cyc

# %% [markdown]
# ## Time scales: autocorrelation (daily data)

# %%
lags = 0:3*365
rs = [autocorrelation(r.X[1, :], lags), autocorrelation(r.T[1, :], lags), autocorrelation(r.Te, lags)]
f_ac = plot_autocorrelation(lags, rs; labels = ["X₁", "T₁", "Tₑ"], xlabel = "lag (days)")
f_ac.fig

# %%
for (name, ρ) in zip(["X₁", "T₁", "Tₑ"], rs)
    println(name, ": e-folding lag = ", efolding_lag(ρ, lags), " days")
end

# %% [markdown]
# ## Hovmöller diagrams

# %%
days = 1:180
f_hx = plot_hovmoller(r.t[days], r.sector, r.X[:, days]; colormap = :viridis, colorrange = extrema(r.X),
                      xlabel = "day", title = "atmosphere X (first 180 days)")
f_hx.fig

# %%
f_ht = plot_hovmoller(r.years, r.sector, r.T; xlabel = "year", title = "slab-ocean T", units = "K")
f_ht.fig

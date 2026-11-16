### A Pluto.jl notebook ###
# v1.1.0

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    #! format: off
    return quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
    #! format: on
end

# ╔═╡ d2ea80e8-779e-4230-88e4-9dcaf6dd9c10
begin
    import Pkg
    Pkg.activate(@__DIR__)      # plots/Project.toml (turns off Pluto's own package manager)
    using CairoMakie, PlutoUI, PlutoLinks, Statistics
end

# ╔═╡ 4ec1bf63-df48-4092-9d20-7c63ade7ea00
md"""
# Toy nature run (Pluto)
ToyCoupled = Lorenz-96 atmosphere + slab ocean + recharge-oscillator ENSO, from
`drivers/toy_nature_run.jl` (run in `run/toy-nature/`); 1 model time unit ≈ 5 days; saved daily.
Is the ENSO-like oscillation there, with a period of a few years, a sensible amplitude and
irregularity? Are the three time scales separated?

Start Pluto from the repository: `julia --project=plots -e 'using Pluto; Pluto.run(auto_reload_from_file = true)'`.
Libraries `readers.jl` and `plotlib.jl` are loaded with `@ingredients`, so edits to them re-run the cells that use them.
"""

# ╔═╡ ccf08dca-5cb9-4b5d-824a-b1664a996711
RD = @ingredients(joinpath(@__DIR__, "readers.jl"))

# ╔═╡ 26bbdc37-d2a3-473b-a936-2fa7a87cff65
PL = @ingredients(joinpath(@__DIR__, "plotlib.jl"))

# ╔═╡ 35a8c4ff-1fd6-4a7a-b479-5d0374de7e3a
r = RD.read_toy_run(joinpath(@__DIR__, "..", "run", "toy-nature", "toy_nature_run.nc"))

# ╔═╡ 455dd511-5fde-4ddd-b582-9c106d1354a9
let
    a = r.attrs
    params = join(["$(replace(k, "param_" => ""))=$(a[k])" for k in sort(collect(keys(a))) if startswith(k, "param_")], ", ")
    Markdown.parse("""
    **$(a["title"])**, commit `$(a["git_commit"][1:8])`$(a["git_dirty"] == "true" ? " (dirty)" : ""), $(length(r.t)) days.

    Parameters: $params
    """)
end

# ╔═╡ ea173469-684c-43ee-9914-69918f33395f
md"## ENSO: Tₑ and h"

# ╔═╡ 5047c2a1-65df-441f-8056-6c59a7367f92
begin
    f_enso = PL.plot_series(r.years, [r.Te, r.h]; labels = ["Tₑ", "h"], xlabel = "year", title = "recharge oscillator")
    f_enso.fig
end

# ╔═╡ aead67e4-01b3-479f-b182-ed0bc630f482
md"""
std Tₑ = $(round(std(r.Te), sigdigits = 3)), std h = $(round(std(r.h), sigdigits = 3)),
skewness Tₑ = $(round(mean((r.Te .- mean(r.Te)) .^ 3) / std(r.Te)^3, sigdigits = 3))
"""

# ╔═╡ 35228aab-6f1d-415b-a64e-7fcddeaabf9d
md"## Spectra (30-day means)"

# ╔═╡ ed0b8bfc-e4b3-4b47-81f2-9643795c84c8
begin
    Te_m = RD.block_mean(r.Te, 30)
    dt_yr = 30 / 365
    f_spec = PL.plot_spectra([Te_m, RD.block_mean(r.T[1, :], 30), RD.block_mean(r.X[1, :], 30)], dt_yr;
                             labels = ["Tₑ", "T₁ (slab ocean)", "X₁ (atmosphere)"], title = "periodograms of 30-day means")
    f_spec.fig
end

# ╔═╡ ffda982d-7e47-4131-b250-e727772e7486
let
    p = PL.periodogram(Te_m, dt_yr)
    md"Peak Tₑ period ≈ $(round(p.period[argmax(p.power)], sigdigits = 3)) years"
end

# ╔═╡ e0084546-5ef4-488b-864f-f1b7c997c219
md"""
## ENSO irregularity: cycle lengths
Cycles = intervals between upward zero crossings of 5-month-smoothed monthly Tₑ; irregularity = CV of
cycle lengths (tuned to ≈ 0.3 with `drivers/toy_enso_sweep.jl`; observed ENSO ≈ 0.3–0.4).
"""

# ╔═╡ 02542cb4-3fb4-443d-aaf9-546886f251ce
cyc = RD.cycle_stats(Te_m, dt_yr)

# ╔═╡ 9b9a69bf-36d8-4875-a85d-40000f811b19
begin
    f_cyc = Figure(size = (600, 350))
    ax_cyc = Axis(f_cyc[1, 1]; xlabel = "cycle length (years)", ylabel = "count",
                  title = "$(length(cyc.lengths)) cycles, $(round(cyc.mean, digits = 2)) ± $(round(cyc.std, digits = 2)) yr, CV = $(round(cyc.cv, digits = 3))")
    hist!(ax_cyc, cyc.lengths; bins = 0:0.5:8)
    f_cyc
end

# ╔═╡ 100ecc61-4f97-4fc4-8c04-a669e79a024a
md"## Time scales: autocorrelation (daily data)"

# ╔═╡ 1a6c2f04-3e55-4a8e-9b1c-7d2e5f6a8b01
begin
    lags = 0:3*365
    acs = [RD.autocorrelation(r.X[1, :], lags), RD.autocorrelation(r.T[1, :], lags), RD.autocorrelation(r.Te, lags)]
    f_ac = PL.plot_autocorrelation(lags, acs; labels = ["X₁", "T₁", "Tₑ"], xlabel = "lag (days)")
    f_ac.fig
end

# ╔═╡ 2b7d3e15-4f66-4b9f-8c2d-8e3f6a7b9c02
md"e-folding lags (days): X₁ = $(RD.efolding_lag(acs[1], lags)), T₁ = $(RD.efolding_lag(acs[2], lags)), Tₑ = $(RD.efolding_lag(acs[3], lags))"

# ╔═╡ 3c8e4f26-5a77-4cad-9d3e-9f4a7b8cad03
md"""
## Hovmöller diagrams
Start day of the 180-day atmosphere window: $(@bind start_day PlutoUI.Slider(1:30:(length(r.t) - 180); default = 1, show_value = true))
"""

# ╔═╡ 4d9f5a37-6b88-4dbe-8e4f-af5b8c9dbe04
begin
    days = start_day:(start_day + 179)
    f_hx = PL.plot_hovmoller(r.t[days], r.sector, r.X[:, days]; colormap = :viridis, colorrange = extrema(r.X),
                             xlabel = "day", title = "atmosphere X, days $(first(days))–$(last(days))")
    f_hx.fig
end

# ╔═╡ 5eaf6b48-7c99-4ecf-9f5a-bf6c9daecf05
begin
    f_ht = PL.plot_hovmoller(r.years, r.sector, r.T; xlabel = "year", title = "slab-ocean T", units = "K")
    f_ht.fig
end

# ╔═╡ Cell order:
# ╟─4ec1bf63-df48-4092-9d20-7c63ade7ea00
# ╠═d2ea80e8-779e-4230-88e4-9dcaf6dd9c10
# ╠═ccf08dca-5cb9-4b5d-824a-b1664a996711
# ╠═26bbdc37-d2a3-473b-a936-2fa7a87cff65
# ╠═35a8c4ff-1fd6-4a7a-b479-5d0374de7e3a
# ╟─455dd511-5fde-4ddd-b582-9c106d1354a9
# ╟─ea173469-684c-43ee-9914-69918f33395f
# ╠═5047c2a1-65df-441f-8056-6c59a7367f92
# ╟─aead67e4-01b3-479f-b182-ed0bc630f482
# ╟─35228aab-6f1d-415b-a64e-7fcddeaabf9d
# ╠═ed0b8bfc-e4b3-4b47-81f2-9643795c84c8
# ╟─ffda982d-7e47-4131-b250-e727772e7486
# ╟─e0084546-5ef4-488b-864f-f1b7c997c219
# ╠═02542cb4-3fb4-443d-aaf9-546886f251ce
# ╠═9b9a69bf-36d8-4875-a85d-40000f811b19
# ╟─100ecc61-4f97-4fc4-8c04-a669e79a024a
# ╠═1a6c2f04-3e55-4a8e-9b1c-7d2e5f6a8b01
# ╟─2b7d3e15-4f66-4b9f-8c2d-8e3f6a7b9c02
# ╟─3c8e4f26-5a77-4cad-9d3e-9f4a7b8cad03
# ╠═4d9f5a37-6b88-4dbe-8e4f-af5b8c9dbe04
# ╠═5eaf6b48-7c99-4ecf-9f5a-bf6c9daecf05

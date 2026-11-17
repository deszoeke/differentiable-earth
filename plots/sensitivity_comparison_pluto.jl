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

# ╔═╡ 61be9311-4771-4fc4-8017-5b5325672813
begin
    import Pkg
    Pkg.activate(@__DIR__)
    using CairoMakie, PlutoUI, PlutoLinks, Statistics
end

# ╔═╡ 64fc7a2f-dc6b-4363-8a52-ff4d66966cd9
md"""
# Sensitivities that survive chaos (toy)
From `drivers/toy_sensitivity_comparison.jl` (run in `run/toy-sensitivity/`); design in `docs/technical.md` §4.
Target: s = ∂E[J(T)]/∂x₀ over the 38 slow variables (ocean T₁…T₃₆, Tₑ, h), the sensitivity of the
**expected** forecast, with the expectation over analysis error. Truth: paired-ensemble finite differences.
Estimators: single-trajectory adjoint, ensemble-mean adjoint, ensemble regression, LIM.
Sensitivities are shown × s_clim (climatological std): the change in E[J] for a one-s_clim change of each initial variable.
"""

# ╔═╡ d7ffa21d-8358-4724-a590-61abff052fe8
RD = @ingredients(joinpath(@__DIR__, "readers.jl"))

# ╔═╡ 720ba676-d5fb-4d64-8aaf-1492fd672e8e
d = RD.read_sensitivity_comparison(joinpath(@__DIR__, "..", "run", "toy-sensitivity", "toy_sensitivity_comparison.nc"))

# ╔═╡ dc5deefd-df2d-4c93-944e-bac714643b98
md"## Scores against the truth (pooled over initial states)"

# ╔═╡ 80b07e0f-a17f-402e-bbdf-a6b6ad44aaf6
begin
    f_score = Figure(size = (1000, 650))
    for (im, mname) in enumerate(d.metric)
        axc = Axis(f_score[1, im]; xscale = log10, xlabel = "lead (days)", ylabel = im == 1 ? "pattern correlation" : "",
                   title = "J = $mname", limits = (nothing, (-0.5, 1.05)))
        axe = Axis(f_score[2, im]; xscale = log10, yscale = log10, xlabel = "lead (days)",
                   ylabel = im == 1 ? "rms error / rms truth" : "")
        hlines!(axe, [1.0]; color = :gray, linestyle = :dash)
        for (ie, ename) in enumerate(d.estimator)
            scatterlines!(axc, d.lead_days, d.corr[ie, :, im]; label = ename)
            scatterlines!(axe, d.lead_days, d.relerr[ie, :, im])
        end
        im == 2 && axislegend(axc; position = :lb)
    end
    f_score
end

# ╔═╡ 0ccca321-c2c3-4104-bca6-0b7163ec667c
let
    r(x) = round(x, sigdigits = 2)
    snr = [sqrt(mean(abs2, d.truth[:, il, im, :])) / sqrt(mean(abs2, d.truth_se[:, il, im, :]))
           for il in eachindex(d.lead_days), im in eachindex(d.metric)]
    rows = ["| $(round(Int, d.lead_days[il])) | " * join(r.(snr[il, :]), " | ") * " |" for il in eachindex(d.lead_days)]
    Markdown.parse("""
    **How reliable is the truth?** rms(truth) / rms(standard error) over slow variables and initial states.
    Near 1 means the "truth" is mostly sampling noise, so low scores at that lead say little about the estimators.

    | lead (days) | """ * join(d.metric, " | ") * """ |
    |---|""" * repeat("---|", length(d.metric)) * "\n" * join(rows, "\n"))
end

# ╔═╡ 2c49eef6-0b21-4596-89c1-e295427ce0cf
md"## Sensitivity patterns: metric, lead, initial state, show single-trajectory adjoint"

# ╔═╡ af4eeb6a-6c1e-45bc-b3db-da6d511ba220
@bind mi PlutoUI.Select([1 => "Tₑ", 2 => "T₁ (slab ocean, sector 1)"])

# ╔═╡ d80eb133-5989-4a3f-afba-2ac8eae62fdf
@bind li PlutoUI.Select([i => "$(round(Int, L)) days" for (i, L) in enumerate(d.lead_days)]; default = 3)

# ╔═╡ 6d0e919d-64e2-469f-8760-d0f8101c08e9
@bind si PlutoUI.Slider(1:size(d.truth, 4); default = 1, show_value = true)

# ╔═╡ 026ec9e6-c67c-4bfb-83e0-5d56946b6cd9
@bind show_single PlutoUI.CheckBox(default = false)

# ╔═╡ 8730660d-75ad-46ce-80fa-9f2df7584829
begin
    sc = d.s_clim
    tr = d.truth[:, li, mi, si] .* sc
    se = d.truth_se[:, li, mi, si] .* sc
    xs = 1:length(tr)
    f_pat = Figure(size = (1000, 420))
    ax = Axis(f_pat[1, 1]; xlabel = "slow variable (1–36: ocean sector, 37: Tₑ, 38: h)", ylabel = "Δ E[J] per s_clim",
              title = "J = $(d.metric[mi]), lead $(round(Int, d.lead_days[li])) days, initial state $si")
    band!(ax, xs, tr .- 2se, tr .+ 2se; color = (:gray, 0.3))
    lines!(ax, xs, tr; color = :black, linewidth = 3, label = "truth ± 2 s.e.")
    lines!(ax, xs, d.ensemble_mean_adjoint[:, li, mi, si] .* sc; label = "ensemble-mean adjoint")
    lines!(ax, xs, d.regression[:, li, mi, si] .* sc; label = "regression")
    lines!(ax, xs, d.lim[:, li, mi] .* sc; label = "LIM")
    show_single && lines!(ax, xs, d.single_adjoint[:, li, mi, si] .* sc; label = "single adjoint", linestyle = :dot)
    lo, hi = extrema(vcat(tr .- 3se, tr .+ 3se))
    ylims!(ax, lo - 0.5abs(hi - lo), hi + 0.5abs(hi - lo))   # zoom on the truth; exploding estimators go off-scale
    axislegend(ax; position = :lt)
    f_pat
end

# ╔═╡ 0fb46039-abcf-4c54-8313-79d7010bb114
let
    r(x) = round(x, sigdigits = 2)
    rows = ["| $(d.estimator[ie]) | " * join([r(d.corr[ie, il, mi]) for il in eachindex(d.lead_days)], " | ") * " |" for ie in eachindex(d.estimator)]
    Markdown.parse("""
    **Pattern correlation with truth, J = $(d.metric[mi])**

    | estimator | """ * join(["$(round(Int, L)) d" for L in d.lead_days], " | ") * """ |
    |---|""" * repeat("---|", length(d.lead_days)) * "\n" * join(rows, "\n"))
end

# ╔═╡ Cell order:
# ╟─64fc7a2f-dc6b-4363-8a52-ff4d66966cd9
# ╠═61be9311-4771-4fc4-8017-5b5325672813
# ╠═d7ffa21d-8358-4724-a590-61abff052fe8
# ╠═720ba676-d5fb-4d64-8aaf-1492fd672e8e
# ╟─dc5deefd-df2d-4c93-944e-bac714643b98
# ╠═80b07e0f-a17f-402e-bbdf-a6b6ad44aaf6
# ╟─0ccca321-c2c3-4104-bca6-0b7163ec667c
# ╟─2c49eef6-0b21-4596-89c1-e295427ce0cf
# ╠═af4eeb6a-6c1e-45bc-b3db-da6d511ba220
# ╠═d80eb133-5989-4a3f-afba-2ac8eae62fdf
# ╠═6d0e919d-64e2-469f-8760-d0f8101c08e9
# ╠═026ec9e6-c67c-4bfb-83e0-5d56946b6cd9
# ╠═8730660d-75ad-46ce-80fa-9f2df7584829
# ╟─0fb46039-abcf-4c54-8313-79d7010bb114

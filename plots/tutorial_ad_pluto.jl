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

# ╔═╡ 2fd82490-f0b8-4bb2-ab81-d4da2e5cafe2
begin
    import Pkg
    Pkg.activate(@__DIR__)
    using CairoMakie, PlutoUI, PlutoLinks, Statistics
end

# ╔═╡ 87c31873-4559-4753-a12d-0c5119a88dd1
md"""
# AD tutorial: toy-model sensitivities
From `drivers/tutorial_ad.jl` (run in `run/tutorial-ad/`); explanations in `docs/tutorial_enzyme_reactant.md`.
`grad` = ∂J(M(x₀))/∂x₀ for J = Tₑ (ENSO) or T₁ (slab ocean, sector 1) at each lead, for 20 initial states.
Multiplying by the climatological std (σ) gives the change of J caused by a one-σ change of each
initial variable: comparable across variables with different units.
"""

# ╔═╡ a454e31b-fb82-4782-bec3-0b8e05e2ac9a
RD = @ingredients(joinpath(@__DIR__, "readers.jl"))

# ╔═╡ 0d75e523-0e09-4503-a4b9-0dc0e5e2b5a2
PL = @ingredients(joinpath(@__DIR__, "plotlib.jl"))

# ╔═╡ 84a610d7-8229-4438-b35c-a6e1ce790cba
d = RD.read_tutorial_ad(joinpath(@__DIR__, "..", "run", "tutorial-ad", "tutorial_ad.nc"))

# ╔═╡ 06419f0c-70e3-441b-a82c-9d2494603ada
let
    r(x) = round(x, sigdigits = 2)
    rows = ["| $(d.lead_days[i]) | $(r(d.dot_test[i])) | $(r(d.fd_relerr[i])) | $(r(d.reactant_relerr[i])) | $(r(d.t_enzyme[i])) | $(r(d.t_reactant_compile[i])) / $(r(d.t_reactant_run[i])) |"
            for i in eachindex(d.lead_days)]
    Markdown.parse("""
    ## Checks by lead
    | lead (days) | dot-product test | finite difference (ε = 1e-7) | Reactant vs Enzyme | Enzyme gradient (s) | Reactant compile / run (s) |
    |---|---|---|---|---|---|
    """ * join(rows, "\n"))
end

# ╔═╡ 5aa05fd5-91c1-4704-844c-23d1b0c5bd94
md"""
## Sensitivity maps
Metric: $(@bind metric_i PlutoUI.Select([1 => "Tₑ (ENSO)", 2 => "T₁ (slab ocean, sector 1)"]))
Initial state: $(@bind start_i PlutoUI.Slider(1:20; default = 1, show_value = true))
"""

# ╔═╡ 192beee5-2d98-4bbf-915b-2cf7485a1d5d
begin
    K = 36
    f_sens = Figure(size = (1000, 650))
    for (il, L) in enumerate(d.lead_days)
        gσ = d.grad[:, start_i, il, metric_i] .* d.sigma_clim
        ax = Axis(f_sens[il, 1]; ylabel = "$(L) d", xlabel = il == length(d.lead_days) ? "sector" : "",
                  title = il == 1 ? "atmosphere X: ∂J/∂x₀ ⋅ σ" : "")
        barplot!(ax, 1:K, gσ[1:K]; color = :steelblue)
        ax2 = Axis(f_sens[il, 2]; xlabel = il == length(d.lead_days) ? "sector" : "",
                   title = il == 1 ? "slab ocean T: ∂J/∂x₀ ⋅ σ" : "")
        barplot!(ax2, 1:K, gσ[(K + 1):(2K)]; color = :darkorange)
        ax3 = Axis(f_sens[il, 3]; title = il == 1 ? "Tₑ, h" : "", xticks = (1:2, ["Tₑ", "h"]))
        barplot!(ax3, 1:2, gσ[(2K + 1):(2K + 2)]; color = :seagreen)
    end
    colsize!(f_sens.layout, 3, Relative(0.12))
    f_sens
end

# ╔═╡ 6432ccec-e671-4a65-9297-77bb36117b11
md"""
## Where the sensitivity lives, against lead
RMS over the 20 initial states of the one-σ sensitivity, summed over each part of the state.
The atmosphere part grows with lead (chaos); a single-state gradient at long lead is mostly
"noise" from the atmosphere. The ensemble-mean gradient (averaged over initial states) keeps
only the part common to all states.
"""

# ╔═╡ 84cca4ca-3078-4157-8280-af7e709c1250
begin
    parts = (atmosphere = 1:36, ocean = 37:72, enso = 73:74)
    f_parts = Figure(size = (900, 380))
    for (im, name) in enumerate(["Tₑ", "T₁"])
        ax = Axis(f_parts[1, im]; xscale = log10, yscale = log10, xlabel = "lead (days)",
                  ylabel = im == 1 ? "‖∂J/∂x₀ ⋅ σ‖" : "", title = "J = $name")
        for (pname, idx) in pairs(parts)
            single = [sqrt(mean(sum(abs2, d.grad[idx, :, il, im] .* d.sigma_clim[idx]; dims = 1))) for il in eachindex(d.lead_days)]
            meangrad = [sqrt(sum(abs2, vec(mean(d.grad[idx, :, il, im]; dims = 2)) .* d.sigma_clim[idx])) for il in eachindex(d.lead_days)]
            l = scatterlines!(ax, d.lead_days, single; label = "$(pname)")
            lines!(ax, d.lead_days, meangrad; linestyle = :dash, color = l.color)
        end
        im == 2 && axislegend(ax; position = :lt)
    end
    Label(f_parts[2, :], "solid: single initial states (rms);  dashed: gradient averaged over initial states"; fontsize = 13)
    f_parts
end

# ╔═╡ 65cd1d98-4f5d-4bd8-92c7-1a234cb50012
md"""
## How long is the tangent-linear model valid?
Relative error of the linear prediction ∂J/∂x₀ ⋅ δx against the nonlinear change of J, for random
initial perturbations δx with std = amplitude × climatological std. Near 0: linear (adjoint
sensitivities trustworthy); near or above 1: nonlinear (use ensembles).
"""

# ╔═╡ 816c0228-1df8-4f80-ade0-04e886729769
begin
    f_tlm = Figure(size = (900, 380))
    for (im, name) in enumerate(["Tₑ", "T₁"])
        ax = Axis(f_tlm[1, im]; xscale = log10, yscale = log10, xlabel = "lead (days)",
                  ylabel = im == 1 ? "relative error of TLM" : "", title = "J = $name")
        hlines!(ax, [1.0]; color = :gray, linestyle = :dash)
        for (ia, a) in enumerate(d.amplitude)
            scatterlines!(ax, d.lead_days, d.tlm_relerr[ia, :, im]; label = "δx = $(a) σ")
        end
        im == 1 && axislegend(ax; position = :lt)
    end
    f_tlm
end

# ╔═╡ Cell order:
# ╟─87c31873-4559-4753-a12d-0c5119a88dd1
# ╠═2fd82490-f0b8-4bb2-ab81-d4da2e5cafe2
# ╠═a454e31b-fb82-4782-bec3-0b8e05e2ac9a
# ╠═0d75e523-0e09-4503-a4b9-0dc0e5e2b5a2
# ╠═84a610d7-8229-4438-b35c-a6e1ce790cba
# ╟─06419f0c-70e3-441b-a82c-9d2494603ada
# ╟─5aa05fd5-91c1-4704-844c-23d1b0c5bd94
# ╠═192beee5-2d98-4bbf-915b-2cf7485a1d5d
# ╟─6432ccec-e671-4a65-9297-77bb36117b11
# ╠═84cca4ca-3078-4157-8280-af7e709c1250
# ╟─65cd1d98-4f5d-4bd8-92c7-1a234cb50012
# ╠═816c0228-1df8-4f80-ade0-04e886729769

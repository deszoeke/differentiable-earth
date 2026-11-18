#####
##### Sensitivities of the expected forecast to the slow initial state (docs/technical.md §4)
#####

"""
    slow_indices(m::ToyCoupled)

Indices of the slow variables (slab ocean T₁…T_K, Tₑ, h): the part of the state whose initial
values can matter beyond the atmospheric predictability limit.
"""
slow_indices(m::ToyCoupled) = (m.params.K + 1):(2 * m.params.K + 2)

"""
    forecast_metric_series(J, m, x0, leads)

`J` of the forecast from `x0` at each lead in `leads` (steps, ascending), from a single run.
"""
function forecast_metric_series(J, m::AbstractPropagator, x0, leads)
    out = zeros(length(leads))
    x = copy(x0)
    t = 0
    for (i, n) in enumerate(leads)
        x = propagate(m, x, n - t)
        t = n
        out[i] = J(x)
    end
    return out
end

"""
    ensemble_fd_sensitivity(J, m, x0, idx, δ, noise, leads)

Truth for the sensitivity of the expected forecast: for each slow index `idx[i]`, centered
finite differences of the ensemble mean of J with step `δ[i]`, using the same noise realizations
(columns of `noise`, state × members) on both sides. Returns `(; s, se)`, each
`length(idx) × length(leads)`: the sensitivity and its standard error (from the spread of the
member-by-member differences). Multithreaded over members.
"""
function ensemble_fd_sensitivity(J, m::AbstractPropagator, x0, idx, δ, noise::AbstractMatrix, leads)
    nmem = size(noise, 2)
    s = zeros(length(idx), length(leads))
    se = similar(s)
    d = zeros(nmem, length(leads))
    for (i, j) in enumerate(idx)
        Threads.@threads for k in 1:nmem
            xp = x0 .+ noise[:, k]
            xm = copy(xp)
            xp[j] += δ[i]
            xm[j] -= δ[i]
            d[k, :] .= (forecast_metric_series(J, m, xp, leads) .- forecast_metric_series(J, m, xm, leads)) ./ (2δ[i])
        end
        s[i, :] .= vec(sum(d; dims = 1)) ./ nmem
        se[i, :] .= vec(sqrt.(sum(abs2, d .- s[i:i, :]; dims = 1) ./ (nmem - 1) ./ nmem))
    end
    return (; s, se)
end

"""
    ensemble_mean_gradient(J, m, x0, noise, n)

Mean over members of ∂J(M(x₀ + ε_k))/∂x₀ (one reverse pass per member), and the standard
error of that mean. Returns `(; g, se)` over the full state. Multithreaded over members.
"""
function ensemble_mean_gradient(J, m::AbstractPropagator, x0, noise::AbstractMatrix, n)
    nmem = size(noise, 2)
    G = zeros(length(x0), nmem)
    G[:, 1] .= gradient_J(J, m, x0 .+ noise[:, 1], n)    # first member serially: compile once, not per thread
    Threads.@threads for k in 2:nmem
        G[:, k] .= gradient_J(J, m, x0 .+ noise[:, k], n)
    end
    g = vec(sum(G; dims = 2)) ./ nmem
    se = vec(sqrt.(sum(abs2, G .- g; dims = 2) ./ (nmem - 1) ./ nmem))
    return (; g, se)
end

"""
    regression_sensitivity(Jvals, D)

Ensemble sensitivity: least-squares regression of the forecast metric values `Jvals` (one per
member) on the initial perturbations `D` (variables × members) of the variables of interest.
Returns the regression coefficients (one per row of `D`).
"""
function regression_sensitivity(Jvals::AbstractVector, D::AbstractMatrix)
    Ja = Jvals .- sum(Jvals) / length(Jvals)
    Da = D .- sum(D; dims = 2) ./ size(D, 2)
    return Da' \ Ja
end

"""
    fit_lim(Y, lag)

Linear inverse model dx/dt = L x for anomalies `Y` (variables × time, evenly sampled):
G(lag) = C(lag) C(0)⁻¹ and L = log(G)/lag, with `lag` in samples (L per sample). Returns `L`.
"""
function fit_lim(Y::AbstractMatrix, lag::Integer)
    Ya = Y .- sum(Y; dims = 2) ./ size(Y, 2)
    nt = size(Ya, 2)
    C0 = Ya[:, 1:(nt - lag)] * Ya[:, 1:(nt - lag)]' ./ (nt - lag)
    Cτ = Ya[:, (1 + lag):nt] * Ya[:, 1:(nt - lag)]' ./ (nt - lag)
    G = Cτ / C0
    return real(log(G)) ./ lag
end

"""
    lim_sensitivity(L, t, row)

Sensitivity of variable `row` at time `t` (samples) to the initial anomalies under the LIM:
row `row` of exp(L t).
"""
lim_sensitivity(L::AbstractMatrix, t::Real, row::Integer) = exp(L .* t)[row, :]

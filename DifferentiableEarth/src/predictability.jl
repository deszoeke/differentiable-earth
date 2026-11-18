#####
##### Predictable component analysis (Schneider & Griffies 1999) and LIM predictions.
##### Notation: docs/technical.md (Notation).
#####

"""
    predictable_components(Σ, C)

Eigen-decomposition of Σ(τ) C(0)⁻¹ via the generalized symmetric problem Σ q = γ C q.
Returns `(; γ, q, p)` sorted from most to least predictable (ascending γ):
- `γ`: the fraction of variance still unpredictable in each component at lead τ
  (0 = perfectly predictable, 1 = saturated at the nature-run variance);
- `q`: filters (columns), C-normalized (qᵀ C q = 1), so qᵀx is the component's amplitude;
- `p`: patterns, p = C q (columns), the anomaly structure of each component.
"""
function predictable_components(Σ::AbstractMatrix, C::AbstractMatrix)
    F = eigen(Symmetric(Matrix(Σ)), Symmetric(Matrix(C)))   # ascending eigenvalues
    q = F.vectors
    return (; γ = F.values, q, p = C * q)
end

"""
    predictive_information(γ)

Total predictive information −½ Σᵢ log γᵢ (Gaussian), from the eigenvalues of Σ(τ) C(0)⁻¹;
0 when the forecast spread has saturated (all γ = 1).
"""
predictive_information(γ::AbstractVector) = -sum(log, clamp.(γ, eps(), Inf)) / 2

"""
    pooled_forecast_covariance(ensembles)

⟨Σ(τ; t)⟩ over starts t: the average of each start's member covariance (deviations from that
start's ensemble mean). `ensembles` is a vector of (state × members) matrices at one lead.
"""
function pooled_forecast_covariance(ensembles::AbstractVector{<:AbstractMatrix})
    n = size(first(ensembles), 1)
    Σ = zeros(n, n)
    for X in ensembles
        D = X .- sum(X; dims = 2) ./ size(X, 2)
        Σ .+= D * D' ./ (size(X, 2) - 1)
    end
    return Σ ./ length(ensembles)
end

"""
    lim_forecast_covariance(L, C, Σ0, τ)

LIM prediction of the forecast covariance at lead τ (in the time units of L):
Σ(τ) = G(τ) Σ(0) G(τ)ᵀ + N(τ), with G(τ) = exp(Lτ) and N(τ) = C(0) − G(τ) C(0) G(τ)ᵀ.
"""
function lim_forecast_covariance(L::AbstractMatrix, C::AbstractMatrix, Σ0::AbstractMatrix, τ::Real)
    G = exp(L .* τ)
    return G * Σ0 * G' .+ (C .- G * C * G')
end

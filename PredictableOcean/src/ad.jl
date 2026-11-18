#####
##### Tangent-linear (JVP) and adjoint (VJP) products of the forecast map, via Enzyme.
##### The same functions work in plain Julia (Enzyme on LLVM) and inside `Reactant.@compile`
##### (Enzyme on MLIR), because `propagate` uses a `@trace` loop. See docs/technical.md §3.
#####

# Positional wrappers: Enzyme annotates positional arguments (Const, Duplicated, Active).
# Each public function also has an all-positional method, because functions compiled with
# Reactant.@compile cannot take keyword arguments when called.
_propagate(m, x, n, ckpt) = propagate(m, x, n; checkpointing = ckpt)
_project(m, x, λ, n, ckpt) = sum(λ .* _propagate(m, x, n, ckpt))      # λ ⋅ M(x)
_forecast_metric(J, m, x, n, ckpt) = J(_propagate(m, x, n, ckpt))      # J(M(x))

"""
    jvp(m, x, v, n; checkpointing = false)

Tangent-linear model: **L** v, where **L** = ∂M/∂x at `x` and M = `propagate(m, ·, n)`.
How a small initial perturbation `v` has grown after `n` steps (Enzyme forward mode).
"""
jvp(m::AbstractPropagator, x, v, n; checkpointing = false) = jvp(m, x, v, n, checkpointing)
jvp(m::AbstractPropagator, x, v, n, checkpointing) =
    Enzyme.autodiff(Forward, _propagate, Const(m), Duplicated(x, v), Const(n), Const(checkpointing))[1]

"""
    vjp(m, x, λ, n; checkpointing = false)

Adjoint model: **L**ᵀ λ, the gradient of λ ⋅ M(x) with respect to the initial state `x`
(Enzyme reverse mode). With λ = ∇J at the final time this is the sensitivity of J to the
initial state.
"""
vjp(m::AbstractPropagator, x, λ, n; checkpointing = false) = vjp(m, x, λ, n, checkpointing)
function vjp(m::AbstractPropagator, x, λ, n, checkpointing)
    dx = Enzyme.make_zero(x)
    Enzyme.autodiff(Reverse, _project, Active, Const(m), Duplicated(x, dx), Const(λ), Const(n), Const(checkpointing))
    return dx
end

"""
    gradient_J(J, m, x, n; checkpointing = false)

∂J(M(x))/∂x: sensitivity of the scalar forecast metric `J` (a callable on the state, e.g. a
[`Component`](@ref)) at lead `n` steps to every initial-state variable, in one reverse pass.
"""
gradient_J(J, m::AbstractPropagator, x, n; checkpointing = false) = gradient_J(J, m, x, n, checkpointing)
function gradient_J(J, m::AbstractPropagator, x, n, checkpointing)
    dx = Enzyme.make_zero(x)
    Enzyme.autodiff(Reverse, _forecast_metric, Active, Const(J), Const(m), Duplicated(x, dx), Const(n),
                    Const(checkpointing))
    return dx
end

"""
    Component(indices)

A scalar forecast metric J(x) = sum of the state entries at `indices` (a range), e.g.
`Component(state_slices(m).Te)` for Tₑ, or `Component(state_slices(m).ocean[1:1])` for the
slab-ocean temperature of sector 1. Written with a slice and `sum`, so it is Reactant-safe.
"""
struct Component{R <: AbstractUnitRange}
    indices::R
end
(J::Component)(x) = sum(x[J.indices])

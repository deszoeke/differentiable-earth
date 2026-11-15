"""
    AbstractPropagator

A model that advances a state vector `x` in time: the forecast map M(T). Every analysis
(covariance, singular vectors, targeting, OSSE) is written against this interface, so the
toy model and the coupled Earth system model are interchangeable.

Required methods for a subtype `P`:
- `state_length(m::P)`: length of the state vector.
- `state_slices(m::P)`: a NamedTuple of index ranges naming the parts of the state
  (e.g. `(atmosphere = 1:36, ocean = 37:72, ...)`).
- `advance(m::P, x)`: one time step; returns a new vector (does not mutate `x`).
- `timestep(m::P)`: the model time step, in model time units.

Provided: `propagate(m, x, n)` (n steps). Tangent-linear and adjoint products (`jvp`, `vjp`)
are added by the AD layer.
"""
abstract type AbstractPropagator end

"""
    propagate(m::AbstractPropagator, x, n::Integer)

Advance state `x` by `n` steps of `m`, returning the final state. Plain Julia loop; the
Reactant version uses a traced loop (see the AD layer).
"""
function propagate(m::AbstractPropagator, x, n::Integer)
    for _ in 1:n
        x = advance(m, x)
    end
    return x
end

"""
    trajectory(m::AbstractPropagator, x, n::Integer; every = 1)

Run `n` steps from `x` and return a matrix whose columns are the states every `every` steps,
starting with `x` itself.
"""
function trajectory(m::AbstractPropagator, x, n::Integer; every::Integer = 1)
    nsave = n ÷ every + 1
    X = similar(x, length(x), nsave)
    X[:, 1] .= x
    j = 1
    for i in 1:n
        x = advance(m, x)
        if i % every == 0
            j += 1
            X[:, j] .= x
        end
    end
    return X
end

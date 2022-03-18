# Arc
struct Arc{T} <: AbstractArc{T}
    src::T # source
    tgt::T # target
    key::Union{Nothing,Int}
end

eltype(::Arc{T}) where {T} = T
reverse(a::Arc) = Arc(tgt(a), src(a), key(a))

Arc(u::T, v::T, k::Int) where {T} = Arc{T}(u, v, k)
Arc(u::T, v::T, k::Nothing) where {T} = Arc{T}(u, v, k)
Arc(u::T, v::T) where {T} = Arc{T}(u, v, nothing)

Arc(t::Tuple{T,T,Nothing}) where {T} = Arc(t...)
Arc(t::Tuple{T,T,Int}) where {T} = Arc(t...)
Arc(t::Tuple{T,T}) where {T} = Arc(t...)
Tuple(a::Arc{T}) where {T} = isnothing(a.key) ? (a.src, a.tgt) : (a.src, a.tgt, a.key)

add_arc!(g::AbstractNexus{T}, a::Arc{T}) where T = add_arc!(g, src(a), tgt(a), key(a))
rem_arc!(g::AbstractNexus{T}, a::Arc{T}) where T = rem_arc!(g, src(a), tgt(a), key(a))

has_arc(g::AbstractNexus{T}, a::Arc{T}) where T = has_arc(g, src(a), tgt(a), key(a))
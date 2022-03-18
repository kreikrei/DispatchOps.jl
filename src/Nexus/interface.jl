abstract type AbstractNexus{T} end
abstract type AbstractArc{T} end
abstract type AbstractArcIter{T} end

@traitdef IsDirected{G<:AbstractNexus}
@traitimpl IsDirected{G} <- is_directed(G)

function show(io::IO, g::AbstractNexus{T}) where {T}
    dir = is_directed(g) ? "directed" : "undirected"
    print(io, "{$(nn(g)), $(na(g))} $dir $T graph.")
end

function show(io::IO, a::AbstractArc{T}) where {T}
    print(io, "Arc $T $(src(a)) -> $(tgt(a)) key $(key(a))")
end

function show(io::IO, ait::AbstractArcIter{T}) where {T}
    print(io, "ArcIter $T $(length(ait.list))")
end

eltype(::AbstractNexus{T}) where {T} = T

nn(g::AbstractNexus) = g.nn
na(g::AbstractNexus) = g.na
fadj(g::AbstractNexus) = g.fadj
nodes(g::AbstractNexus) = g.fadj |> keys

has_node(g::AbstractNexus{T}, n::T) where {T} = n in nodes(g)
function has_arc(g::AbstractNexus{T}, u::T, v::T, key::Int) where {T}
    haskey(g.fadj, u) && haskey(g.fadj[u],v) && haskey(g.fadj[u][v], key) && return true
    return false
end
# not dependent on directedness? NO. 
# why? karena klo yg dicek fadj-nya, u--v dan v--u ada dua2nya 

src(a::AbstractArc) = a.src
tgt(a::AbstractArc) = a.tgt
key(a::AbstractArc) = a.key
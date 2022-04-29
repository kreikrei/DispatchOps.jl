mutable struct MetaDigraph{T} <: AbstractMetaNexus{T}
    core::Digraph{T}
    nprops::Dict{T,Dict{Symbol,Any}}
    aprops::Dict{Arc{T},Dict{Symbol,Any}}
end

@forward MetaDigraph.core badj
MetaDigraph{T}() where {T} = MetaDigraph(Digraph{T}())
function MetaDigraph(core::Digraph{T}) where {T}
    MetaDigraph{T}(core, Dict{T,Dict{Symbol,Any}}(), Dict{Arc{T},Dict{Symbol,Any}}())
end
is_directed(::MetaDigraph) = true
Digraph(g::MetaDigraph{T}) where {T} = g.core

function empty!(g::MetaDigraph{T}) where {T}
    empty!(g.core)
    empty!(g.nprops)
    empty!(g.aprops)
    return nothing
end

function set_props!(g::MetaDigraph{T}, a::Arc{T}, d::Dict) where {T}
    has_arc(g, a) || return false
    !_hasdict(g, a) ? g.aprops[a] = d : merge!(g.aprops[a], d)
    return true
end

rem_prop!(g::MetaDigraph{T}, a::Arc{T}, prop::Symbol) where {T} =
    delete!(g.aprops[a], prop)

clear_props!(g::MetaDigraph{T}, a::Arc{T}) where {T} =
    _hasdict(g, a) && delete!(g.aprops, a)
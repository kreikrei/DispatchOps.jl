mutable struct MetaGraph{T} <: AbstractMetaNexus{T}
    core::Graph{T}
    nprops::Dict{T,Dict{Symbol,Any}}
    aprops::Dict{Arc{T},Dict{Symbol,Any}}
end

MetaGraph{T}() where {T} = MetaGraph(Graph{T}())
function MetaGraph(core::Graph{T}) where {T}
    MetaGraph{T}(core, Dict{T,Dict{Symbol,Any}}(), Dict{Arc{T},Dict{Symbol,Any}}())
end
is_directed(::MetaGraph) = false
Graph(g::MetaGraph{T}) where {T} = g.core

function empty!(g::MetaGraph{T}) where {T}
    empty!(g.core)
    empty!(g.nprops)
    empty!(g.aprops)
    return nothing
end

function set_props!(g::MetaGraph{T}, a::Arc{T}, d::Dict) where {T}
    (has_arc(g, a) && has_arc(g, reverse(a))) || return false
    !_hasdict(g, a) ? g.aprops[a] = d : merge!(g.aprops[a], d)
    !_hasdict(g, reverse(a)) ? g.aprops[reverse(a)] = d : merge!(g.aprops[reverse(a)], d)
    return true
end

function rem_prop!(g::MetaGraph{T}, a::Arc{T}, prop::Symbol) where {T}
    delete!(g.aprops[a], prop)
    delete!(g.aprops[reverse(a)], prop)
end

function clear_props!(g::MetaGraph{T}, a::Arc{T}) where {T}
    _hasdict(g, a) && delete!(g.aprops, a)
    _hasdict(g, reverse(a)) && delete!(g.aprops, reverse(a))
end

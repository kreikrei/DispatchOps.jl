struct ArcIter{T} <: AbstractArcIter{T}
    list::Vector{Arc{T}}
end

@forward ArcIter.list iterate, eltype, length, rand

function arcs(g::Graph{T}) where {T}
    list = Arc{T}[]
    sizehint!(list, g.na)
    @inbounds for (u,nbr) in g.fadj, (v,keylist) in nbr, (key,fin) in keylist
        Arc(v, u, key) in list || push!(list, Arc(u, v, key))
    end
    return ArcIter(list)
end

function arcs(g::Graph{T}, n::Union{T,Vector{T}}) where {T}
    # all arc adjacent to n in UNDIRECTED Graph
    list = Arc{T}[]
    sizehint!(list, g.na)
    @inbounds for u in n, (v,keylist) in g.fadj[u], (key,fin) in keylist
        Arc(v, u, key) in list || push!(list, Arc(u, v, key))
    end
    return ArcIter(list)
end

# arcs dependent on directedness. why? karena klo Graph pas ditarik arc list-nya, 
# cuma ada satu representasi dari dua arc yg bolak balik.
# which means (u -- v dan v -- u direpresentasikan oleh u -- v)

function arcs(g::Digraph{T}) where {T}
    list = Arc{T}[]
    sizehint!(list, g.na)
    @inbounds for (u,nbr) in g.fadj, (v,keylist) in nbr, (key,fin) in keylist
        push!(list, Arc(u, v, key))
    end
    return ArcIter(list)
end

function arcs(g::Digraph{T}, n::Union{T,Vector{T}}, ::Colon) where {T}
    list = Arc{T}[]
    sizehint!(list, g.na)
    @inbounds for u in n, (v,keylist) in g.fadj[u], (key,fin) in keylist
        push!(list, Arc(u, v, key))
    end
    return ArcIter(list)
end

function arcs(g::Digraph{T}, ::Colon, n::Union{T,Vector{T}}) where {T}
    list = Arc{T}[]
    sizehint!(list, g.na)
    @inbounds for v in n, (u,keylist) in g.badj[v], (key,fin) in keylist
        push!(list, Arc(u, v, key))
    end
    return ArcIter(list)
end
# Graph
mutable struct Graph{T} <: AbstractNexus{T}
    nn::Int
    na::Int
    fadj::Dict{T,Dict{T,Dict{Int,Nothing}}}
end

is_directed(::Graph{T}) where {T} = false
Graph{T}() where {T} = begin
    fadj = Dict{T,Dict{T,Dict{Int,Nothing}}}()
    return Graph(0, 0, fadj)
end

function empty!(g::Graph{T}) where {T}
    g.nn = 0
    g.na = 0
    empty!(g.fadj)
    return nothing
end

function add_arc!(G::Graph{T}, u::T, v::T, key::Union{Int,Nothing}=nothing) where {T}
    haskey(G.fadj, u) || begin
        G.fadj[u] = Dict()
        G.nn += 1
    end
    haskey(G.fadj, v) || begin
        G.fadj[v] = Dict()
        G.nn += 1
    end
    isnothing(key) && (key = new_arc_key(G, u, v))

    get!(G.fadj[u], v, Dict())
    get!(G.fadj[v], u, Dict())

    (haskey(G.fadj[u][v], key) || haskey(G.fadj[v][u], key)) || (G.na += 1)
    get!(G.fadj[u][v], key, nothing)
    get!(G.fadj[v][u], key, nothing)
    return key
end

# add_arc buat graph menambahkan u--v dan v--u ke fadj

function new_arc_key(g::Graph{T}, u::T, v::T) where {T}
    (haskey(g.fadj[u], v) || haskey(g.fadj[v], u)) ? begin
        keylist = union(keys(g.fadj[u][v]), keys(g.fadj[v][u]))
    end : return 1
    key = length(keylist)
    while key in keylist
        key += 1
    end # find lowest integer not used
    return key
end

function rem_arc!(G::Graph{T}, u::T, v::T, key::Union{Int,Nothing}=nothing) where {T}
    (haskey(G.fadj[u], v) || haskey(G.fadj[u], v)) ? begin
        d1 = G.fadj[u][v]
        d2 = G.fadj[v][u]
    end : return false # no v on u
    isnothing(key) ? begin
        pop!(d1)
        pop!(d2)
    end : (haskey(d1, key) || haskey(d2, key)) ? begin
        delete!(d1, key)
        delete!(d2, key)
    end : return false # rem key
    (length(d1) == 0 || length(d2) == 0) && begin
        delete!(G.fadj[u], v)
        delete!(G.badj[v], u)
    end
    G.na -= 1
    return true
end

function add_node!(g::Graph{T}, u) where {T}
    !haskey(g.fadj, u) ? begin # doesn't have node, create new dict
        g.fadj[u] = Dict()
        g.nn += 1
        return u
    end : return nothing
end

function rem_node!(g::Graph{T}, u::T) where {T}
    haskey(g.fadj, u) || return false

    for v in keys(g.fadj[u])
        g.na -= length(g.fadj[u][v])
        delete!(g.fadj[v], u)
        delete!(g.fadj[u], v)
    end
    delete!(g.fadj, u)
    g.nn -= 1
    return true
end
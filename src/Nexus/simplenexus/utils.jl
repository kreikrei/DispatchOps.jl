# CONVERSIONS
function Graph(D::Digraph{T}) where {T}
    G = Graph{T}()
    map(a -> add_arc!(G, a), arcs(D))
    return G
end

function Digraph(G::Graph{T}) where {T}
    D = Digraph{T}()
    map(a -> add_arc!(D, a), arcs(G))
    map(a -> add_arc!(D, reverse(a)), arcs(G))
    return D
end
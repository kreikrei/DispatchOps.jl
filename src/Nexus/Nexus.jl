module Nexus

using SimpleTraits
using Lazy

import DispatchOps.Nexus
import Base:
    show, eltype, Tuple, iterate, length, reverse,
    getindex, rand, isempty, empty!

include("interface.jl")

include("./simplenexus/arc.jl")
include("./simplenexus/digraph.jl")
include("./simplenexus/graph.jl")
include("./simplenexus/arciter.jl")
include("./simplenexus/utils.jl")

include("./metanexus/extension.jl")
include("./metanexus/metadigraph.jl")
include("./metanexus/metagraph.jl")

export
    Graph, Digraph, Arc, ArcIter,
    add_arc!, rem_arc!, add_node!, rem_node!,
    nn, na, nodes, arcs, fadj, badj, has_arc, has_node,
    src, tgt, key, MetaGraph, MetaDigraph, props, get_prop, has_prop,
    set_props!, set_prop!, rem_prop!, clear_props!,
    filter_arcs, filter_nodes

end
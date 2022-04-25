module DispatchOps

export
    # Nexus/simplenexus
    Graph, Digraph, Arc, ArcIter, 
    add_arc!, rem_arc!, add_node!, rem_node!, 
    nn, na, nodes, arcs, fadj, badj, has_arc, has_node, 
    src, tgt, key,

    # Nexus/metanexus
    MetaGraph, MetaDigraph, props, get_prop, has_prop, 
    set_props!, set_prop!, rem_prop!, clear_props!,
    filter_arcs, filter_nodes,

    # Sim
    Libraries, Params, States, Accumulators

include("Nexus/Nexus.jl")
using .Nexus

include("Sim/Sim.jl")
using .Sim

end
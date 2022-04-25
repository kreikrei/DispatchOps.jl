
"""
    transport!(ts, stt, acc)
1. filter `stt.dispatch_queue` for dispatch to be executed at current timestep `ts` and \
remove filtered dispatch from `stt.dispatch_queue`
2. update `stt.current_stock` given the executed dispatch at the current timestep `ts` \
and add the executed dispatch to `acc.executed_dispatch`
"""
function transport!(ts::Int, stt::States, acc::Accumulators)
    to_execute = MetaDigraph{locper}()
    for a in Iterators.filter(p -> src(p).per == ts, arcs(stt.dispatch_queue))
        add_arc!(to_execute, a)
        set_props!(to_execute, a, stt.dispatch_queue[a])
        rem_arc!(stt.dispatch_queue, a)
    end

    for a in arcs(to_execute)
        for k in keys(to_execute[a][:flow])
            stt.current_stock[
                stt.current_stock.id.==src(a).loc.&&stt.current_stock.pecahan.==k,
                :value
            ] .-= to_execute[a][:flow][k] # stock reduction at source
            stt.current_stock[
                stt.current_stock.id.==tgt(a).loc.&&stt.current_stock.pecahan.==k,
                :value
            ] .+= to_execute[a][:flow][k] # stock addition at target
        end

        add_arc!(acc.executed_dispatch, a)
        set_props!(acc.executed_dispatch, a, to_execute[a])
    end

    return nothing
end

transport!(sim::Simulation) = transport!(sim.t, sim.stt, sim.acc)
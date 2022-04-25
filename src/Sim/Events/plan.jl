
"""
    plan!(ts, stt, libs, cons)
1. build model and solve dispatch sequence for `cons.T` time unit ahead \
from current timestep `ts` given `stt.current_stock` \
using `libs.khazanah`, `libs.trayek`, and `libs.demand_forecast`
2. extract dispatch sequence starting from current timestep `ts` \
for 1 time unit and add it to `stt.dispatch_queue`
"""
function plan!(ts::Int, stt::States, libs::Libraries, params::Params)
    EG = buildGraph(libs.khazanah, libs.trayek, ts, params.T)
    model = buildModel(EG, libs.demand_forecast, stt.current_stock)
    optimizeModel!(model, gap=params.GAP)

    to_append = Iterators.filter(a ->
            src(a).per >= ts &&
                tgt(a).per <= ts + 1 &&
                EG[a][:type] == "transport",
        arcs(EG)
    )

    for a in to_append
        v = value.(model[:flow][a, :])
        if !iszero(v)
            add_arc!(stt.dispatch_queue, a)
            set_props!(stt.dispatch_queue, a, EG[a])
            set_props!(stt.dispatch_queue, a,
                Dict(
                    :flow => Dict(p => v[p] for p in v.axes[1]),
                    :trip => value(model[:trip][a]) |> round
                )
            )
        end
    end

    return nothing
end

plan!(sim::Simulation) = plan!(sim.t, sim.stt, sim.libs, sim.cons)
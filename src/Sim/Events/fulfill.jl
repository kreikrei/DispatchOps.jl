
"""
    fulfill!(ts, stt, acc, libs)
1. create fulfillment flow given `stt.current_stock` and \
`libs.demand_realization` at current timestep `ts` + 1
2. update `stt.current_stock` given the fulfillment flow and \
add it to the `acc.demand_fulfillment`
3. append `stt.current_stock` to `acc.inventory_levels`
"""
function fulfill!(ts::Int, stt::States, acc::Accumulators, libs::Libraries)
    to_fulfill = filter(p -> p.periode == ts + 1, libs.demand_realization)
    fulfillment = similar(to_fulfill, 0)

    for r in eachrow(to_fulfill)
        v = min(
            r.value,
            stt.current_stock[
                stt.current_stock.id.==r.id.&&stt.current_stock.pecahan.==r.pecahan,
                :value
            ] |> first
        )
        append!(fulfillment,
            DataFrame(
                id=r.id,
                periode=r.periode,
                pecahan=r.pecahan,
                value=v
            )
        )
    end

    for r in eachrow(fulfillment)
        stt.current_stock[
            stt.current_stock.id.==r.id.&&stt.current_stock.pecahan.==r.pecahan,
            :value
        ] .-= r.value
    end

    append!(acc.demand_fulfillment, fulfillment)
    append!(acc.inventory_levels,
        DataFrame(
            id=stt.current_stock.id,
            periode=ts + 1,
            pecahan=stt.current_stock.pecahan,
            value=stt.current_stock.value
        )
    )

    return nothing
end

fulfill!(sim::Simulation) = fulfill!(sim.t, sim.stt, sim.acc, sim.libs)
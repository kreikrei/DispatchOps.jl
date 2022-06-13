const DF = DataFrame

"""
    buildGraph(khazanah, trayek, moda, ts, pH)
takes in `khazanah`, `trayek`, and `moda` with a given timestep `ts` and \
planning horizon `pH` to construct the graph in which the dispatch plan is built.
"""
function buildGraph(khazanah::DF, trayek::DF, moda::DF, ts::Int, pH::Int)
    EG = MetaDigraph{locper}()

    for i in eachrow(khazanah)
        add_node!(EG, locper(i.id, ts)) # stock nodes
        set_prop!(EG, locper(i.id, ts), :type, "stock")
        set_prop!(EG, locper(i.id, ts), :coor, (x=i.x, y=i.y))

        for t in ts+1:ts+pH
            add_node!(EG, locper(i.id, t)) # demand nodes
            set_prop!(EG, locper(i.id, t), :type, "demand")
            set_prop!(EG, locper(i.id, t), :coor, (x=i.x, y=i.y))
        end

        add_node!(EG, locper(i.id, ts + pH + 1)) # sink nodes
        set_prop!(EG, locper(i.id, ts + pH + 1), :type, "sink")
        set_prop!(EG, locper(i.id, ts + pH + 1), :coor, (x=i.x, y=i.y))
    end

    to_use = innerjoin(trayek, moda, on=:moda => :name)

    for t in ts:ts+pH
        for i in eachrow(khazanah)
            u = locper(i.id, t)
            v = locper(i.id, t + 1)
            k = add_arc!(EG, u, v)
            set_props!(EG, Arc(u, v, k),
                Dict(
                    :Q => i.Q,
                    :cpeti => i.cpeti,
                    :cjarak => i.cjarak,
                    :moda => "GDNG",
                    :type => "holdover"
                )
            )
        end
        for r in eachrow(to_use)
            if t + 1 <= ts + pH
                u = locper(r.u, t)
                v = locper(r.v, t + 1)
                k = add_arc!(EG, u, v)
                set_props!(EG, Arc(u, v, k),
                    Dict(
                        :Q => r.Q,
                        :cpeti => r.cpeti,
                        :cjarak => haversine(EG[u][:coor], EG[v][:coor]) /
                                   1000 * r.cjarak,
                        :moda => r.moda,
                        :type => "transport"
                    )
                )
            end
        end
    end

    return EG
end

function standard_model(EG::MetaDigraph{locper}, demand::DF, stock::DF)
    m = Model()

    # demand and stock as reference
    gdf_demand = groupby(demand, [:id, :periode, :pecahan])
    gdf_stock = groupby(stock, [:id, :pecahan])

    # set definitions
    pecahan = unique(demand.pecahan)

    sink_nodes = filter_nodes(EG, :type, "sink")
    stock_nodes = filter_nodes(EG, :type, "stock")
    demand_nodes = filter_nodes(EG, :type, "demand")

    all_arcs = arcs(EG)
    holdover_arcs = filter_arcs(EG, :type, "holdover")
    transport_arcs = filter_arcs(EG, :type, "transport")

    # model definition
    @variable(m, 0 <= trip[a=all_arcs], Int)
    @variable(m, 0 <= flow[a=all_arcs, p=pecahan])
    @variable(m, 0 <= sink[n=sink_nodes, p=pecahan]) # dummy sink vars

    @constraint(m, flow_bal[n=demand_nodes, p=pecahan],
        sum(flow[a, p] for a in arcs(EG, :, [n])) -
        sum(flow[a, p] for a in arcs(EG, [n], :)) ==
        gdf_demand[(n.loc, n.per, p,)].value[1]
    )

    @constraint(m, stock_bal[n=stock_nodes, p=pecahan],
        sum(flow[a, p] for a in arcs(EG, [n], :)) == gdf_stock[(n.loc, p,)].value[1]
    ) # flow balance at stock nodes

    @constraint(m, sink_bal[n=sink_nodes, p=pecahan],
        sum(flow[a, p] for a in arcs(EG, :, [n])) == sink[n, p]
    ) # flow balance at dummy sinks

    @constraint(m, arc_cap[a=all_arcs],
        sum(flow[a, p] for p in pecahan) <= trip[a] * EG[a][:Q]
    ) # arc capacity constraint

    @constraint(m, inv_cap[a=holdover_arcs],
        trip[a] <= 1
    ) # trips for inventories

    @objective(m, Min,
        sum(
            EG[a][:cpeti] * sum(flow[a, p] for p in pecahan) + EG[a][:cjarak] * trip[a]
            for a in arcs(EG)
        )
    )

    return m
end

"""
    hard_holdover_model(EG, demands, stock)
takes in the graph and extracted demands and also stock to create a mathematical model.
Use the hard constraint on vault capacity constraint. Flow balanced as soft constraint.
"""
function hard_holdover_model(EG::MetaDigraph{locper}, demand::DF, stock::DF)
    m = Model()

    # demand and stock as reference
    gdf_demand = groupby(demand, [:id, :periode, :pecahan])
    gdf_stock = groupby(stock, [:id, :pecahan])

    # set definitions
    pecahan = unique(demand.pecahan)

    sink_nodes = filter_nodes(EG, :type, "sink")
    stock_nodes = filter_nodes(EG, :type, "stock")
    demand_nodes = filter_nodes(EG, :type, "demand")

    all_arcs = arcs(EG)
    holdover_arcs = filter_arcs(EG, :type, "holdover")
    transport_arcs = filter_arcs(EG, :type, "transport")

    # model definition
    @variable(m, 0 <= trip[a=all_arcs], Int)
    @variable(m, 0 <= flow[a=all_arcs, p=pecahan])
    @variable(m, 0 <= sink[n=sink_nodes, p=pecahan]) # dummy sink vars

    @constraint(m, stock_bal[n=stock_nodes, p=pecahan],
        sum(flow[a, p] for a in arcs(EG, [n], :)) == gdf_stock[(n.loc, p,)].value[1]
    ) # flow balance at stock nodes

    @constraint(m, sink_bal[n=sink_nodes, p=pecahan],
        sum(flow[a, p] for a in arcs(EG, :, [n])) == sink[n, p]
    ) # flow balance at dummy sinks

    @constraint(m, arc_cap[a=all_arcs],
        sum(flow[a, p] for p in pecahan) <= trip[a] * EG[a][:Q]
    ) # arc capacity constraint

    @constraint(m, inv_cap[a=holdover_arcs],
        trip[a] <= 1
    ) # trips for inventories

    @objective(m, Min,
        sum(
            EG[a][:cpeti] * sum(flow[a, p] for p in pecahan) + EG[a][:cjarak] * trip[a]
            for a in arcs(EG)
        ) +
        sum(
            (
                sum(flow[a, p] for a in arcs(EG, :, [n])) -
                sum(flow[a, p] for a in arcs(EG, [n], :)) -
                gdf_demand[(n.loc, n.per, p,)].value[1]
            )^2
            for n in demand_nodes, p in pecahan
        )
    )

    return m
end

"""
    soft_holdover_model(EG, demands, stock)
takes in the graph and extracted demands and also stock to create a mathematical model.
Use the soft constraint on vault capacity constraint. Flow balanced as soft constraint.
"""
function soft_holdover_model(EG::MetaDigraph{locper}, demand::DF, stock::DF)
    m = Model()

    # demand and stock as reference
    gdf_demand = groupby(demand, [:id, :periode, :pecahan])
    gdf_stock = groupby(stock, [:id, :pecahan])

    # set definitions
    pecahan = unique(demand.pecahan)

    sink_nodes = filter_nodes(EG, :type, "sink")
    stock_nodes = filter_nodes(EG, :type, "stock")
    demand_nodes = filter_nodes(EG, :type, "demand")

    all_arcs = arcs(EG)
    holdover_arcs = filter_arcs(EG, :type, "holdover")
    transport_arcs = filter_arcs(EG, :type, "transport")

    # model definition
    @variable(m, 0 <= trip[a=all_arcs], Int)
    @variable(m, 0 <= surp[a=holdover_arcs]) # surplus for khazanah
    @variable(m, 0 <= flow[a=all_arcs, p=pecahan])
    @variable(m, 0 <= sink[n=sink_nodes, p=pecahan]) # dummy sink vars

    @constraint(m, stock_bal[n=stock_nodes, p=pecahan],
        sum(flow[a, p] for a in arcs(EG, [n], :)) == gdf_stock[(n.loc, p,)].value[1]
    ) # flow balance at stock nodes

    @constraint(m, sink_bal[n=sink_nodes, p=pecahan],
        sum(flow[a, p] for a in arcs(EG, :, [n])) == sink[n, p]
    ) # flow balance at dummy sinks

    @constraint(m, arc_cap[a=transport_arcs],
        sum(flow[a, p] for p in pecahan) <= trip[a] * EG[a][:Q]
    ) # transport arc capacity constraint

    @constraint(m, inv_cap[a=holdover_arcs],
        trip[a] <= 1
    ) # trips for inventories

    @objective(m, Min,
        sum(
            EG[a][:cpeti] * sum(flow[a, p] for p in pecahan) + EG[a][:cjarak] * trip[a]
            for a in arcs(EG)
        ) +
        sum(
            (
                sum(flow[a, p] for a in arcs(EG, :, [n])) -
                sum(flow[a, p] for a in arcs(EG, [n], :)) -
                gdf_demand[(n.loc, n.per, p,)].value[1]
            )^2
            for n in demand_nodes, p in pecahan
        ) + # penalized flow balance at nodes
        sum(
            (
                sum(flow[a, p] for p in pecahan) -
                surp[a] -
                trip[a] * EG[a][:Q]
            )^2
            for a in holdover_arcs
        ) + # penalized inventory capacity arcs
        sum(
            surp[a]^2
            for a in holdover_arcs
        )
    )

    return m
end

function optimizeModel(m::Model; gap::Float64, env::Gurobi.Env, silent::Bool=true)
    set_optimizer(m, () -> Gurobi.Optimizer(env); add_bridges=false)
    silent && set_silent(m)
    set_optimizer_attributes(m,
        "MIPGap" => gap,
        "NumericFocus" => 2,
        # "ScaleFlag" => 2,
        "Threads" => 8
    )
    optimize!(m)
    return nothing
end

"""
    plan!(ts, stt, libs, params)
1. build model and solve dispatch sequence for `params.T` time unit ahead \
from current timestep `ts` given `stt.current_stock` \
using `libs.khazanah`, `libs.trayek`, and `libs.demand_forecast`
2. extract dispatch sequence starting from current timestep `ts` \
for 1 time unit and add it to `stt.dispatch_queue`
"""
function plan!(ts::Int, stt::States, libs::Libraries, params::Params)
    EG = buildGraph(libs.khazanah, libs.trayek, libs.moda, ts, params.H)
    model = params.model(EG, libs.demand_forecast, stt.current_stock)
    optimizeModel(model, gap=params.GAP, env=params.env)

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

plan!(sim::Simulation) = plan!(sim.t, sim.stt, sim.libs, sim.params)
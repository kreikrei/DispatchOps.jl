"""
    readData(path_to_data_folder, complete_trayek = true)
reads the data folder given into dataframes ready to be used.
the data folder must contain:
- khazanah (id, name, x_coor, y_coor, capacity, cjarak, cpeti, transit)
- trayek (u, v, moda)
- moda (name, capacity, cjarak, cpeti, transit)
- demand (location_id, period, pecahan, value)
- stock (location_id, pecahan, value)
by default completes the trayek by ensuring for every a -> b there exists b -> a.
"""
function readData(path::String, complete_trayek::Bool = true)
    khazanah = CSV.read(joinpath(path,"khazanah.csv"), DataFrame)
    demand = CSV.read(joinpath(path,"demand.csv"), DataFrame)
    stock = CSV.read(joinpath(path,"stock.csv"), DataFrame)
    trayek = CSV.read(joinpath(path,"trayek.csv"), DataFrame)
    moda = CSV.read(joinpath(path,"moda.csv"), DataFrame)

    if complete_trayek
        append!(trayek, DataFrame(u = trayek.v, v = trayek.u, moda = trayek.moda))
        unique!(trayek)
    end

    trayek = innerjoin(trayek, moda, on = :moda => :name)
    
    return khazanah, demand, stock, trayek
end


"""
    buildGraph(khazanah, trayek, ts, pH)
takes in `khazanah` and `trayek` with a given `timestep` and `planningHorizon` to construct the graph in which the dispatch plan is built.
"""
function buildGraph(khazanah::DataFrame, trayek::DataFrame, ts::Int, pH::Int)
    EG = MetaDigraph{locper}()

    for i in eachrow(khazanah)
        add_node!(EG, locper(i.id, ts)) # stock nodes
        set_prop!(EG, locper(i.id, ts), :type, "stock")
        set_prop!(EG, locper(i.id, ts), :coor, (x = i.x, y = i.y))
    
        for t in ts + 1:ts + pH
            add_node!(EG, locper(i.id, t)) # demand nodes
            set_prop!(EG, locper(i.id ,t), :type, "demand")
            set_prop!(EG, locper(i.id, t), :coor, (x = i.x, y = i.y))
        end
    
        add_node!(EG, locper(i.id, ts + pH + 1)) # sink nodes
        set_prop!(EG, locper(i.id, ts + pH + 1), :type, "sink")
        set_prop!(EG, locper(i.id, ts + pH + 1), :coor, (x = i.x, y = i.y))
    end

    for t in ts:ts + pH
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
        for r in eachrow(trayek)
            if t + 1 <= ts + pH
                u = locper(r.u, t)
                v = locper(r.v, t + 1)
                k = add_arc!(EG, u, v)
                set_props!(EG, Arc(u, v, k),
                    Dict(
                        :Q => r.Q,
                        :cpeti => r.cpeti,
                        :cjarak => haversine(EG[u][:coor], EG[v][:coor], 6372) * r.cjarak,
                        :moda => r.moda,
                        :type => "transport"
                    )
                )
            end
        end
    end

    return EG
end

"""
    buildModel(expanded_graph, demands, stock)
takes in the graph and extracted demands and also stock to create a mathematical model.
"""
function buildModel(EG::MultiDigraph{locper}, demand::DataFrame, stock::DataFrame)
    m = Model()

    # demand and stock as reference
    gdf_demand = groupby(demand, [:id, :periode, :pecahan])
    gdf_stock = groupby(stock, [:id, :pecahan])

    # set definitions
    pecahan = unique(demand.pecahan)
    
    sink_nodes = filter_nodes(EG, :type, "sink")
    stock_nodes = filter_nodes(EG, :type, "stock")
    demand_nodes = filter_nodes(EG, :type, "demand")
    
    holdover_arcs = filter_nodes(EG, :type, "holdover")
    transport_arcs = filter_nodes(EG, :type, "transport")
    all_arcs = arcs(EG)
    
    # model definition
    @variable(m, 0 <= flow[a = all_arcs, p = pecahan])
    @variable(m, 0 <= trip[a = all_arcs, p = pecahan], Int)
    @variable(m, 0 <= sink[n = sink_nodes, p = pecahan])

    @constraint(m, stock_bal[n = stock_nodes, p = pecahan],
        
    )

    @constraint(m, demand_bal[n = demand_nodes],

    )

    @constraint(m, sink_bal[n = sink_nodes],

    )

    @constraint(m, inv_cap[a = holdover_arcs],

    )

    @constraint(m, trans_cap[a = transport_arcs],
        
    )

    @objective(m, Min,

    )

    return m
end
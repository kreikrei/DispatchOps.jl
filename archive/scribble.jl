using Revise
using DispatchOps
using DataFrames, Query, JuMP

#= SIM INPUT
    1. khazanah (dr readData)
    2. demand estim (dr readData)
    3. demand realization (bikin generator)
    4. initial stock (dr readData)
    5. trayek used (dr readData)
=#
khazanah, demand, init, trayek = readData("/home/kreiton/.julia/dev/DispatchOps/data");

# SIM INPUT (demand realization)
demand_realization = DataFrame(
    id = demand.id,
    periode = demand.periode,
    pecahan = demand.pecahan,
    value = demand.value .+ rand([-5,5])
)

# SIM ACCUMULATOR - INVENTORY
inventory = DataFrame(
    id = String[], 
    periode = Int[], 
    pecahan = String[], 
    value = Float64[]
)
append!(inventory, 
    DataFrame(
        id = init.id,
        periode = 0,
        pecahan = init.pecahan,
        value = init.value
    )
)

# SIM ACCUMULATOR - DISPATCH QUEUE


# SIM ACCUMULATOR - EXECUTED DISPATCH


# SIM PARAM
pH = 6
rH = 1
gap = 0.2

# SIM START
t = 0

stock = filter(p -> p.periode == t, inventory)
estim = filter(p -> p.periode >= t + 1 && p.periode <= t + pH, demand)

EG = buildGraph(khazanah, trayek, t, pH)
model = buildModel(EG, estim, stock)
optimizeModel!(model, gap = gap)

plannedDispatch = MetaDigraph{locper}()
for a in filter_arcs(EG, :type, "transport")
    v = value.(model[:flow][a,:]) |> sum
    if v > 0
        add_arc!(plannedDispatch, a)
        set_props!(plannedDispatch, a, EG[a])
        set_props!(plannedDispatch, a,
            Dict(
                :flow => Dict(
                    p => value(model[:flow][a,p]) 
                    for p in model[:flow][a,:].axes[1]
                ),
                :aggr => v,
                :trip => value(model[:trip][a]) |> round
            )
        )
    end
end

executedDispatch = MetaDigraph{locper}()
for a in filter(p -> src(p).per == t, arcs(plannedDispatch) |> collect)
    add_arc!(executedDispatch, a)
    set_props!(executedDispatch, a, plannedDispatch[a])
end

# TRANSPORT EXECUTION - BEGIN WITH EMPTY DF FOR NEXT PERIOD INV
new_stock = DataFrame(
    id = stock.id,
    periode = t + 1,
    pecahan = stock.pecahan,
    value = stock.value
)
new_stock

# TRANSPORT EXECUTION - EXECUTE ALL DISPATCH
for a in arcs(executedDispatch)
    for p in keys(executedDispatch[a][:flow])
        # stock reduction for source nodes
        new_stock[
            new_stock.id .== src(a).loc .&& 
            new_stock.periode .== src(a).per + 1 .&& 
            new_stock.pecahan .== p,:value
        ] .-= executedDispatch[a][:flow][p]
        # stock addition for target nodes
        new_stock[
            new_stock.id .== tgt(a).loc .&&
            new_stock.periode .== tgt(a).per .&&
            new_stock.pecahan .== p, :value
        ] .+= executedDispatch[a][:flow][p]
    end
end
new_stock

# DEMAND REALIZATION 
realdemand = filter(p -> p.periode == t + 1, demand_realization)
for r in eachrow(realdemand)
    new_stock[
        new_stock.id .== r.id .&&
        new_stock.periode .== r.periode .&&
        new_stock.pecahan .== r.pecahan, :value
    ] .= max(0, new_stock[
        new_stock.id .== r.id .&&
        new_stock.periode .== r.periode .&&
        new_stock.pecahan .== r.pecahan, :value
    ][1] - r.value)
end

append!(inventory, new_stock)

# MOVE FORWARD TIMESTEP
t += 1
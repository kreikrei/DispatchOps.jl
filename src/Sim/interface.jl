using Revise
using DispatchOps
using CSV, DataFrames
using JuMP
using GraphViz

# LIBRARIES

mutable struct Libraries
    khazanah::DataFrame
    trayek::DataFrame
    init_stock::DataFrame
    demand_forecast::DataFrame
    demand_realization::DataFrame
end

Libraries() = Libraries(
    DataFrame(
        id = String[], name = String[], x = Float64[], y = Float64[], 
        Q = Int[], cpeti = Float64[], cjarak = Float64[], 
        transit = Int[]
    ), # khazanah cols
    DataFrame(
        u = String[], v = String[], moda = String[],
        Q = Int[], cpeti = Float64[], cjarak = Float64[], 
        transit = Int[]
    ), # final trayek cols
    DataFrame(
        id = String[], pecahan = String[], value = Float64[]
    ), # init_stock
    DataFrame(
        id = String[], periode = Int[], pecahan = String[], value = Float64[]
    ), # demand forecast cols
    DataFrame(
        id = String[], periode = Int[], pecahan = String[], value = Float64[]
    ) # demand realization cols
)

function Libraries(path_to_lib::String, complete_trayek::Bool = true)
    to_return = Libraries()

    demand_forecast = CSV.read(joinpath(path_to_lib,"demand.csv"), DataFrame)
    khazanah = CSV.read(joinpath(path_to_lib,"khazanah.csv"), DataFrame)
    trayek = CSV.read(joinpath(path_to_lib,"trayek.csv"), DataFrame)
    stock = CSV.read(joinpath(path_to_lib,"stock.csv"), DataFrame)
    moda = CSV.read(joinpath(path_to_lib,"moda.csv"), DataFrame)
    
    if complete_trayek
        append!(trayek, DataFrame(u = trayek.v, v = trayek.u, moda = trayek.moda))
        unique!(trayek)
    end

    append!(to_return.khazanah, khazanah)
    append!(to_return.trayek, unique(innerjoin(trayek, moda, on = :moda => :name)))
    append!(to_return.demand_forecast, demand_forecast)
    append!(to_return.init_stock, stock)

    return to_return
end

function Base.show(io::IO, libs::Libraries)
    khazanah_stat = "Khazanah with $(nrow(libs.khazanah)) vault entry."

    trayek_stat = "Trayek with $(nrow(libs.trayek)) trayek entry."

    init_stock_stat = "Initial stock (t = 0) of \
    $(length(unique(libs.init_stock.id))) vault with \
    $(length(unique(libs.init_stock.pecahan))) pecahan."

    demand_forecast_stat = "Demand Forecast of \
    $(length(unique(libs.demand_forecast.id))) vault \
    for $(length(unique(libs.demand_forecast.periode))) periode \
        with $(length(unique(libs.demand_forecast.pecahan))) pecahan."

    demand_realization_stat = "Demand Realization of \
    $(length(unique(libs.demand_realization.id))) vault \
    for $(length(unique(libs.demand_realization.periode))) periode \
        with $(length(unique(libs.demand_realization.pecahan))) pecahan."

    print(io, 
        "System Libraries:\n$(khazanah_stat) \n$(trayek_stat) \n$(init_stock_stat) \n$(demand_forecast_stat) \n$(demand_realization_stat)"
    )
end

# STATES

mutable struct States
    current_stock::DataFrame
    dispatch_queue::MetaDigraph{locper}
end

States() = States(
    DataFrame(id = String[], pecahan = String[], value = Float64[]),
    MetaDigraph{locper}()
)

function Base.show(io::IO, states::States)
    current_stock_stat = "Current Stock of \
    $(length(unique(states.current_stock.id))) vault \
    with $(length(unique(states.current_stock.pecahan))) pecahan."

    dispatch_queue_stat = "Dispatch Queue with \
    $(length(arcs(states.dispatch_queue))) trayek entry."

    print(io, 
        "System States:\n$(current_stock_stat)\n$(dispatch_queue_stat)"
    )
end

# ACCUMULATORS

mutable struct Accumulators
    executed_dispatch::MetaDigraph{locper}
    inventory_levels::DataFrame
    demand_fulfillment::DataFrame
end

Accumulators() = Accumulators(
    MetaDigraph{locper}(),
    DataFrame(
        id = String[],
        periode = Int[],
        pecahan = String[],
        value = Float64[]
    ),
    DataFrame(
        id = String[],
        periode = Int[],
        pecahan = String[],
        value = Float64[]
    )
)

function Base.show(io::IO, accumulators::Accumulators)
    executed_dispatch_stat = "Executed Dispatch with \
    $(accumulators.executed_dispatch.core.na) trayek entry."

    inventory_levels_stat = "Inventory Levels of \
    $(length(unique(accumulators.inventory_levels.id))) vault \
    for $(length(unique(accumulators.inventory_levels.periode))) periode \
        with $(length(unique(accumulators.inventory_levels.pecahan))) pecahan."

    demand_fulfillment_stat = "Demand Fulfillment of \
    $(length(unique(accumulators.demand_fulfillment.id))) vault \
    for $(length(unique(accumulators.demand_fulfillment.periode))) periode \
        with $(length(unique(accumulators.demand_fulfillment.pecahan))) pecahan."

    print(io, 
        "System Accumulators:\n$(executed_dispatch_stat)\n$(inventory_levels_stat)\n$(demand_fulfillment_stat)"
    )
end

# CONSTANTS

mutable struct Constants
    T::Int
    GAP::Float64
end

Base.show(io::IO, constants::Constants) = print(io,
    "System Constants: \nPlanning Horizon of $(constants.T). \
    \nRolling Horizon of 1. \n$(constants.GAP) MIPGap."
)

# per-scheduling-an events nih gimana ya
# atau mungkin bikin plan!(), transport!(), dan execute!() dulu kali ya

"""
    plan!(ts, stt, libs, cons)
1. build model and solve dispatch sequence for `cons.T` time unit ahead \
from current timestep `ts` given `stt.current_stock` \
using `libs.khazanah`, `libs.trayek`, and `libs.demand_forecast`
2. extract dispatch sequence starting from current timestep `ts` \
for 1 time unit and add it to `stt.dispatch_queue`
"""
function plan!(ts::Int, stt::States, libs::Libraries,cons::Constants)
    EG = buildGraph(libs.khazanah, libs.trayek, ts, cons.T)
    model = buildModel(EG, libs.demand_forecast, stt.current_stock)
    optimizeModel!(model, gap = cons.GAP)

    to_append = Iterators.filter(a -> 
        src(a).per >= ts && 
        tgt(a).per <= ts + 1 && 
        EG[a][:type] == "transport", 
        arcs(EG)
    )

    for a in to_append
        v = value.(model[:flow][a,:])
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
                stt.current_stock.id .== src(a).loc .&&
                stt.current_stock.pecahan .== k,
                :value
            ] .-= to_execute[a][:flow][k] # stock reduction at source
            stt.current_stock[
                stt.current_stock.id .== tgt(a).loc .&&
                stt.current_stock.pecahan .== k,
                :value
            ] .+= to_execute[a][:flow][k] # stock addition at target
        end

        add_arc!(acc.executed_dispatch, a)
        set_props!(acc.executed_dispatch, a, to_execute[a])
    end

    return nothing
end

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
                stt.current_stock.id .== r.id .&&
                stt.current_stock.pecahan .== r.pecahan,
                :value
            ] |> first
        )
        append!(fulfillment,
            DataFrame(
                id = r.id,
                periode = r.periode,
                pecahan = r.pecahan,
                value = v
            )
        )
    end

    for r in eachrow(fulfillment)
        stt.current_stock[
            stt.current_stock.id .== r.id .&&
            stt.current_stock.pecahan .== r.pecahan,
            :value
        ] .-= r.value
    end

    append!(acc.demand_fulfillment, fulfillment)
    append!(acc.inventory_levels, 
        DataFrame(
            id = stt.current_stock.id,
            periode = ts + 1,
            pecahan = stt.current_stock.pecahan,
            value = stt.current_stock.value
        )
    )

    return nothing
end

"""
    Simulation
initiating `Simulation` requires three inputs:
- libs
- cons
- terminating_timestep

at initiation, `current_timestep` will be set to zero.
init_stocks will be appended from lib to states and accumulators.
"""
mutable struct Simulation
    t::Int
    terminating_timestep::Int

    stt::States
    acc::Accumulators
    libs::Libraries
    cons::Constants

    event_queue::Vector{Function}
end

function Simulation(;terminating_timestep::Int, libs::Libraries, cons::Constants)
    t = 0

    states = States()
    accumulators = Accumulators()

    append!(states.current_stock, libs.init_stock)
    append!(accumulators.inventory_levels, 
        DataFrame(
            id = libs.init_stock.id,
            periode = t,
            pecahan = libs.init_stock.pecahan,
            value = libs.init_stock.value
        )
    )

    q = Function[]

    to_return = Simulation(
        t, terminating_timestep, 
        states, accumulators, libs, cons, 
        q
    )

    return to_return
end

plan!(sim::Simulation) = plan!(sim.t, sim.stt, sim.libs, sim.cons)
transport!(sim::Simulation) = transport!(sim.t, sim.stt, sim.acc)
fulfill!(sim::Simulation) = fulfill!(sim.t, sim.stt, sim.acc, sim.libs)

function schedule!(sim::Simulation)
    # checks the current timestep
    if sim.t < sim.terminating_timestep
        push!(sim.event_queue, plan!)
        push!(sim.event_queue, transport!)
        push!(sim.event_queue, fulfill!)
    end

    return nothing
end

# schedule will be invoked every time the timestep moves forward

function run!(sim::Simulation)
    println("running simulation")
    start = time()

    while sim.t != sim.terminating_timestep
        println("time = $(sim.t)")
        println()

        println(sim.stt)
        println()

        println(sim.acc)
        println()

        schedule!(sim)
        while !isempty(sim.event_queue)
            fn = popfirst!(sim.event_queue)
            sim |> fn
        end
        sim.t += 1
    end
    stop = time()

    println("total duration: $(stop-start)")

    return nothing
end

# DEMAND GENERATOR
include("generator.jl")
libs = Libraries("/home/kreiton/.julia/dev/DispatchOps/data/laptri", false)
libs.demand_realization = noisify_fixed(libs.demand_forecast, 0)

# INITIALIZATION
sim = Simulation(
    terminating_timestep = 2, 
    libs = libs, 
    cons = Constants(1, 0.001)
)

# RUN
run!(sim)

# COST
sim.acc.executed_dispatch

# QUALITY
fulfillment = sim.acc.demand_fulfillment

to_fulfill = filter(
    p -> 
    p.periode <= sim.terminating_timestep && 
    p.value != 0, 
    sim.libs.demand_realization
) # all non-zero demands

res = Float64[]
for r in eachrow(to_fulfill)
    n = fulfillment[
        fulfillment.id .== r.id .&& 
        fulfillment.periode .== r.periode .&& 
        fulfillment.pecahan .== r.pecahan, :value
    ] |> first
    
    push!(res, abs(n - r.value))
end # L1-norm distance

sum(res)
100 * sum(res) / sum(abs.(to_fulfill.value .- 0))

# NETWORK STRUCTURE
D = sim.acc.executed_dispatch

filename = "uniquetrayek_test"
open("./out/$filename.dot", "w") do file
    write(file, "digraph $filename {\n")
    write(file, "    splines=polyline\n")
    write(file, "    overlap=false\n")

    for r in eachrow(libs.khazanah)
        y = 6372 * 0.9982 * r.y
        x = 6372 * 0.9982 * r.x

        write(file, "    $(r.id) [\n")
        write(file, "        pos = \"$(x),$(y)!\"\n")
        write(file, "    ];\n")
    end

    for a in arcs(D)
        i = src(a).loc
        j = tgt(a).loc
        write(file, "    $i -> $j [label = \"$(D[a][:moda])\"];\n")
    end

    write(file, "}")
end

testIO = open("./out/$filename.dot")
GraphViz.load(testIO)

for a in arcs(D, :, [locper("sby",1)]) |> collect
    println(a)
    println(D[a])
end

for a in arcs(D, [locper("sby",0)], :) |> collect
    println(a)
    println(D[a])
end

filter(p -> p.id == "sby", sim.acc.inventory_levels) |> println
filter(p -> p.id == "sby" && p.periode == 1, libs.demand_realization) |> println
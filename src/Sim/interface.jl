"""
    locper
tipe data untuk node dari graf expanded. Terdiri dari khazanah dan periode.
"""
struct locper
    loc::String
    per::Int
end

show(io::IO, lp::locper) = print(io, "⟦i=$(lp.loc),t=$(lp.per)⟧")

# default dataframes - DON'T FORGET TO COPY
const stock_df_def = DataFrame(id=String[], pecahan=String[], value=Float64[])
const demand_df_def = insertcols!(stock_df_def |> copy, :id, :periode => [], after=true)

"""
    Libraries(khazanah, trayek, init_stock, demand_forecast, demand_realization)
defines the basic libraries needed to load the simulation. calling it with \
empty arguments give the default dataframes.
"""
@with_kw_noshow struct Libraries
    khazanah::DataFrame = DataFrame(
        id=String[], name=String[], x=Float64[], y=Float64[],
        Q=Int[], cpeti=Float64[], cjarak=Float64[]
    ) # khazanah cols
    trayek::DataFrame = DataFrame(
        u=String[], v=String[], moda=String[]
    ) # trayek cols
    moda::DataFrame = DataFrame(
        name=String[], Q=Int[], cpeti=Float64[], cjarak=Float64[]
    )
    init_stock::DataFrame = copy(stock_df_def)
    demand_forecast::DataFrame = copy(demand_df_def)
    demand_realization::DataFrame = copy(demand_df_def)
end

"""
    Libraries(path_to_lib; complete)
reads the files specified on `path_to_lib` and loads it into library.
if `complete = true` trayek dataframe will be turned into complete graph.
"""
function Libraries(path_to_lib::String; complete::Bool)
    to_return = Libraries()

    filenames = ["khazanah", "trayek", "demand", "stock", "moda"]
    df = Dict{String,DataFrame}()
    for f in filenames
        df[f] = CSV.read(joinpath(path_to_lib, "$f.csv"), DataFrame)

        # trayek-related adjustments
        if f == "trayek"
            if complete
                append!(df[f], DataFrame(u=df[f].v, v=df[f].u, moda=df[f].moda))
            end
            unique!(df[f])
        end
    end

    append!(to_return.trayek, df["trayek"])
    append!(to_return.moda, df["moda"])
    append!(to_return.demand_forecast, df["demand"])
    append!(to_return.khazanah, df["khazanah"])
    append!(to_return.init_stock, df["stock"])

    return to_return
end

function show(io::IO, libs::Libraries)
    khazanah_stat = "Khazanah\t\t: $(nrow(libs.khazanah)) vault entry."

    trayek_stat = "Trayek\t\t\t: $(nrow(libs.trayek)) trayek entry."

    init_stock_stat = "Initial stock (t=0)\t: \
    $(length(unique(libs.init_stock.id))) vault with \
    $(length(unique(libs.init_stock.pecahan))) pecahan."

    demand_forecast_stat = "Demand Forecast\t\t: \
    $(length(unique(libs.demand_forecast.id))) vault \
    for $(length(unique(libs.demand_forecast.periode))) periode \
        with $(length(unique(libs.demand_forecast.pecahan))) pecahan."

    demand_realization_stat = "Demand Realization\t: \
    $(length(unique(libs.demand_realization.id))) vault \
    for $(length(unique(libs.demand_realization.periode))) periode \
        with $(length(unique(libs.demand_realization.pecahan))) pecahan."

    print(io,
        "---System Libraries---\n$(khazanah_stat) \n$(trayek_stat) \n$(init_stock_stat) \n$(demand_forecast_stat) \n$(demand_realization_stat)"
    )
end

copy(l::Libraries) = Libraries(
    copy(l.khazanah),
    copy(l.trayek),
    copy(l.moda),
    copy(l.init_stock),
    copy(l.demand_forecast),
    copy(l.demand_realization)
)

"""
    States(current_stock, dispatch_queue)
defines the states that makes up the system.
"""
@with_kw_noshow mutable struct States
    current_stock::DataFrame = copy(stock_df_def)
    dispatch_queue::MetaDigraph{locper} = MetaDigraph{locper}()
end

function show(io::IO, states::States)
    current_stock_stat = "Current Stock\t: \
    $(length(unique(states.current_stock.id))) vault \
    with $(length(unique(states.current_stock.pecahan))) pecahan."

    dispatch_queue_stat = "Dispatch Queue\t: \
    $(length(arcs(states.dispatch_queue))) trayek entry."

    print(io,
        "---System States---\n$(current_stock_stat)\n$(dispatch_queue_stat)"
    )
end

isempty(s::States) = reduce(*,
    [isempty(getfield(s, f)) for f in fieldnames(typeof(s))]
)

@with_kw_noshow mutable struct Accumulators
    executed_dispatch::MetaDigraph{locper} = MetaDigraph{locper}()
    inventory_levels::DataFrame = copy(demand_df_def)
    demand_fulfillment::DataFrame = copy(demand_df_def)
end

function show(io::IO, accumulators::Accumulators)
    executed_dispatch_stat = "Executed Dispatch \t: \
    $(accumulators.executed_dispatch.core.na) trayek entry."

    inventory_levels_stat = "Inventory Levels \t: \
    $(length(unique(accumulators.inventory_levels.id))) vault \
    for $(length(unique(accumulators.inventory_levels.periode))) periode \
        with $(length(unique(accumulators.inventory_levels.pecahan))) pecahan."

    demand_fulfillment_stat = "Demand Fulfillment \t: \
    $(length(unique(accumulators.demand_fulfillment.id))) vault \
    for $(length(unique(accumulators.demand_fulfillment.periode))) periode \
        with $(length(unique(accumulators.demand_fulfillment.pecahan))) pecahan."

    print(io,
        "---System Accumulators---\n$(executed_dispatch_stat)\n$(inventory_levels_stat)\n$(demand_fulfillment_stat)"
    )
end

isempty(a::Accumulators) = reduce(*,
    [isempty(getfield(a, f)) for f in fieldnames(typeof(a))]
)

@with_kw_noshow mutable struct Params
    T::Int # terminating timstep
    H::Int # planning horizon
    GAP::Float64 = 0.2 # MIPGap
    model::Function # model generator
    fixed::Bool = false # Modifiers
    env::Gurobi.Env = Gurobi.Env()
    dist::Function = haversine
end

function show(io::IO, params::Params)
    print(io,
        "---System Params---\nT\t= $(params.T)\nH\t= $(params.H)\nGAP\t= $(params.GAP)\
        \nmodel\t= $(params.model)\nfixed\t= $(params.fixed)\ndist\t=$(params.dist)"
    )
end

copy(p::Params) = Params(
    T=copy(p.T), H=copy(p.H), GAP=copy(p.GAP), model=p.model, fixed=copy(p.fixed)
)

"""
    Simulation
initiating `Simulation` requires two inputs:
- libs
- params

at initiation, `current_timestep` will be set to zero.
init_stocks will be appended from lib to states and accumulators.
"""
@with_kw_noshow mutable struct Simulation
    # SCHEDULER
    t::Int = 0
    queue::Vector{Function} = Vector{Function}()

    # GENERATED
    stt::States = States()
    acc::Accumulators = Accumulators()

    # SEED
    libs::Libraries
    params::Params

    duration::Float64 = 0
end

function show(io::IO, sim::Simulation)
    print(io,
        "\nCURRENT TIMESTEP = $(sim.t)\n\
        \n$(sim.stt)\n\
        \n$(sim.acc)\n\
        \n$(sim.params)\n"
    )
end

@with_kw_noshow struct Experiment
    T::Int
    data_path::String
    is_complete::Bool
    noise_function::Function
    noise_range::AbstractArray
    replication::Int
    H_range::AbstractArray
    GAP_range::AbstractArray
    model_used::Function
    is_horizon_fixed::Bool
    output_path::String
    file_name::String
end

function show(io::IO, exp::Experiment)
    print(io,
        "$(
            length(exp.noise_range) * exp.replication * 
            length(exp.H_range) * length(exp.GAP_range)
        ) entry Experiment"
    )
end
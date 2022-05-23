total_cost(sim::Simulation) = fixed_cost(sim) + variable_cost(sim)

variable_cost(sim::Simulation) = sum(
    sim.acc.executed_dispatch[a][:cpeti] *
    sum(values(sim.acc.executed_dispatch[a][:flow]))
    for a in arcs(sim.acc.executed_dispatch)
)

fixed_cost(sim::Simulation) = sum(
    sim.acc.executed_dispatch[a][:cjarak] *
    sim.acc.executed_dispatch[a][:trip]
    for a in arcs(sim.acc.executed_dispatch)
)

function lost_sales(sim::Simulation)
    realization = filter(
        p -> p.periode <= sim.params.T, sim.libs.demand_realization
    )
    fulfilled = begin
        sum(abs.(sim.acc.demand_fulfillment.value)) / sum(abs.(realization.value))
    end
    return 1 - fulfilled
end

function process_experiment(exp::Experiment)
    s = DataFrame(noise=Float64[], H=Int64[], GAP=Float64[], simulation=Simulation[])
    total = length(exp.noise_range) * exp.replication *
            length(exp.H_range) * length(exp.GAP_range)

    start = time()
    for noise in exp.noise_range, N in 1:exp.replication
        l = Libraries(exp.data_path, complete=exp.is_complete)
        append!(l.demand_realization, exp.noise_function(l.demand_forecast, noise))
        for H in exp.H_range, GAP in exp.GAP_range
            p = Params(
                H=H, T=exp.T, model=exp.model_used,
                fixed=exp.is_horizon_fixed, GAP=GAP
            )
            new_sim = Simulation(libs=l, params=p)

            # exp core
            println("<---H=$(H) | noise=$(noise) | N=$(N)--->")
            initiate!(new_sim)
            run!(new_sim)

            append!(s, DataFrame(noise=noise, H=H, GAP=GAP, simulation=new_sim))
            println("Experiment $(round(nrow(s) / total * 100,digits=2))% complete.\n")
        end
    end
    stop = time()
    println("All experiments ran. Duration: $(round(stop-start, digits=2))s")

    !isdir(exp.output_path) && mkdir(exp.output_path)
    save_object(joinpath(exp.output_path, "$(exp.file_name).jld2"), s)
    println("Output saved.")

    return s
end

"""
    sensitivity_report(sim)
creates a sensitivity analysis on the objective function cost parameters \
of the planning model. `sim` must not be initiated.
"""
function sensitivity_report(sim::Simulation, p::Float64=1.0)
    base = Simulation(libs=copy(sim.libs), params=copy(sim.params))
    initiate!(base)
    run!(base)

    df = DataFrame(
        col=Symbol[],
        varmult=Vector{Float64}[],
        total_cost=Float64[],
        lost_sales=Float64[],
        Jaccard_similarity_fine=Float64[],
        Jaccard_similarity_coarse=Float64[],
        Jaccard_similarity_mild=Float64[]
    )

    append!(df, DataFrame(
        col=:base,
        varmult=[[0.0, 0.0, 0.0, 0.0]],
        total_cost=total_cost(base),
        lost_sales=lost_sales(base),
        Jaccard_similarity_fine=1,
        Jaccard_similarity_coarse=1,
        Jaccard_similarity_mild=1
    ))

    cols = [:cpeti, :cjarak]
    vars = [
        [1.0, 0.0, 0.0, 0.0],
        [0.0, 1.0, 0.0, 0.0],
        [0.0, 0.0, 1.0, 0.0],
        [0.0, 0.0, 0.0, 1.0]
    ]
    mults = [-p, p]

    for col in cols, var in vars, mult in mults
        s = Simulation(libs=copy(sim.libs), params=copy(sim.params))
        s.libs.moda[:, col] .+= mult * var
        initiate!(s)
        run!(s)
        append!(df, DataFrame(
            col=col,
            varmult=[mult * var],
            total_cost=total_cost(s),
            lost_sales=lost_sales(s),
            Jaccard_similarity_fine=fineJaccard(base, s),
            Jaccard_similarity_coarse=coarseJaccard(base, s),
            Jaccard_similarity_mild=mildJaccard(base, s)
        ))
    end

    return df
end

"""
    fineJaccard(a,b)
compares arc by arc in executed dispatch without any modification.
"""
function fineJaccard(a::Simulation, b::Simulation)
    A = arcs(a.acc.executed_dispatch) |> collect
    B = arcs(b.acc.executed_dispatch) |> collect

    combined = union(A, B)
    intersected = intersect(A, B)
    return length(intersected) / length(combined)
end

"""
    mildJaccard(a,b)
compares point pairs and its modes in executed dispatch.
"""
function mildJaccard(a::Simulation, b::Simulation)
    GA = MetaDigraph{String}()
    GB = MetaDigraph{String}()

    for a in arcs(a.acc.executed_dispatch)
        add_arc!(GA, src(a).loc, tgt(a).loc, key(a))
    end
    for b in arcs(b.acc.executed_dispatch)
        add_arc!(GB, src(b).loc, tgt(b).loc, key(b))
    end

    combined = union(arcs(GA), arcs(GB))
    intersected = intersect(arcs(GA), arcs(GB))
    return length(intersected) / length(combined)
end

"""
    coarseJaccard(a,b)
compares only location pairs in executed dispatch.
"""
function coarseJaccard(a::Simulation, b::Simulation)
    GA = MetaDigraph{String}()
    GB = MetaDigraph{String}()

    for a in arcs(a.acc.executed_dispatch)
        add_arc!(GA, src(a).loc, tgt(a).loc, 1)
    end
    for b in arcs(b.acc.executed_dispatch)
        add_arc!(GB, src(b).loc, tgt(b).loc, 1)
    end

    combined = union(arcs(GA), arcs(GB))
    intersected = intersect(arcs(GA), arcs(GB))
    return length(intersected) / length(combined)
end

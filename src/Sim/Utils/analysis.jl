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

function process(exp::Experiment)
    s = DataFrame(noise=Float64[], H=Int64[], GAP=Float64[], simulation=Simulation[])
    total = length(exp.noise_range) * exp.replication *
            length(exp.H_range) * length(exp.GAP_range)

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

    !isdir(output_path) && mkdir(output_path)
    save_object(joinpath(output_path, "$(exp.file_name).jld2"), s)

    return s
end

# TODO #52 sensitivity analysis function
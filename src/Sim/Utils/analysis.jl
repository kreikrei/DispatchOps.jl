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

function network_structure(sim::Simulation)

end
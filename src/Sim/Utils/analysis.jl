function total_cost(sim::Simulation)

end

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
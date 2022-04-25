function initiate!(sim::Simulation)
    append!(sim.stt.current_stock, sim.libs.init_stock)
    append!(sim.acc.inventory_levels,
        insertcols!(sim.libs.init_stock |> copy, :id, :periode => fill(sim.t), after=true)
    )

    return sim
end

function schedule!(sim::Simulation)
    # checks the current timestep
    sim.t < sim.params.T && begin
        push!(sim.queue, plan!)
        push!(sim.queue, transport!)
        push!(sim.queue, fulfill!)
    end

    return nothing
end

function run!(sim::Simulation)
    (isempty(sim.stt) || isempty(sim.acc)) && error("Simulation Uninitiated!")

    println("Starting Simulation")
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
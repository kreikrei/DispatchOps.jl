function initiate!(sim::Simulation)
    append!(sim.stt.current_stock, sim.libs.init_stock)
    append!(sim.acc.inventory_levels,
        insertcols!(sim.libs.init_stock |> copy, :id, :periode => fill(sim.t), after=true)
    )

    return sim
end

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
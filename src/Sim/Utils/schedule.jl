function initiate!(sim::Simulation)
    append!(sim.stt.current_stock, sim.libs.init_stock)
    append!(sim.acc.inventory_levels,
        insertcols!(sim.libs.init_stock |> copy, :id, :periode => fill(sim.t), after=true)
    )

    return sim
end

function schedule!(sim::Simulation)
    sim.t < sim.params.T && begin
        # push!(sim.queue, plan!)
        # push!(sim.queue, transport!)
        # push!(sim.queue, fulfill!)
    end

    return nothing
end

function run!(sim::Simulation)
    (isempty(sim.stt) || isempty(sim.acc)) && error("Simulation uninitiated!")

    println("Starting simulation")
    start = time()
    while sim.t < sim.params.T
        println(sim)
        schedule!(sim)
        while !isempty(sim.queue)
            fn = popfirst!(sim.queue)
            sim |> fn
        end
        sim.t += 1
    end
    stop = time()

    println("Simulation stopped. Total duration: $(stop-start)")

    return nothing
end
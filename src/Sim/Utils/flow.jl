function reset!(sim::Simulation)
    sim.t = 0
    sim.queue = Vector{Function}()

    empty!(sim.stt.current_stock)
    empty!(sim.stt.dispatch_queue)

    empty!(sim.acc.executed_dispatch)
    empty!(sim.acc.inventory_levels)
    empty!(sim.acc.demand_fulfillment)

    return sim
end

function initiate!(sim::Simulation; reset::Bool=true)
    reset && reset!(sim) # reset simulation
    if (isempty(sim.stt) || isempty(sim.acc))
        append!(sim.stt.current_stock, sim.libs.init_stock)
        append!(sim.acc.inventory_levels,
            insertcols!(
                sim.libs.init_stock |> copy, :id, :periode => fill(sim.t), after=true
            )
        )
    else
        println("Simulation already initiated!")
    end
    return sim
end

function schedule!(sim::Simulation)
    sim.t < sim.params.T && begin
        push!(sim.queue, plan!)
        push!(sim.queue, transport!)
        push!(sim.queue, fulfill!)
    end

    return nothing
end

function run!(sim::Simulation)
    (isempty(sim.stt) || isempty(sim.acc)) && error("Simulation uninitiated!")

    println("Starting simulation")
    start = time()
    while sim.t < sim.params.T
        println(sim) # verbose
        schedule!(sim)
        while !isempty(sim.queue)
            fn = popfirst!(sim.queue)
            sim |> fn
            # add ability to change to fixed horizon
        end
        sim.t += 1
    end
    stop = time()

    println("Simulation stopped. Total duration: $(stop-start)")

    return nothing
end
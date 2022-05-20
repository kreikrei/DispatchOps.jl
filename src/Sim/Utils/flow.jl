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
    isempty(sim.libs.demand_realization) && error("Demand realization can't be empty!")

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

function run!(sim::Simulation; verbose::Bool=false)
    (isempty(sim.stt) || isempty(sim.acc)) && error("Simulation uninitiated!")

    println("Starting simulation. Timestep = $(sim.t)")
    start = time()
    while sim.t < sim.params.T
        if sim.params.fixed
            sim.params.H = min(sim.params.H, sim.params.T - sim.t)
        end
        verbose && println(sim) # verbose
        schedule!(sim)
        while !isempty(sim.queue)
            fn = popfirst!(sim.queue)
            sim |> fn
        end
        sim.t += 1
        println("Current timestep = $(sim.t).\
        Time elapsed: $(round(time() - start, digits=2))s")
    end
    stop = time()

    sim.duration += stop - start
    println("Simulation stopped. Total duration: $(round(sim.duration, digits=2))s")

    return nothing
end
using DispatchOps
using Test
@testset "DispatchOps.jl" begin
    @testset "zero demand" begin
        # ZERO
        data_path = "/home/kreiton/.julia/dev/DispatchOps/data/dummy/zero"
        T = 1
        H = 1
        is_complete = true
        dist = Euclidean()
        model = standard_model

        l = Libraries(data_path, complete=is_complete)
        p = Params(H=H, T=T, model=model, dist=dist)
        append!(l.demand_realization, noisify_fixed(l.demand_forecast, 0))

        s = Simulation(libs=l, params=p)
        initiate!(s)
        run!(s)

        @test isempty(s.acc.executed_dispatch)
    end

    @testset "break bulk" begin
        data_path = "/home/kreiton/.julia/dev/DispatchOps/data/dummy/break"
        T = 1
        H = 1
        is_complete = true
        dist = Euclidean()
        model = standard_model

        l = Libraries(data_path, complete=is_complete)
        p = Params(H=H, T=T, model=model, dist=dist)
        append!(l.demand_realization, noisify_fixed(l.demand_forecast, 0))

        s = Simulation(libs=l, params=p)
        initiate!(s)
        run!(s)

        answer = MetaDigraph{DispatchOps.Sim.locper}()
        add_arc!(answer, DispatchOps.Sim.locper("A", 0), DispatchOps.Sim.locper("B", 1))
        add_arc!(answer, DispatchOps.Sim.locper("A", 0), DispatchOps.Sim.locper("C", 1))
        add_arc!(answer, DispatchOps.Sim.locper("A", 0), DispatchOps.Sim.locper("D", 1))
        add_arc!(answer, DispatchOps.Sim.locper("A", 0), DispatchOps.Sim.locper("E", 1))
        for a in arcs(answer)
            set_prop!(answer, a, :flow, Dict("NN" => 250))
            set_prop!(answer, a, :trip, 1)
        end
        @test collect(arcs(s.acc.executed_dispatch)) == collect(arcs(answer))
        if collect(arcs(s.acc.executed_dispatch)) == collect(arcs(answer))
            for a in arcs(answer)
                @test answer[a][:flow] == s.acc.executed_dispatch[a][:flow]
                @test answer[a][:trip] == s.acc.executed_dispatch[a][:trip]
            end
        end
    end

    @testset "consolidate" begin
        data_path = "/home/kreiton/.julia/dev/DispatchOps/data/dummy/consolidate/"
        T = 1
        H = 1
        is_complete = true
        dist = Euclidean()
        model = standard_model

        l = Libraries(data_path, complete=is_complete)
        p = Params(H=H, T=T, model=model, dist=dist)
        append!(l.demand_realization, noisify_fixed(l.demand_forecast, 0))

        s = Simulation(libs=l, params=p)
        initiate!(s)
        run!(s)

        add_arc!(answer, DispatchOps.Sim.locper("B", 0), DispatchOps.Sim.locper("A", 1))
        add_arc!(answer, DispatchOps.Sim.locper("C", 0), DispatchOps.Sim.locper("A", 1))
        add_arc!(answer, DispatchOps.Sim.locper("D", 0), DispatchOps.Sim.locper("A", 1))
        add_arc!(answer, DispatchOps.Sim.locper("E", 0), DispatchOps.Sim.locper("A", 1))
        for a in arcs(answer)
            set_prop!(answer, a, :flow, Dict("NN" => 250))
            set_prop!(answer, a, :trip, 1)
        end
        @test collect(arcs(s.acc.executed_dispatch)) == collect(arcs(answer))
        if collect(arcs(s.acc.executed_dispatch)) == collect(arcs(answer))
            for a in arcs(answer)
                @test answer[a][:flow] == s.acc.executed_dispatch[a][:flow]
                @test answer[a][:trip] == s.acc.executed_dispatch[a][:trip]
            end
        end
    end
end

# TODO #55 test case for verification -> 1 - 1 + front loading

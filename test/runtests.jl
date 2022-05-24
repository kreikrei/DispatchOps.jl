using DispatchOps
using Test

@testset "DispatchOps.jl" begin
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

    # TODO #53 test case for verification -> M - 1 + front loading
    # TODO #54 test case for verification -> 1 - M + front loading
    # TODO #55 test case for verification -> 1 - 1 + front loading
end

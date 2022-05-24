using Revise
using DispatchOps

test_set = "nearest"
const data_path = "/home/kreiton/.julia/dev/DispatchOps/data/dummy/$test_set"
const T = 1
const H = 1
const is_complete = true
const dist = Euclidean()
const model = standard_model

l = Libraries(data_path, complete=is_complete)
p = Params(H=H, T=T, model=model, dist=dist)
append!(l.demand_realization, noisify_fixed(l.demand_forecast, 0))

s = Simulation(libs=l, params=p)
initiate!(s)
run!(s)

s.acc.executed_dispatch |> arcs |> collect
s.acc.inventory_levels
total_cost(s)
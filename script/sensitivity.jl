using Revise
using DispatchOps
using JLD2

# analyze on H_range = 1:3
const data_path = "/home/kreiton/.julia/dev/DispatchOps/data/origin"
const is_complete = true
const T = 12
const model = hard_holdover_model
const is_horizon_fixed = true

l = Libraries(data_path, complete=is_complete)
append!(l.demand_realization, noisify_fixed(l.demand_forecast, 0))
params = [Params(H=h, T=T, model=model, fixed=is_horizon_fixed) for h in 1:3]

for p in params
    s = Simulation(libs=copy(l), params=copy(p))
    df = sensitivity_report(s)
    save_object("/home/kreiton/.julia/dev/DispatchOps/out/SensitivityReport-H$(p.H)", df)
end
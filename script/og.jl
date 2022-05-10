using DispatchOps
using JLD2
using DataFrames

const model_used = hard_holdover_model
const T = 12
const H_to_test = 1:5
const noise_to_test = 0:10:100

# libs complete = true
# sim fixed = true

s = DataFrame(
    H=Int[],
    noise=Int[],
    simulation=Simulation[]
)

for h in H_to_test, noise in noise_to_test
    l = Libraries("/home/kreiton/.julia/dev/DispatchOps/data/og", complete=true)
    l.demand_realization = noisify_fixed(l.demand_forecast, noise)
    new_sim = Simulation(libs=l, params=Params(H=h, T=T, model=model_used), fixed=true)
    append!(s, DataFrame(H=h, noise=noise, simulation=new_sim))
end


initiate!.(s.simulation)
run!.(s.simulation)

save_object("og.jld2", s)
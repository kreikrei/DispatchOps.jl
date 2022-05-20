# TRAYEK | FIXED-END | NOISE_FUNCTION |  GAP
#    0   |     1     |       0        |  0.2
using Revise
using DispatchOps
using JLD2
using DataFrames

const T = 12
const path = "/home/kreiton/.julia/dev/DispatchOps/data/origin"
const is_complete = true
const noise_function = noisify_fixed
const noise_range = 0:10:50
const replication = 1:5

const H_range = 1:8
const GAP_range = [0.2]
const model_used = hard_holdover_model
const is_horizon_fixed = true

const output_path = "/home/kreiton/.julia/dev/DispatchOps/out"

s = DataFrame(
    noise=Int[],
    H=Int64[],
    GAP=Float64[],
    N=Int64[],
    simulation=Simulation[]
)

for noise in noise_range, N in replication
    l = Libraries(path, complete=is_complete)
    append!(l.demand_realization, noise_function(l.demand_forecast, noise))
    for H in H_range, GAP in GAP_range
        p = Params(H=H, T=T, model=model_used, fixed=is_horizon_fixed, GAP=GAP)
        new_sim = Simulation(libs=l, params=p)
        append!(s, DataFrame(noise=noise, H=H, GAP=GAP, N=N, simulation=new_sim))
    end
end

for r in eachrow(s)
    println("<---H=$(r.H) | noise=$(r.noise) | N=$(r.N)--->")
    initiate!(r.simulation)
    run!(r.simulation)

    # logger part
    progress = rownumber(r) / nrow(s)
    println("Experiment $(round(progress*100,digits=2))% complete.\n")
end

!isdir(output_path) && mkdir(output_path)
save_object(joinpath(output_path, "exp010.jld2"), s)
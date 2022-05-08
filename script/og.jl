using DispatchOps
using JLD2

const model_used = hard_holdover_model
const T = 12
const H_to_test = 1:3

# libs complete = true
# sim fixed = false

l = Libraries("/home/kreiton/.julia/dev/DispatchOps/data/og", complete=true)
l.demand_realization = noisify_fixed(l.demand_forecast, 0)

s = Vector{Simulation}()
for h in H_to_test
    new_s = Simulation(
        libs=l, params=Params(H=h, T=T, model=model_used), fixed=false
    )
    push!(s, new_s)
end

initiate!.(s)
run!.(s)

save_object("og.jld2", s)
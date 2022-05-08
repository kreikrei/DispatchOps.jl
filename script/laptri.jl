using DispatchOps

const T = 12

l = Libraries("/home/kreiton/.julia/dev/DispatchOps/data/laptri", complete=false)
l.demand_realization = noisify_fixed(l.demand_forecast, 0)

s = Vector{Simulation}()
H_to_test = 1:12
for h in H_to_test
    new_s = Simulation(
        libs=l, params=Params(H=h, T=T, model=soft_holdover_model), fixed=false
    )
    push!(s, new_s)
end

initiate!.(s)
run!.(s)
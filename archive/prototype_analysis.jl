# COST
s.acc.executed_dispatch

# QUALITY
fulfillment = s.acc.demand_fulfillment

to_fulfill = filter(
    p ->
        p.periode <= s.terminating_timestep &&
            p.value != 0,
    s.libs.demand_realization
) # all non-zero demands

res = Float64[]
for r in eachrow(to_fulfill)
    n = fulfillment[
        fulfillment.id.==r.id.&&fulfillment.periode.==r.periode.&&fulfillment.pecahan.==r.pecahan, :value
    ] |> first

    push!(res, abs(n - r.value))
end # L1-norm distance

sum(res)
100 * sum(res) / sum(abs.(to_fulfill.value .- 0))

for a in arcs(D, :, [locper("sby", 1)]) |> collect
    println(a)
    println(D[a])
end

for a in arcs(D, [locper("sby", 0)], :) |> collect
    println(a)
    println(D[a])
end

filter(p -> p.id == "sby", sim.acc.inventory_levels) |> println
filter(p -> p.id == "sby" && p.periode == 1, libs.demand_realization) |> println
using CSV
using DataFrames
using Gadfly
using JLD2
using Statistics
using AxisArrays
using DispatchOps
using Colors
using Compose

suboptim = load_object("/home/kreiton/.julia/dev/DispatchOps/out/suboptim.jld2")
approx = load_object("/home/kreiton/.julia/dev/DispatchOps/out/approx.jld2")
optim = load_object("/home/kreiton/.julia/dev/DispatchOps/out/optim.jld2")

gapmod = vcat(suboptim, approx, optim)

duration(s::Simulation) = s.duration
peti_transported(s::Simulation, pecahand::Dict) = AxisArray(
    [
        s.acc.executed_dispatch[a][:flow][k]
        for (k, v) in pecahand, a in arcs(s.acc.executed_dispatch)
    ], pecahan=keys(pecahand), trayek=arcs(s.acc.executed_dispatch)
)

pecahan = CSV.read("data/.pecahan.csv", DataFrame)
const pecahand = Dict(
    pecahan.id .=> [
        (nilai=p.nilai, konversi=p.konversi) for p in eachrow(pecahan)
    ]
)

transform!(gapmod,
    :simulation => ByRow(x -> total_cost(x)) => :total_cost
)

transform!(gapmod,
    :simulation => ByRow(x -> duration(x)) => :duration
)

plot(gapmod, x=:H, y=:total_cost, color=:GAP, Geom.point, Geom.line)

plot(gapmod, x=:H, y=:duration, color=:GAP, Geom.point, Geom.line, Scale.y_log10)
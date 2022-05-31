using CSV
using DataFrames
# using Gadfly
using JLD2
using Statistics
using DispatchOps
# using Colors
# using Compose
using CairoMakie
import Makie: Makie.wong_colors

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
    :simulation => ByRow(x -> total_cost(x) * 1000) => :total_cost
)

transform!(gapmod,
    :simulation => ByRow(x -> duration(x) / x.params.T) => :duration
)


fig = Figure()
formatmiliar(x) = ["$(n/1e9)" for n in x]
ax1 = Axis(fig[1, 1],
    xticks=(unique(gapmod.H), string.(gapmod.H |> unique)),
    ytickformat=formatmiliar,
    yminorticksvisible=true,
    yminorticks=IntervalsBetween(5),
    title="Biaya Total Layanan Terhadap Panjang Horizon Perencanaan (Noise=0)",
    ylabel="Total Biaya (Miliar Rupiah)",
    xlabel="Panjang Horizon Perencanaan (H)"
)

for gap in unique(gapmod.GAP)
    scatterlines!(ax1, unique(gapmod.H), gapmod[gapmod.GAP.==gap, :total_cost], colorrange=wong_colors())
end

fig
ax2 = Axis(fig[2, 1],
    xticks=(unique(gapmod.H), string.(gapmod.H |> unique)),
    yscale=log10,
    yminorticksvisible=true,
    yminorticks=IntervalsBetween(3),
    title="Rerata Durasi Penyelesaian Terhadap Panjang Horizon Perencanaan (Noise=0)",
    ylabel="Rerata Durasi Penyelesaian (dtk)",
    xlabel="Panjang Horizon Perencanaan (H)"
)

for gap in unique(gapmod.GAP)
    scatterlines!(ax2, unique(gapmod.H), gapmod[gapmod.GAP.==gap, :duration], colorrange=wong_colors())
end

labels = string.(unique(gapmod.GAP) .* 100) .* "%"
elements = [PolyElement(polycolor=wong_colors()[i]) for i in 1:length(labels)]
title = "Opt. Gap"
Legend(fig[1:2, 2], elements, labels, title, titlehalign=:left)

fig

save("/home/kreiton/.julia/dev/DispatchOps/out/horizonGAP.svg", fig)

#=p1 = plot(
    gapmod,
    x=:H,
    y=:total_cost,
    color=:GAP,
    Geom.point,
    Geom.line,
    Scale.x_discrete,
    Scale.color_discrete_manual(convert(Vector{Color}, wong_colors())...),
    Guide.ylabel("Total Biaya (Rupiah)")
)

p2 = plot(
    gapmod,
    x=:H,
    y=:duration,
    color=:GAP,
    Geom.point,
    Geom.line,
    Scale.y_log10,
    Scale.x_discrete,
    Scale.color_discrete_manual(convert(Vector{Color}, wong_colors())...)
)

import Cairo, Fontconfig
vstack(p1, p2)=#
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

peti_transported(s::Simulation) = sum(
    sum(
        s.acc.executed_dispatch[a][:flow][k]
        for (k, v) in s.acc.executed_dispatch[a][:flow]
    ) for a in arcs(s.acc.executed_dispatch)
)

suboptim = load_object("/home/kreiton/.julia/dev/DispatchOps/out/suboptim.jld2")
approx = load_object("/home/kreiton/.julia/dev/DispatchOps/out/approx.jld2")
optim = load_object("/home/kreiton/.julia/dev/DispatchOps/out/optim.jld2")

gapmod = vcat(suboptim, approx, optim)

duration(s::Simulation) = s.duration

transform!(gapmod,
    :simulation => ByRow(x -> total_cost(x) * 1000) => :total_cost
)

transform!(gapmod,
    :simulation => ByRow(x -> duration(x) / x.params.T) => :duration
) # average solve time

transform!(gapmod,
    :simulation => ByRow(x -> peti_transported(x)) => :peti_transported
)

transform!(gapmod,
    :simulation => ByRow(x -> total_cost(x) * 1e3 / peti_transported(x)) => :cost_per_unit_shipped
)


# FIRST FIGURE
fig1 = Figure()
formatmiliar(x) = ["$(n/1e9)" for n in x]
ax1 = Axis(fig1[1, 1],
    xticks=(unique(gapmod.H), string.(gapmod.H |> unique)),
    ytickformat=formatmiliar,
    yminorticksvisible=true,
    yminorticks=IntervalsBetween(5),
    title="Biaya Total Layanan Terhadap Panjang Horizon Perencanaan (Noise=0)",
    ylabel="Total Biaya (Miliar Rupiah)",
    xlabel="Panjang Horizon Perencanaan (H)"
)

for gap in unique(gapmod.GAP)
    scatterlines!(ax1, unique(gapmod.H), gapmod[gapmod.GAP.==gap, :total_cost], colorrange=wong_colors(), label="$(gap*100)%")
end

fig1
formatribu(x) = ["$(n/1e3)" for n in x]
ax2 = Axis(fig1[2, 1],
    xticks=(unique(gapmod.H), string.(gapmod.H |> unique)),
    ytickformat=formatribu,
    yminorticksvisible=true,
    yminorticks=IntervalsBetween(5),
    title="Total Peti Terkirim Terhadap Panjang Horizon Perencanaan (Noise=0)",
    ylabel="Total Peti Terkirim (Ribu Peti)",
    xlabel="Panjang Horizon Perencanaan (H)"
)

for gap in unique(gapmod.GAP)
    scatterlines!(ax2, unique(gapmod.H), gapmod[gapmod.GAP.==gap, :peti_transported], colorrange=wong_colors(), label="$(gap*100)%")
end

labels1 = string.(unique(gapmod.GAP) .* 100) .* "%"
elements1 = [PolyElement(polycolor=wong_colors()[i]) for i in 1:length(labels1)]
title1 = "Opt. Gap"
Legend(fig1[1:2, 2], elements1, labels1, title1, titlehalign=:left)
fig1

fig2 = Figure()
ax3 = Axis(fig2[1, 1],
    xticks=(unique(gapmod.H), string.(gapmod.H |> unique)),
    ytickformat=formatribu,
    yminorticksvisible=true,
    yminorticks=IntervalsBetween(5),
    title="Biaya per Peti Terkirim Terhadap Panjang Horizon Perencanaan (Noise=0)",
    ylabel="Biaya per Peti Terkirim (Ribu Rupiah)",
    xlabel="Panjang Horizon Perencanaan (H)"
)

for gap in unique(gapmod.GAP)
    scatterlines!(ax3, unique(gapmod.H), gapmod[gapmod.GAP.==gap, :cost_per_unit_shipped], colorrange=wong_colors(), label="$(gap*100)%")
end

axislegend("Opt. Gap", position=:lb)
fig2

save("/home/kreiton/.julia/dev/DispatchOps/out/horizonGAP.svg", fig1)
save("/home/kreiton/.julia/dev/DispatchOps/out/horizonGAPcostperunit.svg", fig2)

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
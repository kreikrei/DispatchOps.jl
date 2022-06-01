using CSV
using DataFrames
# using Gadfly
using JLD2
using Statistics
using DispatchOps
using Colors
# using Compose
using CairoMakie
import Makie: Makie.wong_colors

peti_transported(s::Simulation) = sum(
    sum(
        s.acc.executed_dispatch[a][:flow][k]
        for (k, v) in s.acc.executed_dispatch[a][:flow]
    ) for a in arcs(s.acc.executed_dispatch)
)

exp010 = load_object("/home/kreiton/.julia/dev/DispatchOps/out/exp010.jld2")
insertcols!(exp010, :network => fill("usulan", nrow(exp010)))
exp110 = load_object("/home/kreiton/.julia/dev/DispatchOps/out/exp110.jld2")
insertcols!(exp110, :network => fill("aktual", nrow(exp110)))

tocompare = vcat(exp010[exp010.noise.==0, :], exp110[exp110.noise.==0, :])
transform!(tocompare, :simulation => ByRow(x -> total_cost(x) * 1e3) => :total_cost)
pecahan = CSV.read("data/.pecahan.csv", DataFrame)
const pecahand = Dict(
    pecahan.id .=> [
        (nilai=p.nilai, konversi=p.konversi) for p in eachrow(pecahan)
    ]
)

transform!(tocompare,
    :simulation => ByRow(x -> sum(abs.([r.value * pecahand[r.pecahan].konversi * pecahand[r.pecahan].nilai for r in eachrow(x.acc.demand_fulfillment)]))) => :demand_fulfilled
)
insertcols!(tocompare, :fulfillment_cost => tocompare.demand_fulfilled ./ tocompare.total_cost)

fig = Figure()
ax1 = Axis(fig[1, 1],
    xticks=(unique(tocompare.H), string.(unique(tocompare.H))),
    title="Produktivitas Jaringan",
    ylabel="Pemenuhan Kebutuhan per Biaya (Rp/Rp)",
    xlabel="Panjang Periode Perencanaan (H)"
)

scatterlines!(ax1,
    unique(tocompare.H),
    unique(tocompare[tocompare.network.=="aktual", :fulfillment_cost]), label="aktual"
)
scatterlines!(ax1,
    unique(tocompare.H),
    unique(tocompare[tocompare.network.=="usulan", :fulfillment_cost]), label="usulan"
)

axislegend("Jaringan", position=:rb)
current_figure()
save("/home/kreiton/.julia/dev/DispatchOps/out/network_productivity_comparison.svg", fig)

to_plot = tocompare[tocompare.H.==4, :]
usulan_df = first(to_plot[to_plot.network.=="usulan", :])
aktual_df = first(to_plot[to_plot.network.=="aktual", :])

activities = DataFrame(
    T=Int[],
    jaringan=Int[],
    label=String[],
    aktivitas=Float64[]
)

for t in 1:12, df in [usulan_df, aktual_df]
    jaringan = df == usulan_df ? 1 : 2
    label = df == usulan_df ? "usulan" : "aktual"
    aktivitas = sum(
        sum(values(df.simulation.acc.executed_dispatch[a][:flow]))
        for a in filter(
            p -> tgt(p).per == t,
            collect(arcs(df.simulation.acc.executed_dispatch))
        )
    )
    append!(activities,
        DataFrame(T=t, label=label, aktivitas=aktivitas, jaringan=jaringan)
    )
end

fig = Figure()
ax1 = Axis(fig[1, 1],
    xticks=(unique(activities.T), string.(unique(activities.T))),
    ytickformat=x -> ["$(n/1e3)" for n in x],
    ylabel="Aktivitas Pengiriman (Ribu Peti)",
    xlabel="Periode",
    title="Perbandingan Aktivitas Pengiriman Jaringan Usulan dan Aktual Tiap Periode"
)

barplot!(ax1,
    activities.T,
    activities.aktivitas,
    dodge=activities.jaringan,
    color=wong_colors()[activities.jaringan]
)

labels = unique(activities.label)
elements = [PolyElement(polycolor=wong_colors()[i]) for i in 1:length(labels)]
title = "Jaringan"
Legend(fig[1, 2], elements, labels, title, titlehalign=:left)

current_figure()

save("/home/kreiton/.julia/dev/DispatchOps/out/network_activity_comparison.svg", fig)
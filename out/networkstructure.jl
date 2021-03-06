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

#=transform!(tocompare,
    :simulation => ByRow(x -> sum(abs.([r.value * pecahand[r.pecahan].konversi * pecahand[r.pecahan].nilai for r in eachrow(x.acc.demand_fulfillment)]))) => :demand_fulfilled
)
insertcols!(tocompare, :fulfillment_cost => tocompare.demand_fulfilled ./ tocompare.total_cost) =#

transform!(tocompare,
    :simulation => ByRow(x -> total_cost(x) * 1000) => :total_cost
)

fig = Figure()
ax1 = Axis(fig[1, 1],
    xticks=(unique(tocompare.H), string.(unique(tocompare.H))),
    title="Biaya Total Layanan Tiap Jaringan",
    ylabel="Total Biaya (Miliar Rupiah)",
    xlabel="Panjang Periode Perencanaan (H)",
    ytickformat=x -> ["$(n/1e9)" for n in x]
)

scatterlines!(ax1,
    unique(tocompare.H),
    unique(tocompare[tocompare.network.=="aktual", :total_cost]), label="aktual"
)
scatterlines!(ax1,
    unique(tocompare.H),
    unique(tocompare[tocompare.network.=="usulan", :total_cost]), label="usulan"
)
vlines!(ax1, 4, color=:red)

# axislegend("Jaringan", position=:rt)
current_figure()
#=save("/home/kreiton/.julia/dev/DispatchOps/out/network_productivity_comparison.svg", fig)=#

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

# fig = Figure()
ax2 = Axis(fig[2, 1],
    xticks=(unique(activities.T), string.(unique(activities.T))),
    ytickformat=x -> ["$(n/1e3)" for n in x],
    ylabel="Aktivitas Pengiriman (Ribu Peti)",
    xlabel="Periode (T)",
    title="Perbandingan Aktivitas Pengiriman Jaringan Usulan dan Aktual Tiap Periode",
    subtitle="(H=4)"
)

barplot!(ax2,
    activities.T,
    activities.aktivitas,
    dodge=activities.jaringan,
    color=wong_colors()[activities.jaringan]
)

labels = unique(activities.label)
elements = [PolyElement(polycolor=wong_colors()[i]) for i in 1:length(labels)]
title = "Jaringan"
Legend(fig[1:2, 2], elements, labels, title, titlehalign=:left)

current_figure()

save("/home/kreiton/.julia/dev/DispatchOps/out/network_comparison.svg", fig)

# NETWORK STRUCTURE
for df in ["usulan", "aktual"]
    to_D = first(to_plot[to_plot.network.==df, :])
    D = MetaDigraph{String}()

    for a in arcs(to_D.simulation.acc.executed_dispatch)
        new = DispatchOps.Arc(src(a).loc, tgt(a).loc, 1)
        add_arc!(D, new)
    end

    filename = "$(df)_df"
    open("./out/$(df)_df.dot", "w") do file
        write(file, "digraph $(df)_df {\n")
        write(file, "    splines=polyline\n")
        write(file, "    overlap=scale\n")
        write(file, "    mode=KK\n")

        for r in eachrow(usulan_df.simulation.libs.khazanah)
            y = r.y
            x = r.x

            write(file, "    $(r.id) [\n")
            write(file, "        pos = \"$(x),$(y)\"\n")
            write(file, "    ];\n")
        end

        for a in arcs(D)
            write(file, "    $(src(a)) -> $(tgt(a));\n")
        end

        write(file, "}")
    end
end
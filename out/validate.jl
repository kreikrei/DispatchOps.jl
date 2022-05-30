using CSV
using DataFrames
using Gadfly
using JLD2
using Statistics
using AxisArrays
using DispatchOps
using Colors
using Compose
using CairoMakie

duration(s::Simulation) = s.duration
rupiah_transported(s::Simulation, pecahand::Dict) = AxisArray(
    [
        s.acc.executed_dispatch[a][:flow][k] * v.konversi * v.nilai
        for (k, v) in pecahand, a in arcs(s.acc.executed_dispatch)
    ], pecahan=keys(pecahand), trayek=arcs(s.acc.executed_dispatch)
)
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

const pengiriman_aktual_trayek = 192
const pengiriman_aktual_rupiah = 219_600_000_000_000

validation = load_object("/home/kreiton/.julia/dev/DispatchOps/out/validation.jld2")

tes_N = repeat(1:3,
    inner=length(unique(validation.H)),
    outer=length(unique(validation.noise))
)

insertcols!(validation, :H, :N => tes_N, after=true)

trayek_pengiriman = transform(validation,
    :simulation => ByRow(x -> length(arcs(x.acc.executed_dispatch))) => :trayek_pengiriman
)
rupiah_pengiriman = transform(validation,
    :simulation => ByRow(x -> sum(rupiah_transported(x, pecahand))) => :rupiah_pengiriman
)

max_scale(x) = 10^(round(log10(x)) + 0.5)
min_scale(x) = 10^(round(log10(x)) - 0.5)

gdf_trayek_pengiriman = groupby(trayek_pengiriman, :N)
gdf_rupiah_pengiriman = groupby(rupiah_pengiriman, :N)

four_colors = [colorant"#006E7F", colorant"#F8CB2E", colorant"#711A75", colorant"#B22727"]

# last check: klo dikasih min. order of magnitude 2 jdi terlalu mejret atau tidak

# TRAYEK

p_trayek = plot(
    trayek_pengiriman,
    x=:H, y=:trayek_pengiriman, color=:noise, group=:N,
    Geom.point, Geom.line,
    yintercept=[pengiriman_aktual_trayek],
    Geom.hline(style=[:dash], color=["black"]),
    Scale.color_discrete_manual(four_colors...),
    Scale.x_discrete,
    Guide.colorkey(title="Noise"),
    Guide.xlabel("Panjang Horizon Perencanaan (H)"),
    Guide.ylabel("Jumlah Pengiriman (trayek)"),
    Guide.annotation(
        compose(context(), text(10, 0.96 * pengiriman_aktual_trayek, "Pengiriman Aktual = $pengiriman_aktual_trayek", hright, vtop), fontsize(7pt))
    ),
    Guide.title("Jumlah Pengiriman Model pada Panjang Horizon Perencanaan Tertentu")
)

img = SVG("/home/kreiton/.julia/dev/DispatchOps/out/trayek_pengiriman.svg")
draw(img, p_trayek)

# RUPIAH
p_rupiah = plot(
    rupiah_pengiriman,
    x=:H, y=:rupiah_pengiriman, color=:noise, group=:N,
    Geom.point, Geom.line,
    yintercept=[pengiriman_aktual_rupiah],
    Geom.hline(style=[:dash], color=["black"]),
    Scale.color_discrete_manual(four_colors...),
    Scale.x_discrete,
    Guide.colorkey(title="Noise"),
    Guide.xlabel("Panjang Horizon Perencanaan (H)"),
    Guide.ylabel("Rupiah Terdistribusi (Rp)"),
    Guide.annotation(
        compose(context(), text(10, 0.96 * pengiriman_aktual_rupiah, "Rupiah Terdistribusi Aktual = Rp$(pengiriman_aktual_rupiah/1000000000000) Triliun", hright, vtop), fontsize(7pt))
    ),
    Guide.title("Rupiah Terdistribusi Model pada Panjang Horizon Perencanaan Tertentu")
)

img = SVG("/home/kreiton/.julia/dev/DispatchOps/out/rupiah_pengiriman.svg")
draw(img, p_rupiah)

#=======DIRECT COMPARISON SOLUSI TERDEKAT===========#

widergap = load_object("/home/kreiton/.julia/dev/DispatchOps/out/validationbackup.jld2")

trayek_pengiriman = transform(widergap,
    :simulation => ByRow(x -> length(arcs(x.acc.executed_dispatch))) => :trayek_pengiriman
)

rupiah_pengiriman = transform(widergap,
    :simulation => ByRow(x -> sum(rupiah_transported(x, pecahand))) => :rupiah_pengiriman
)

to_plot_for_comparison = widergap[[2, 5], :]

TW = [1:3, 4:6, 7:9, 10:12]
pengantaran_aktual_tw = [33, 98, 29, 32]

jumlah_pengantaran = DataFrame(
    HasilLabel=String[],
    Hasil=Int[],
    Triwulan=Int[],
    JumlahPengantaran=Int[]
)

for tw in eachindex(pengantaran_aktual_tw)
    append!(jumlah_pengantaran, DataFrame(HasilLabel="Aktual", Hasil=1, Triwulan=tw, JumlahPengantaran=pengantaran_aktual_tw[tw]))
end

for r in eachrow(to_plot_for_comparison), tw in eachindex(TW)
    hasil = rownumber(r) + 1
    hasillabel = "Model (H=$(r.H))"
    t = tw
    v = length(
        filter(a -> tgt(a).per in TW[tw], arcs(r.simulation.acc.executed_dispatch) |> collect)
    )
    append!(jumlah_pengantaran, DataFrame(HasilLabel=hasillabel, Hasil=hasil, Triwulan=t, JumlahPengantaran=v))
end

jumlah_pengantaran |> println

# BARPLOT MAKIE

colors = Makie.wong_colors()

fig = Figure()
ax = CairoMakie.Axis(
    fig[1, 1],
    xticks=(jumlah_pengantaran.Triwulan, string.(jumlah_pengantaran.Triwulan)),
    title="Pengantaran Tiap Triwulan",
    subtitle="Tahun 2019",
    ylabel="Jumlah Pengantaran",
    xlabel="Triwulan"
)

barplot!(ax,
    jumlah_pengantaran.Triwulan,
    jumlah_pengantaran.JumlahPengantaran,
    dodge=jumlah_pengantaran.Hasil,
    bar_labels=jumlah_pengantaran.JumlahPengantaran,
    flip_labels_at=80.0,
    color=colors[jumlah_pengantaran.Hasil]
)

labels = unique(jumlah_pengantaran.HasilLabel)
elements = [PolyElement(polycolor=colors[i]) for i in 1:length(labels)]
title = "Generator"
Legend(fig[1, 2], elements, labels, title, titlehalign=:left)

save("tes_makie.svg", fig)
using CSV
using DataFrames
# using Gadfly
using JLD2
using Statistics
using AxisArrays
using DispatchOps
# using Colors
# using Compose
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

#=======DIRECT COMPARISON SOLUSI TERDEKAT===========#

widergap = load_object("/home/kreiton/.julia/dev/DispatchOps/out/validationbackup.jld2")

trayek_pengiriman = transform(widergap,
    :simulation => ByRow(x -> length(arcs(x.acc.executed_dispatch))) => :trayek_pengiriman
)

rupiah_pengiriman = transform(widergap,
    :simulation => ByRow(x -> sum(rupiah_transported(x, pecahand))) => :rupiah_pengiriman
)

to_plot_for_comparison = widergap[[2, 5], :]
pecahand
TW = [1:3, 4:6, 7:9, 10:12]
pengiriman_aktual_tw = [33, 98, 29, 32]
rupiah_terdistribusi_aktual_tw = [
    28_600_000_000_000.0, 127_700_000_000_000.0, 9_600_000_000_000.0, 53_700_000_000_000.0
]

jumlah_pengiriman = DataFrame(
    HasilLabel=String[],
    Hasil=Int[],
    Triwulan=Int[],
    JumlahPengiriman=Int[]
)

jumlah_rupiah_terdistribusi = DataFrame(
    HasilLabel=String[],
    Hasil=Int[],
    Triwulan=Int[],
    JumlahRupiahTerdistribusi=Float64[]
)

for tw in eachindex(pengiriman_aktual_tw)
    append!(jumlah_pengiriman,
        DataFrame(
            HasilLabel="Aktual",
            Hasil=1,
            Triwulan=tw,
            JumlahPengiriman=pengiriman_aktual_tw[tw]
        )
    )
end

for tw in eachindex(rupiah_terdistribusi_aktual_tw)
    append!(jumlah_rupiah_terdistribusi,
        DataFrame(
            HasilLabel="Aktual",
            Hasil=1,
            Triwulan=tw,
            JumlahRupiahTerdistribusi=rupiah_terdistribusi_aktual_tw[tw]
        )
    )
end

jumlah_pengiriman
jumlah_rupiah_terdistribusi

for r in eachrow(to_plot_for_comparison), tw in eachindex(TW)
    hasil = rownumber(r) + 1
    hasillabel = "Model (GAP=$(r.GAP), H=$(r.H))"
    t = tw

    v_pengiriman = length(
        filter(
            a -> tgt(a).per in TW[tw],
            collect(arcs(r.simulation.acc.executed_dispatch))
        )
    )
    append!(jumlah_pengiriman,
        DataFrame(
            HasilLabel=hasillabel, Hasil=hasil, Triwulan=t,
            JumlahPengiriman=v_pengiriman
        )
    )

    v_rupiah_terdistribusi = sum(
        r.simulation.acc.executed_dispatch[a][:flow][k] * v.konversi * v.nilai
        for (k, v) in pecahand, a in filter(
            a -> tgt(a).per in TW[tw], collect(arcs(r.simulation.acc.executed_dispatch))
        )
    )
    append!(jumlah_rupiah_terdistribusi,
        DataFrame(
            HasilLabel=hasillabel, Hasil=hasil, Triwulan=t,
            JumlahRupiahTerdistribusi=v_rupiah_terdistribusi
        )
    )
end

jumlah_pengiriman
jumlah_rupiah_terdistribusi

# BARPLOT MAKIE

colors = Makie.wong_colors()

fig1 = Figure()
ax1 = CairoMakie.Axis(
    fig1[1, 1],
    xticks=(jumlah_pengiriman.Triwulan, string.(jumlah_pengiriman.Triwulan)),
    title="Pengiriman Tiap Triwulan",
    subtitle="Tahun 2019",
    ylabel="Jumlah Pengiriman (Trayek)",
    xlabel="Triwulan"
)
barplot!(ax1,
    jumlah_pengiriman.Triwulan,
    jumlah_pengiriman.JumlahPengiriman,
    dodge=jumlah_pengiriman.Hasil,
    bar_labels=jumlah_pengiriman.JumlahPengiriman,
    color=colors[jumlah_pengiriman.Hasil],
    label_size=15,
    label_offset=0
)
fig1
labels1 = unique(jumlah_pengiriman.HasilLabel)
elements1 = [PolyElement(polycolor=colors[i]) for i in 1:length(labels1)]
title1 = "Generator"
Legend(fig1[1, 2], elements1, labels1, title1, titlehalign=:left)
fig1

fig2 = Figure()
formattriliun(x) = ["$(convert(Int64,round(n/1e12)))" for n in x]
ax2 = CairoMakie.Axis(
    fig2[1, 1],
    xticks=(jumlah_rupiah_terdistribusi.Triwulan, string.(jumlah_rupiah_terdistribusi.Triwulan)),
    title="Rupiah Terdistribusi Tiap Triwulan",
    subtitle="Tahun 2019",
    ylabel="Jumlah Rupiah Terdistribusi (Triliun Rupiah)",
    xlabel="Triwulan",
    ytickformat=formattriliun
)

barplot!(ax2,
    jumlah_rupiah_terdistribusi.Triwulan,
    jumlah_rupiah_terdistribusi.JumlahRupiahTerdistribusi,
    dodge=jumlah_rupiah_terdistribusi.Hasil,
    bar_labels=:y,
    color=colors[jumlah_rupiah_terdistribusi.Hasil],
    label_size=15,
    label_offset=0,
    label_formatter=x -> "$(round(x/1e12,digits=1))"
)

fig2
labels2 = unique(jumlah_rupiah_terdistribusi.HasilLabel)
elements2 = [PolyElement(polycolor=colors[i]) for i in 1:length(labels2)]
title2 = "Generator"
Legend(fig2[1, 2], elements2, labels2, title2, titlehalign=:left)
fig2

save("/home/kreiton/.julia/dev/DispatchOps/out/jumlah_pengiriman.svg", fig1)
save("/home/kreiton/.julia/dev/DispatchOps/out/jumlah_rupiah_terdistribusi.svg", fig2)

#= former plotting script

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
draw(img, p_rupiah) =#
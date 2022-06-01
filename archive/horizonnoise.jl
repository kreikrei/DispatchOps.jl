using CSV
using DataFrames
using Gadfly
using JLD2
using Statistics
using DispatchOps
using Colors
# using Compose
# using CairoMakie
import Makie: Makie.wong_colors

exp010 = load_object("/home/kreiton/.julia/dev/DispatchOps/out/exp010.jld2")

insertcols!(exp010, :H, :N => repeat(1:4,
        inner=length(unique(exp010.H)),
        outer=length(unique(exp010.noise))
    ), after=true)

transform!(
    exp010, :simulation => ByRow(x -> total_cost(x) * 1e3) => :total_cost
)

pecahan = CSV.read("data/.pecahan.csv", DataFrame)
const pecahand = Dict(
    pecahan.id .=> [
        (nilai=p.nilai, konversi=p.konversi) for p in eachrow(pecahan)
    ]
)

transform!(exp010,
    :simulation => ByRow(x -> sum(abs.([r.value * pecahand[r.pecahan].konversi * pecahand[r.pecahan].nilai for r in eachrow(x.acc.demand_fulfillment)]))) => :demand_fulfilled
)

insertcols!(exp010, :fulfillment_cost => exp010.demand_fulfilled ./ exp010.total_cost)

p_noise = plot(exp010,
    x=:H, y=:fulfillment_cost, color=:noise, group=:N,
    Geom.point, Geom.line,
    Scale.x_discrete,
    Scale.color_discrete_manual(convert(Vector{Color}, wong_colors())...),
    Guide.colorkey(title="StaticNoise"),
    Guide.title("Pemenuhan Kebutuhan per Biaya Terhadap Panjang Horizon Perencanaan (Gap=20%)"),
    Guide.ylabel("Pemenuhan Kebutuhan per Biaya (Rp/Rp)"),
    Guide.xlabel("Panjang Horizon Perencanaan (H)")
) |> SVG("/home/kreiton/.julia/dev/DispatchOps/out/horizonnoise.svg")
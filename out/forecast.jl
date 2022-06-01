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

peti_transported(s::Simulation) = sum(
    sum(
        s.acc.executed_dispatch[a][:flow][k]
        for (k, v) in s.acc.executed_dispatch[a][:flow]
    ) for a in arcs(s.acc.executed_dispatch)
)

exp010 = load_object("/home/kreiton/.julia/dev/DispatchOps/out/exp010.jld2")
exp011 = load_object("/home/kreiton/.julia/dev/DispatchOps/out/exp011.jld2")

insertcols!(exp010, :H, :noise_function => fill(:static, nrow(exp010)))
insertcols!(exp011, :H, :noise_function => fill(:dynamic, nrow(exp011)))
expo = vcat(exp010, exp011)

transform!(
    expo, :simulation => ByRow(x -> total_cost(x) * 1e3) => :total_cost
)

pecahan = CSV.read("data/.pecahan.csv", DataFrame)
pecahand = Dict(
    pecahan.id .=> [
        (nilai=p.nilai, konversi=p.konversi) for p in eachrow(pecahan)
    ]
)

transform!(expo,
    :simulation => ByRow(x -> sum(abs.([r.value * pecahand[r.pecahan].konversi * pecahand[r.pecahan].nilai for r in eachrow(x.acc.demand_fulfillment)]))) => :demand_fulfilled
)

insertcols!(expo, :fulfillment_cost => expo.demand_fulfilled ./ expo.total_cost)

transform!(
    exp, :simulation => ByRow(x -> lost_sales(x)) => :lost_sales
)

p_noise_fulfillment = plot(expo,
    x=:noise, y=:fulfillment_cost, xgroup=:noise_function, color=:H,
    Geom.subplot_grid(Geom.point, Geom.smooth, free_x_axis=true),
    Scale.color_discrete_manual(convert(Vector{Color}, wong_colors())...),
    Guide.ylabel("Pemenuhan Kebutuhan per Biaya (Rp/Rp)"),
    Guide.xlabel("Parameter Simpangan Tiap Noise Function"),
    Guide.title("Pemenuhan Kebutuhan per Biaya Terhadap Parameter Simpangan")
) |> SVG("/home/kreiton/.julia/dev/DispatchOps/out/forecast_fulfillment_per_cost.svg")

p_noise_lost = plot(expo,
    x=:noise, y=:lost_sales, xgroup=:noise_function, color=:H,
    Geom.subplot_grid(Geom.point, Geom.smooth, free_x_axis=true),
    Scale.y_continuous(labels=x -> "$(x*1e2)%"),
    Scale.color_discrete_manual(convert(Vector{Color}, wong_colors())...),
    Guide.ylabel("Lost Sales"),
    Guide.xlabel("Parameter Simpangan Tiap Noise Function"),
    Guide.title("Lost Sales Terhadap Parameter Simpangan")
) |> SVG("/home/kreiton/.julia/dev/DispatchOps/out/forecast_lost_sales.svg")

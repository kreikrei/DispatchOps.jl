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
exp = vcat(exp010, exp011)

transform!(
    exp, :simulation => ByRow(x -> total_cost(x) * 1e3) => :total_cost
)

transform!(
    exp, :simulation => ByRow(x -> lost_sales(x)) => :lost_sales
)

transform!(
    exp, :simulation => ByRow(x -> peti_transported(x)) => :peti_transported
)

transform!(
    exp, :simulation => ByRow(x -> total_cost(x) * 1e3 / peti_transported(x)) => :cost_per_unit_shipped
)

#=transform!(
    exp, :simulation => ByRow(x -> sum(abs.(x.libs.demand_forecast.value .- x.libs.demand_realization.value))/sum(abs.(x.libs.demand_forecast.value))) => :forecast_delta
)=#

p_noise_cost = plot(exp,
    x=:noise, y=:cost_per_unit_shipped, xgroup=:noise_function, color=:H,
    Geom.subplot_grid(Geom.point, Stat.x_jitter(range=0.1), Geom.smooth, free_x_axis=true), Scale.y_continuous(labels=x -> "$(x/1e3)"),
    Scale.color_discrete_manual(convert(Vector{Color}, wong_colors())...),
    Guide.ylabel("Biaya per Peti Terkirim (Ribu Rupiah)"),
    Guide.xlabel("Parameter Simpangan tiap Noise Function"),
    Guide.title("Biaya per Peti Terkirim Terhadap Parameter Simpangan")
) |> SVG("/home/kreiton/.julia/dev/DispatchOps/out/forecast_cost_per_unit_shipped.svg")

p_noise_lost = plot(exp,
    x=:noise, y=:lost_sales, xgroup=:noise_function, color=:H,
    Geom.subplot_grid(Geom.point, Stat.x_jitter(range=0.1), Geom.smooth, free_x_axis=true), Scale.y_continuous(labels=x -> "$(x*1e2)%"),
    Scale.color_discrete_manual(convert(Vector{Color}, wong_colors())...),
    Guide.ylabel("Lost Sales"),
    Guide.xlabel("Parameter Simpangan Tiap Noise Function"),
    Guide.title("Lost Sales Terhadap Parameter Simpangan")
) |> SVG("/home/kreiton/.julia/dev/DispatchOps/out/forecast_lost_sales.svg")

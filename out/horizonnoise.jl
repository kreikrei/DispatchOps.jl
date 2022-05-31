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

insertcols!(exp010, :H, :N => repeat(1:4,
        inner=length(unique(exp010.H)),
        outer=length(unique(exp010.noise))
    ), after=true)

transform!(
    exp010, :simulation => ByRow(x -> total_cost(x) * 1e3) => :total_cost
)
transform!(
    exp010, :simulation => ByRow(x -> lost_sales(x)) => :lost_sales
)
transform!(
    exp010, :simulation => ByRow(x -> peti_transported(x)) => :peti_transported
)
transform!(
    exp010, :simulation => ByRow(x -> total_cost(x) * 1e3 / peti_transported(x)) => :cost_per_unit_shipped
)

p_noise = plot(exp010,
    x=:H, y=:cost_per_unit_shipped, color=:noise,
    Geom.point, Geom.smooth,
    Scale.x_discrete, Scale.y_continuous(labels=x -> "$(x/1e3)"),
    Scale.color_discrete_manual(convert(Vector{Color}, wong_colors())...),
    Guide.colorkey(title="StaticNoise"),
    Guide.title("Biaya per Peti Terkirim Terhadap Panjang Horizon Perencanaan (Gap=20%)"),
    Guide.ylabel("Biaya per Peti Terkirim (Ribu Rupiah)"),
    Guide.xlabel("Panjang Horizon Perencanaan (H)")
) |> SVG("/home/kreiton/.julia/dev/DispatchOps/out/horizonnoise.svg")
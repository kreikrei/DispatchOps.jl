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
transform!(
    exp010, :simulation => ByRow(x -> lost_sales(x)) => :lost_sales
)

p_noise = plot(exp010,
    x=:H, y=:total_cost, color=:noise, group=:N,
    Geom.point, Stat.x_jitter(range=0.1), Geom.smooth,
    Scale.x_discrete, Scale.y_continuous(labels=x -> "$(x/1e9)"),
    Scale.color_discrete_manual(convert(Vector{Color}, wong_colors())...),
    Guide.colorkey(title="Noise"),
    Guide.title("Biaya Total Layanan Terhadap Panjang Horizon Perencanaan (Gap=20%)"),
    Guide.ylabel("Total Biaya (Miliar Rupiah)"),
    Guide.xlabel("Panjang Horizon Perencanaan (H)")
) |> SVG("/home/kreiton/.julia/dev/DispatchOps/out/horizonnoise.svg")
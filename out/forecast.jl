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
exp011 = load_object("/home/kreiton/.julia/dev/DispatchOps/out/exp011.jld2")

insertcols!(exp010, :H, :noise_function => fill(:Statis, nrow(exp010)))
insertcols!(exp011, :H, :noise_function => fill(:Dinamis, nrow(exp011)))
expo = vcat(exp010, exp011)
expo = expo[expo.noise.!=0, :]
expo = DataFrame(
    noise=expo.noise,
    noise_function=expo.noise_function,
    H=string.(expo.H),
    GAP=expo.GAP,
    simulation=expo.simulation
)

transform!(
    expo, :simulation => ByRow(x -> total_cost(x) * 1e3) => :total_cost
)

transform!(
    expo, :simulation => ByRow(x -> lost_sales(x)) => :lost_sales
)

transform!(
    expo, :simulation => ByRow(x -> sum(abs.(x.libs.demand_forecast.value .- x.libs.demand_realization.value))) => :simpangan_total
)

using GLM
r = glm(
    @formula(total_cost ~ simpangan_total),
    expo[expo.noise_function.==:Statis, :], Normal()
)

for n in [:Statis, :Dinamis], f in [:total_cost, :lost_sales]
    p = plot(expo[expo.noise_function.==n, :],
        x=:noise, y=f, color=:H, Geom.boxplot,
        Scale.x_discrete(
            levels=unique(
                expo[expo.noise_function.==n, :noise]
            )
        ),
        Scale.color_discrete_manual(convert(Vector{Color}, wong_colors())...),
        Guide.xrug,
        Guide.yrug,
        Guide.xlabel("Parameter Simpangan Fungsi $(n)")
    )
    f == :total_cost && push!(p,
        Coord.Cartesian(ymax=4.2e10, ymin=2.5e10),
        Scale.y_continuous(labels=x -> "$(x/1e9)"),
        Guide.ylabel("Biaya Total Layanan (Miliar Rupiah)")
    )
    f == :lost_sales && push!(p,
        Coord.Cartesian(ymax=0.27, ymin=0.23),
        Scale.y_continuous(labels=x -> "$(x*100)%"),
        Guide.ylabel("Lost Sales")
    )

    p |> SVG("/home/kreiton/.julia/dev/DispatchOps/out/forecast_$(f)_$(n).svg")
end

#=p_noise_lost = plot(expo,
    x=:noise, y=:lost_sales, xgroup=:noise_function, color=:H,
    Geom.subplot_grid(Geom.point, Geom.smooth, free_x_axis=true),
    Scale.y_continuous(labels=x -> "$(x*1e2)%"),
    Scale.color_discrete_manual(convert(Vector{Color}, wong_colors())...),
    Guide.ylabel("Lost Sales"),
    Guide.xlabel("Parameter Simpangan Tiap Noise Function"),
    Guide.title("Lost Sales Terhadap Parameter Simpangan")
) |> SVG("/home/kreiton/.julia/dev/DispatchOps/out/forecast_lost_sales.svg")=#
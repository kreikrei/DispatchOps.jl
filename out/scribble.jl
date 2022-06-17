using DispatchOps, JLD2, DataFrames, CSV, Gadfly, Statistics

df = load_object("/home/kreiton/.julia/dev/DispatchOps/out/optim.jld2")

res = DataFrame(
    H=Int[],
    GAP=Float64[],
    id=String[],
    util=Float64[]
)

for r in eachrow(df)
    A = r.simulation.acc.inventory_levels
    B = r.simulation.acc.demand_fulfillment
    C = innerjoin(
        A[A.periode .>=1,:], 
        B[B.periode .<=12,:],
        on=[:id,:periode,:pecahan], makeunique=true
    )
    insertcols!(C, :invl => C.value .+ C.value_1)

    pecahan_sum = combine(groupby(C, [:id, :periode]), :invl => sum)
    location_avg = combine(groupby(pecahan_sum, [:id]), :invl_sum => mean)

    aggregated = innerjoin(location_avg, r.simulation.libs.khazanah, on=:id)
    insertcols!(aggregated, :util => aggregated.invl_sum_mean./aggregated.Q)
    append!(
        res, DataFrame(
            H = fill(r.H, nrow(aggregated)),
            GAP = fill(r.GAP, nrow(aggregated)),
            id = aggregated.id,
            util = aggregated.util
        )
    )
end
res

plot(res, x=:id, y=:util, yintercept=[1.0], 
    Geom.hline(color="red"), 
    Geom.boxplot(suppress_outliers=true), 
    Scale.x_discrete,
    Scale.y_continuous(labels=x->"$(x*100)%"),
    Guide.ylabel("Utilisasi Kapasitas Khazanah"),
    Theme(panel_fill="white")
) |> SVG("/home/kreiton/Documents/tugas akhir/average_inventory_util.svg")

mean(res.util)
std(res.util)

# TRAYEK UTILIZATION

D = df.simulation[6].acc.executed_dispatch
rs = []

for a in arcs(D)
    x = sum(values(D[a][:flow]))
    y = D[a][:trip]
    Q = D[a][:Q]
    if x / (y * Q) != -Inf
        push!(rs, x/(y*Q))
    end
end

plot(x=rs, Geom.histogram(bincount=10, limits=(min=0.0, max=1.0)), Scale.x_continuous(labels=x -> "$(x*100)%"), Guide.xlabel("Utilisasi Kapasitas Trayek"), Guide.ylabel("Jumlah Trayek dengan Utilisasi x")) #|> SVG("/home/kreiton/Documents/tugas akhir/average_trayek_util.svg")

count(>=(1), rs) / length(rs)   
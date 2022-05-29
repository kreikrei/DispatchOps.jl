using CSV
using DataFrames
using Gadfly
using JLD2
using Statistics
using AxisArrays
using DispatchOps
using Colors
using Compose

# read sensitivity analysis reports
reportH1 = load_object("/home/kreiton/.julia/dev/DispatchOps/out/NewSensitivityReport-H1")
reportH2 = load_object("/home/kreiton/.julia/dev/DispatchOps/out/NewSensitivityReport-H2")
reportH3 = load_object("/home/kreiton/.julia/dev/DispatchOps/out/NewSensitivityReport-H3")

moda = CSV.read("/home/kreiton/.julia/dev/DispatchOps/data/.moda.csv", DataFrame)
modad = Dict(1:length(moda.name) .=> moda.name)

function moda_primer!(df::DataFrame, modad::Dict)
    modacols = Vector{String}()
    sizehint!(modacols, nrow(df))
    varcols = Vector{Float64}()
    sizehint!(varcols, nrow(df))
    for r in eachrow(df)
        idx = findfirst(x -> x != 0, r.varmult)
        if !isnothing(idx)
            push!(modacols, modad[idx])
            push!(varcols, r.varmult[idx])
        else
            push!(modacols, "BASELINE")
            push!(varcols, 0.0)
        end
    end
    insertcols!(df, :varmult, :moda => modacols, :variance => varcols)
    return df
end

moda_primer!(reportH1, modad)
insertcols!(reportH1, :H => fill(1, nrow(reportH1)))
moda_primer!(reportH2, modad)
insertcols!(reportH2, :H => fill(2, nrow(reportH2)))
moda_primer!(reportH3, modad)
insertcols!(reportH3, :H => fill(3, nrow(reportH3)))

report = vcat(reportH1, reportH2, reportH3)

# ilangin base base itu

unique(report.col)

for H in unique(report.H), m in unique(report.moda), c in unique(report.col)
    if m != "BASELINE" && c != :base
        append!(report, DataFrame(
            col=c,
            moda=m,
            H=H,
            variance=0.0,
            varmult=[[0.0, 0.0, 0.0, 0.0]],
            total_cost=0.0,
            lost_sales=0.0,
            Jaccard_similarity_coarse=1.0,
            Jaccard_similarity_fine=1.0,
            Jaccard_similarity_mild=1.0
        )
        )
    end
end

# DATA PROCESSING DONE

report_stacked = stack(report, [:Jaccard_similarity_fine, :Jaccard_similarity_coarse, :Jaccard_similarity_mild])

for c in unique()

to_plot = filter(r -> r.col == :cjarak && r.moda == "TRUK" && 
r.variable=="Jaccard_similarity_fine", report_stacked)

plot(to_plot, x=:variance, y=:value, color=:H, Geom.point, Geom.line, Scale.discrete_color)



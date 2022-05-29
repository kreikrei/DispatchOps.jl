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
moda_primer!(reportH2, modad)
moda_primer!(reportH3, modad)
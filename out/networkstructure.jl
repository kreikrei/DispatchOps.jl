using CSV
using DataFrames
# using Gadfly
using JLD2
using Statistics
using DispatchOps
using Colors
# using Compose
# using CairoMakie
import Makie: Makie.wong_colors

exp010 = load_object("/home/kreiton/.julia/dev/DispatchOps/out/exp010.jld2")
exp110 = load_object("/home/kreiton/.julia/dev/DispatchOps/out/exp110.jld2")
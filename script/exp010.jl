# TRAYEK | FIXED-END | NOISE_FUNCTION |  GAP
#    0   |     1     |       0        |  0.2

using Revise
using DispatchOps
using JLD2

e = Experiment(
    T=12,
    data_path="/home/kreiton/.julia/dev/DispatchOps/data/origin",
    is_complete=true,
    noise_function=noisify_fixed,
    noise_range=0:10:50,
    replication=5,
    H_range=1:8,
    GAP_range=[0.2],
    model_used=hard_holdover_model,
    is_horizon_fixed=true,
    output_path="/home/kreiton/.julia/dev/DispatchOps/out",
    file_name="exp010"
)

process(e)
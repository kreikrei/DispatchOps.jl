# TRAYEK | FIXED-END | NOISE_FUNCTION |  GAP
#    0   |     1     |       0        |  0.05

using Revise
using DispatchOps

e = Experiment(
    T=12,
    data_path="/home/kreiton/.julia/dev/DispatchOps/data/origin",
    is_complete=true,
    noise_function=noisify_fixed,
    noise_range=0:0,
    replication=1,
    H_range=1:6,
    GAP_range=[0.59],
    model_used=hard_holdover_model,
    is_horizon_fixed=true,
    output_path="/home/kreiton/.julia/dev/DispatchOps/out",
    file_name="optim"
)

process_experiment(e)
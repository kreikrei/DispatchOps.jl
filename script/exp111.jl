# TRAYEK | FIXED-END | NOISE_FUNCTION |  GAP
#    1   |     1     |       1        |  0.2

using Revise
using DispatchOps

e = Experiment(
    T=12,
    data_path="/home/kreiton/.julia/dev/DispatchOps/data/laptri",
    is_complete=true,
    noise_function=noisify_varied,
    noise_range=0:0.05:0.20,
    replication=4,
    H_range=1:6,
    GAP_range=[0.2],
    model_used=hard_holdover_model,
    is_horizon_fixed=true,
    output_path="/home/kreiton/.julia/dev/DispatchOps/out",
    file_name="exp111"
)

process_experiment(e)
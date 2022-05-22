# FOR VALIDATION PURPOSES
# the only use of soft_holdover_model

using Revise
using DispatchOps

e = Experiment(
    T=12,
    data_path="/home/kreiton/.julia/dev/DispatchOps/data/laptri",
    is_complete=false,
    noise_function=noisify_varied,
    noise_range=0:0.05:0.15,
    replication=3,
    H_range=1:10,
    GAP_range=[0.2],
    model_used=soft_holdover_model,
    is_horizon_fixed=true,
    output_path="/home/kreiton/.julia/dev/DispatchOps/out",
    file_name="validation"
)

process_experiment(e)
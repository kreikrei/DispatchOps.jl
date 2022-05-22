using Revise
using DispatchOps

e = Experiment(
    T=12,
    data_path="/home/kreiton/.julia/dev/DispatchOps/data/laptri",
    is_complete=true,
    noise_function=noisify_varied,
    noise_range=0:0.05:0.10,
    replication=2,
    H_range=1:3,
    GAP_range=[0.2],
    model_used=hard_holdover_model,
    is_horizon_fixed=true,
    output_path="/home/kreiton/.julia/dev/DispatchOps/out",
    file_name="testruns"
)

process_experiment(e)
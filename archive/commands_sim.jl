# DEMAND GENERATOR
include("generator.jl")
libs = Libraries("/home/kreiton/.julia/dev/DispatchOps/data/laptri", false)
libs.demand_realization = noisify_fixed(libs.demand_forecast, 0)

# INITIALIZATION
sim = Simulation(
    terminating_timestep = 2, 
    libs = libs, 
    cons = Constants(1, 0.001)
)

# RUN
run!(sim)
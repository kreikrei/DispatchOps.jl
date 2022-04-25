"""
    readData(path_to_data_folder, complete_trayek = true)
reads the data folder given into dataframes ready to be used.
the data folder must contain:
- khazanah (id, name, x_coor, y_coor, capacity, cjarak, cpeti, transit)
- trayek (u, v, moda)
- moda (name, capacity, cjarak, cpeti, transit)
- demand (location_id, period, pecahan, value)
- stock (location_id, pecahan, value)
by default completes the trayek by ensuring for every a -> b there exists b -> a.
"""
function readData(path::String, complete_trayek::Bool=true)
    khazanah = CSV.read(joinpath(path, "khazanah.csv"), DataFrame)
    demand = CSV.read(joinpath(path, "demand.csv"), DataFrame)
    stock = CSV.read(joinpath(path, "stock.csv"), DataFrame)
    trayek = CSV.read(joinpath(path, "trayek.csv"), DataFrame)
    moda = CSV.read(joinpath(path, "moda.csv"), DataFrame)

    if complete_trayek
        append!(trayek, DataFrame(u=trayek.v, v=trayek.u, moda=trayek.moda))
        unique!(trayek)
    end

    trayek = innerjoin(trayek, moda, on=:moda => :name)

    return khazanah, demand, stock, trayek
end
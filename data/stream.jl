using CSV, DataFrames
khazanah = CSV.read("khazanah.csv", DataFrame);
demand = CSV.read("demand.csv", DataFrame);
stock = CSV.read("stock.csv", DataFrame);
periode = CSV.read("periode.csv", DataFrame);
pecahan = CSV.read("pecahan.csv", DataFrame);
trayek = CSV.read("trayek.csv", DataFrame);
moda = CSV.read("moda.csv", DataFrame);

using Plots

priceDF = CSV.read("data/Elspotprices.csv", DataFrame, decimal=',')
prodDF = CSV.read("data/Forecasts_Hour.csv", DataFrame, decimal=',')

scatter(prodDF[:,9],priceDF[:,5])
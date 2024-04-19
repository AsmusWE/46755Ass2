using CSV, DataFrames
using Random

function GenScens()
    priceDF = CSV.read("data/Elspotprices.csv", DataFrame, decimal=',')
    prodDF = CSV.read("data/Forecasts_Hour.csv", DataFrame, decimal=',')
    # Number of days used to create scenarios, max 20
    priceDays = 20
    prodDays = 20
    imbalanceScens = 3
    imbalance = zeros(3,24)
    Random.seed!(1234)
    for i in 1:3
        imbalance[i,:] = rand(Bool, 24)
    end
    # Creating an array containing 1200 scenarios of 24 hours containing 3 values (price, prod, imbalance)
    scenarios = zeros(Float32, priceDays*prodDays*imbalanceScens, 24, 3)
    currScen = 1
    for i in range(1,priceDays)
        for j in range(1, prodDays)
            for u in range(1, imbalanceScens)
                # Setting price
                scenarios[currScen, :, 1] = priceDF[i:(i+23),5] #column 5 is spot price in EU/MWh
                # Setting prod
                scenarios[currScen, :, 2] = prodDF[j:(j+23),9] #column 9 is current forecast in MWh/h
                # Setting deficit
                scenarios[currScen, :, 3] = imbalance[u,:]
                # Advancing scenarios
                currScen += 1
            end
        end
    end
    return scenarios
end
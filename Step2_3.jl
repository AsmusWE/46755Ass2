using Plots
using StatsPlots

include("ScenGen2.jl")
include("Step2_1ALSOX.jl")

profiles = 200
training_profiles = 50
p = [0.0 0.1 0.2 0.5 1] # 1-"p90" values
ALSOX_C_0 = solve_ALSOX(p[1], profiles, training_profiles)
ALSOX_C_1 = solve_ALSOX(p[2], profiles, training_profiles)
ALSOX_C_2 = solve_ALSOX(p[3], profiles, training_profiles)
ALSOX_C_5 = solve_ALSOX(p[4], profiles, training_profiles)
ALSOX_C_10 = solve_ALSOX(p[5], profiles, training_profiles)

C_vals = [ALSOX_C_0, ALSOX_C_1, ALSOX_C_2, ALSOX_C_5, ALSOX_C_10]

Profiles = generate_load_profiles(profiles) # Shape is [scenarios, minutes]
TestProfiles = Profiles[training_profiles+1:end]

ALSOX_fails = Float32[0, 0, 0, 0, 0]
ALSOX_shortfall = Float32[0, 0, 0, 0, 0]

for c in range(1,length(C_vals)) # Looping over p90 values
    for i in TestProfiles # Looping over scenarios
        violations_ALSOX = 0
        for j in i # Looping over minutes
            if j < C_vals[c] # If the load is less than the bid
                violations_ALSOX += 1
                ALSOX_shortfall[c] += C_vals[c] - j # Add the difference to the shortfall
            end
        end
        if violations_ALSOX > p[c]*60 # If the number of violations is greater than the accepted value
            ALSOX_fails[c] += 1 # Add to the number of fails
        end
    end
end


PlotProfiles = mapreduce(permutedims, vcat, TestProfiles)
PlotProfiles = convert(Array{Float64,2}, PlotProfiles)


for (i, c_val) in enumerate(C_vals)
    if i == 1
        hline([c_val], label="ALSOX_C_$(p[i])", color=i, linewidth=2)
        else
        hline!([c_val], label="ALSOX_C_$(p[i])", color=i, linewidth=2)
    end
end
errorline!(1:60,transpose(PlotProfiles), errorstyle = :plume, ylims = (0, 510), label = "Scenarios")

#plot!(1:60, C_vals, label="ALSOX_C values")

#plot!(TestProfiles ,alpha=0.1, color=:blue)
#plot!(mean_TestProfiles, label="Mean Test Profiles")
#plot!(C_vals, label="ALSOX_C values")

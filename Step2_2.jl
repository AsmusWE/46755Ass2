
include("ScenGen2.jl")
include("Step2_1ALSOX.jl")
include("Step2_1CVar.jl")

ALSOX_C = solve_ALSOX()
CVaR_C = solve_CVaR()

Profiles = generate_load_profiles(200) # Shape is [scenarios, minutes]
#TestProfiles = Profiles[51:200]
TestProfiles = Profiles[1:50]

global ALSOX_fails = 0
global CVaR_fails = 0
global ALSOX_shortfall = 0
global CVaR_shortfall = 0

for i in TestProfiles # Looping over scenarios
    violations_ALSOX = 0
    violations_CVaR = 0
    for j in i # Looping over minutes
        if j < ALSOX_C # If the load is less than the bid
            violations_ALSOX += 1
            global ALSOX_shortfall += ALSOX_C - j # Add the difference to the shortfall
        end
        if j < CVaR_C
            violations_CVaR += 1
            global CVaR_shortfall += CVaR_C - j
        end
    end
    if violations_ALSOX > 0.1*60 # If the number of violations is greater than the accepted value
        global ALSOX_fails += 1 # Add to the number of fails
    end
    if violations_CVaR > 0.1*60
        global CVaR_fails += 1
    end
end



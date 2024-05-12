
include("ScenGen2.jl")
include("Step2_1ALSOX.jl")
include("Step2_1CVar.jl")


ALSOX_C, ALSOX_C_Time = @timed solve_ALSOX()
CVaR_C, CVaR_C_Time = @timed solve_CVaR()


Profiles = generate_load_profiles(200) # Shape is [scenarios, minutes]
TestProfiles = Profiles[51:200]
#TestProfiles = Profiles[1:50]

global ALSOX_shortfall = 0
global CVaR_shortfall = 0

for i in TestProfiles # Looping over scenarios
    for j in i # Looping over minutes
        if j < ALSOX_C # If the load is less than the bid
            global ALSOX_shortfall += ALSOX_C - j # Add the difference to the shortfall
        end
        if j < CVaR_C
            global CVaR_shortfall += CVaR_C - j
        end
    end
end

# Profiles in which the p90 requirement is violated
sum(sum(ALSOX_C .> w) > 0.1*60 for w in TestProfiles ) #out-of-sample
sum(sum(CVaR_C .> w) > 0.1*60 for w in TestProfiles ) #out-of-sample
sum(sum(ALSOX_C .> w) > 0.1*60 for w in Profiles[1:50] ) #in-sample
sum(sum(CVaR_C .> w) > 0.1*60 for w in Profiles[1:50] ) #in-sample
# Sum of p90 violations:
sum(sum(ALSOX_C .> w) for w in Profiles[1:50] ) #301 > 300 so the p90 requirement is violated?
#sum(sum(round(ALSOX_C) .> w) for w in Profiles[1:50] ) #293 < 300, p90 requirement fulfilled
sum(sum(CVaR_C .> w) for w in Profiles[1:50] ) #CVaR is conservative so naturally p90 requirement is fulfilled
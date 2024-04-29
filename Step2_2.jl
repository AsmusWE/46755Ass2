
include("ScenGen2.jl")
include("Step2_1ALSOX.jl")
include("Step2_1CVar.jl")

ALSOX_C = solve_ALSOX()
CVaR_C = solve_CVaR()

Profiles = generate_load_profiles(200) # Shape is [scenarios, minutes]
TestProfiles = Profiles[51:200]


global ALSOX_fails = 0
global CVaR_fails = 0
global ALSOX_shortfall = 0
global CVaR_shortfall = 0

for i in TestProfiles
    violations_ALSOX = 0
    violations_CVaR = 0
    for j in i
        if j < ALSOX_C
            violations_ALSOX += 1
            global ALSOX_shortfall += ALSOX_C - j
        end
        if j < CVaR_C
            violations_CVaR += 1
            global CVaR_shortfall += CVaR_C - j
        end
    end
    if violations_ALSOX > 0.9*60
        global ALSOX_fails += 1
    end
    if violations_CVaR > 0.9*60
        global CVaR_fails += 1
    end
end



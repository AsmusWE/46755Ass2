include("ScenGen2.jl")
include("Step2_1ALSOX.jl")

# TODO check why ALSOX_C_0 is highest
# TODO check why ALSOX_C_1 doesn't result in the same as step2_2

ALSOX_C_0 = solve_ALSOX(0.0)
ALSOX_C_1 = solve_ALSOX(0.1)
ALSOX_C_2 = solve_ALSOX(0.2)

C_vals = [ALSOX_C_0, ALSOX_C_1, ALSOX_C_2]

Profiles = generate_load_profiles(200) # Shape is [scenarios, minutes]
TestProfiles = Profiles[51:200]

global ALSOX_fails = Float32[0, 0, 0]
global ALSOX_shortfall = Float32[0, 0, 0]

for c in Int64(length(C_vals))
    for i in TestProfiles
        violations_ALSOX = 0
        for j in i
            if j < C_vals[c]
                violations_ALSOX += 1
                global ALSOX_shortfall[c] += C_vals[c] - j
            end
        end
        if violations_ALSOX > 0.9*60
            global ALSOX_fails[c] += 1
        end
    end
end
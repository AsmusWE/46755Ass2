include("ScenGen2.jl")
include("Step2_1ALSOX.jl")

# TODO check why ALSOX_C_0 is highest
# TODO check why ALSOX_C_1 doesn't result in the same as step2_2

p = [0.0 0.1 0.2] # 1-"p90" values
ALSOX_C_0 = solve_ALSOX(p[1])
ALSOX_C_1 = solve_ALSOX(p[2])
ALSOX_C_2 = solve_ALSOX(p[3])

C_vals = [ALSOX_C_0, ALSOX_C_1, ALSOX_C_2]

Profiles = generate_load_profiles(200) # Shape is [scenarios, minutes]
TestProfiles = Profiles[51:200]

ALSOX_fails = Float32[0, 0, 0]
ALSOX_shortfall = Float32[0, 0, 0]

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
using Random
function generate_load_profiles(num_profiles)
    Random.seed!(123)
    profiles = []
    for _ in 1:num_profiles
        profile = []
        current_load = rand(200:500)
        push!(profile, current_load)
        
        for _ in 2:60
            next_load = current_load + rand(-25:25)
            next_load = max(200, min(500, next_load))
            push!(profile, next_load)
            current_load = next_load
        end
        
        push!(profiles, profile)
    end
    
    return profiles
end

num_profiles = 200
load_profiles = generate_load_profiles(num_profiles)
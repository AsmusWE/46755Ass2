#function ALSOX(delta)
using JuMP, Gurobi
using Plots
include("ScenGen2.jl")


function solve_relaxed(q, profiles, training_profiles)
    Profiles = generate_load_profiles(profiles) # Shape is [scenarios, minutes]
    F_up = Profiles[1:training_profiles] 
    M = 300 # Largest possible violation
    len_m = 60
    Ω = 50

    #************************************************************************
    # MODEL
    Step2_1 = Model(Gurobi.Optimizer)
    set_silent(Step2_1)

    @variable(Step2_1, 0 <= y[1:len_m,1:Ω] <= 1)
    @variable(Step2_1, 0 <= c_up)

    @objective(Step2_1, Max, c_up)

    @constraint(Step2_1, [m=1:len_m, ω=1:Ω], 
        c_up - F_up[ω][m] <= y[m,ω] * M)
    @constraint(Step2_1, sum(y[m,ω] for m = 1:len_m, ω = 1:Ω) <= q)

    #************************************************************************

    #************************************************************************
    # SOLVE
    set_time_limit_sec(Step2_1,30)
    solution = optimize!(Step2_1)
    println("Termination status: $(termination_status(Step2_1))")
    #************************************************************************

    #************************************************************************
    # SOLUTION
    if termination_status(Step2_1) == MOI.OPTIMAL
        println("RESULTS:")
        printstyled("objective = $(objective_value(Step2_1))\n";color= :blue)
    end
    #************************************************************************
    return value.(y), value(c_up)
end


function solve_ALSOX(ϵ = 0.1, profiles = 200, training_profiles = 50)
    delta = 10^(-5)
    samples = training_profiles

    q_low = 0
    q_high = ϵ * samples^2
    q = 0

    while q_high-q_low >= delta
        q = (q_low + q_high) / 2
        solution = solve_relaxed(q, profiles, training_profiles)[1]
        count_zeros = sum(solution .== 0)
        count_zeros = count_zeros/(samples*60)
        if count_zeros >= (1-ϵ)
            q_low = q
        else
            q_high = q
        end
    end
    best_c = solve_relaxed(q, profiles, training_profiles)[2]
    return best_c
end

@timed solve_ALSOX()
 







#function ALSOX(delta)
using JuMP, Gurobi
using Plots
include("ScenGen2.jl")


function solve_relaxed(q)
    Profiles = generate_load_profiles(200) # Shape is [scenarios, minutes]
    F_up = Profiles[1:50] 
    M = 300 # Largest possible violation
    len_m = 60
    Ω = 50

    #************************************************************************
    # MODEL
    Step2_1 = Model(Gurobi.Optimizer)

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


function solve_ALSOX(ϵ = 0.1)
    delta = 10^(-5)
    samples = 50

    global q_low = 0
    global q_high = ϵ * samples^2

    while q_high-q_low >= delta
        global q = (q_low + q_high) / 2
        solution = solve_relaxed(q)[1]
        count_zeros = sum(solution .== 0)
        if count_zeros >= 1-ϵ
            global q_low = q
        else
            global q_high = q
        end
    end
    best_c = solve_relaxed(q)[2]
    return best_c
end

solve_ALSOX()
 







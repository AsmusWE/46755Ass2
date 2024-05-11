using JuMP, Gurobi
using Plots
include("ScenGen2.jl")


function solve_CVaR()
    Profiles = generate_load_profiles(200) # Shape is [scenarios, minutes]
    F_up = Profiles[1:50] 
    len_m = 60
    Ω = 50
    ϵ = 0.1

    #************************************************************************
    # MODEL
    Step2_1 = Model(Gurobi.Optimizer)
    set_silent(Step2_1)

    @variable(Step2_1, 0 <= c_up)
    @variable(Step2_1, β<=0)
    @variable(Step2_1, ζ[m=1:len_m,ω=1:Ω])

    @objective(Step2_1, Max, c_up)

    @constraint(Step2_1, [m=1:len_m, ω=1:Ω], 
                c_up - F_up[ω][m] <= ζ[m,ω])

    @constraint(Step2_1, 1/(len_m*Ω) * sum(ζ[m,ω] for m = 1:len_m, ω = 1:Ω) <= (1-ϵ)β)

    @constraint(Step2_1, quad_term[m = 1:len_m, ω = 1:Ω], β <= ζ[m,ω])

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
    return value(c_up)
end

@timed solve_CVaR()
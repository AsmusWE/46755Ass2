using JuMP, Gurobi
using Plots

include("ScenGen.jl")
scenarios = GenScens() #scenarios, t, price prod imbalance

lambda_DA = scenarios[:,:,1]
p_real = scenarios[:,:,2] #COMMENT: should be normalized to the 200 MW wind farm size in the assignment!!
Imbalance = scenarios[:,:,3]

T = collect(1:size(scenarios)[2])
W = collect(1:size(scenarios)[1])

prob = ones(W[end])/W[end] #COMMENT: should not be all scenarios but only 250 out of 1200!!
P_nom = 200 #MW



#************************************************************************
# MODEL
Step1_2 = Model(Gurobi.Optimizer)

@variable(Step1_2, 0 <= p_DA[t in T] <= P_nom) #Electricity offered in DA market
@variable(Step1_2, delta_t[w in W, t in T]) #Realised difference in generation and offer in DA, auxiliary
@variable(Step1_2, 0 <= delta_tup[w in W, t in T]) #Realised production SURPLUS relative to DA offer
@variable(Step1_2, 0 <= delta_tdown[w in W, t in T]) #Realised production DEFICIT relative to DA offer
@variable(Step1_2, I_B[w in W, t in T]) #The profit balance in balancing market

@objective(Step1_2, Max,
            sum( prob[w] * sum( lambda_DA[w,t]*p_DA[t] + I_B[w,t] for t in T) for w in W))

@constraint(Step1_2, [w in W, t in T],
            delta_t[w,t] == p_real[w,t] - p_DA[t])
@constraint(Step1_2, [w in W, t in T],
            delta_t[w,t] == delta_tup[w,t] - delta_tdown[w,t])
@constraint(Step1_2, [w in W, t in T],
            I_B[w,t] <= -Imbalance[w,t]*lambda_DA[w,t]*delta_tdown[w,t] #System surplus, WF deficit, pay @ DA price
                        -(1-Imbalance[w,t])*1.2*lambda_DA[w,t]*delta_tdown[w,t] #System deficit, WF deficit, pay @ 1.2*DA price
                        +Imbalance[w,t]*0.9*lambda_DA[w,t]*delta_tup[w,t] #System surplus, WF surplus, earn @ 0.9*DA price
                        +(1-Imbalance[w,t])*lambda_DA[w,t]*delta_tup[w,t]) #System deficit, WF surplus, earn @ DA price
#************************************************************************

#************************************************************************
# SOLVE
set_time_limit_sec(Step1_2,30)
solution = optimize!(Step1_2)
println("Termination status: $(termination_status(Step1_2))")
#************************************************************************

#************************************************************************
# SOLUTION
if termination_status(Step1_2) == MOI.OPTIMAL
    println("RESULTS:")
    printstyled("objective = $(objective_value(Step1_2))\n";color= :blue)
end
#************************************************************************

#************************************************************************
# PLOT - profit distribution over scenarios
Profits = zeros(W[end])
delta_tup = zeros(W[end],T[end])
delta_tdown = zeros(W[end],T[end]) #could have been declared inside loop to avoid the W-dimension, but to be consistent with model formulation it is placed out here

for w in W
    DA_prof = sum(lambda_DA[w,t] * value(p_DA[t]) for t in T)
    #delta_t[w,t] == p_real[w,t] - p_DA[t]
    #delta_t[w,t] == delta_tup[w,t] - delta_tdown[w,t]
    for t in T
        if(p_real[w,t] - value(p_DA[t]) >= 0)
            delta_tup[w,t] = p_real[w,t] - value(p_DA[t])
            delta_tdown[w,t] = 0
        else 
            delta_tdown[w,t] = value(p_DA[t]) - p_real[w,t]
            delta_tup[w,t] = 0
        end
    end
    balancing_prof = sum(
                        -Imbalance[w,t]*lambda_DA[w,t]*delta_tdown[w,t] #System surplus, WF deficit, pay @ DA price
                        -(1-Imbalance[w,t])*1.2*lambda_DA[w,t]*delta_tdown[w,t] #System deficit, WF deficit, pay @ 1.2*DA price
                        +Imbalance[w,t]*0.9*lambda_DA[w,t]*delta_tup[w,t] #System surplus, WF surplus, earn @ 0.9*DA price
                        +(1-Imbalance[w,t])*lambda_DA[w,t]*delta_tup[w,t] for t in T)
    Profits[w] = DA_prof + balancing_prof
end
print("So the average profits are: €", round(sum(Profits)/W[end],digits=1))

histogram(Profits, label="Scenarios", xlabel="Profit [€]", ylabel="Frequency") #add vline at expected price
#plot(Profits, label="label", xlabel="Scenario", ylabel="Profit [€]")
#************************************************************************
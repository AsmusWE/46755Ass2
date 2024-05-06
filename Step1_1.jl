using JuMP, Gurobi
using Plots, Distributions

include("ScenGen.jl")
scenarios = GenScens() #scenarios, t, price prod imbalance

T = collect(1:24)
W_tot = collect(1:1200)

num_samples = 250

Random.seed!(2300) #1, 23, 1212, 4242  #set to overrule 'Random.seed!(1234)' from 'Scengen.jl'

samples = sample(W_tot, num_samples, replace=false) #collect(1:250) #
W = collect(1:num_samples)

lambda_DA = scenarios[samples,:,1]
p_real = scenarios[samples,:,2] 
Imbalance = scenarios[samples,:,3]
# Imbalance[:,1] .= 1
# Imbalance[181:240,1] .= 0
# Imbalance[61:83,1] .= 0 #0.668, h=1, p_DA = 0
# Imbalance[:,1] .= 1
# Imbalance[1:60,1] .= 0
# Imbalance[61:83,1] .= 0 #0.668, h=1, p_DA = 200


prob = ones(num_samples) ./ num_samples 
P_nom = 200 #MW

#************************************************************************
# MODEL
Step1_1 = Model(Gurobi.Optimizer)

@variable(Step1_1, 0 <= p_DA[t in T] <= P_nom) #Electricity offered in DA market
@variable(Step1_1, delta_t[w in W, t in T]) #Realised difference in generation and offer in DA, auxiliary
@variable(Step1_1, I_B[w in W, t in T]) #The profit balance in balancing market

@objective(Step1_1, Max,
            sum( prob[w] * sum( lambda_DA[w,t]*p_DA[t] + I_B[w,t] for t in T) for w in W))

@constraint(Step1_1, [w in W, t in T],
            delta_t[w,t] == p_real[w,t] - p_DA[t])
@constraint(Step1_1, [w in W, t in T],
            I_B[w,t] <= (Imbalance[w,t]*0.9 + (1-Imbalance[w,t])*1.2) * lambda_DA[w,t] * delta_t[w,t])
            #Firstly, in the purple parenthesis, the balancing market price is set by the system imbalance
            #Secondly, the sign of delta_t[w,t] then tells us whether the WF is earning or losing money @ the balancing market price
#************************************************************************

#************************************************************************
# SOLVE
set_time_limit_sec(Step1_1,30)
solution = optimize!(Step1_1)
println("Termination status: $(termination_status(Step1_1))")
#************************************************************************

#************************************************************************
# SOLUTION
if termination_status(Step1_1) == MOI.OPTIMAL
    println("RESULTS:")
    printstyled("objective = $(objective_value(Step1_1))\n";color= :blue)
end
#************************************************************************

#************************************************************************
# PLOT - profit distribution over scenarios
Profits = zeros(W[end])
DA_prof = zeros(W[end])
balancing_prof = zeros(W[end])
for w in W
    DA_prof[w] = sum(lambda_DA[w,t] * value(p_DA[t]) for t in T)
    balancing_prof[w] = sum( (Imbalance[w,t]*0.9 + (1-Imbalance[w,t])*1.2) * lambda_DA[w,t] * (p_real[w,t] - value(p_DA[t])) for t in T)
    Profits[w] = DA_prof[w] + balancing_prof[w]
end
print("So the average profits are: €", round(sum(Profits)/W[end],digits=1))

histogram(Profits, label="Scenarios", xlabel="Profit [€]", ylabel="Frequency", bins=25) #add vline at expected price
#plot(Profits, label="label", xlabel="Scenario", ylabel="Profit [€]")
#************************************************************************


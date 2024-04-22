using JuMP, Gurobi
include("ScenGen.jl")
scenarios = GenScens() #scenarios, t, price prod imbalance

lambda_DA = scenarios[:,:,1]
p_real = scenarios[:,:,2] #COMMENT: should be normalized to the 200 MW wind farm size in the assignment!!
Imbalance = scenarios[:,:,3]

T = collect(1:size(scenarios)[2])
W = collect(1:size(scenarios)[1])

prob = ones(W[end])/W[end] #COMMENT: should not be all scenarios but only 250 out of 1200!!
P_nom = 200 #MW
alpha = 0.9
beta = 0 # code in a way that beta can be increased gradually and the results are saved


#************************************************************************
# MODEL
Step1_3_1 = Model(Gurobi.Optimizer)

@variable(Step1_3_1, 0 <= p_DA[t in T] <= P_nom) #Electricity offered in DA market
@variable(Step1_3_1, delta_t[w in W, t in T]) #Realised difference in generation and offer in DA, auxiliary
@variable(Step1_3_1, I_B[w in W, t in T]) #The profit balance in balancing market
@variable(Step1_3_1, zeta) #NEW: This is actually the VaR!
@variable(Step1_3_1, 0 <= eta[w in W]) #NEW: This is used for the CVaR

@objective(Step1_3_1, Max,
           (1-beta)*(sum( prob[w] * sum( lambda_DA[w,t]*p_DA[t] + I_B[w,t] for t in T) for w in W))
            + beta*(zeta - (1/(1-alpha))*sum(prob[w] * eta[w] for w in W))) #NEW: disregarding 'beta' this term is the CVaR!

@constraint(Step1_3_1, [w in W, t in T],
            delta_t[w,t] == p_real[w,t] - p_DA[t])
@constraint(Step1_3_1, [w in W, t in T],
            I_B[w,t] <= (Imbalance[w,t]*0.9 + (1-Imbalance[w,t])*1.2) * lambda_DA[w,t] * delta_t[w,t])
            #Firstly, in the purple parenthesis, the balancing market price is set by the system imbalance
            #Secondly, the sign of delta_t[w,t] then tells us whether the WF is earning or losing money @ the balancing market price
@constraint(Step1_3_1, [w in W],
            -sum( lambda_DA[w,t]*p_DA[t] + I_B[w,t] for t in T) + zeta - eta[w] <= 0)
#************************************************************************

#************************************************************************
# SOLVE
set_time_limit_sec(Step1_3_1,30)
solution = optimize!(Step1_3_1)
println("Termination status: $(termination_status(Step1_3_1))")
#************************************************************************

#************************************************************************
# SOLUTION
if termination_status(Step1_3_1) == MOI.OPTIMAL
    println("RESULTS:")
    printstyled("objective = $(objective_value(Step1_3_1))\n";color= :blue)
end
#************************************************************************

#************************************************************************
# PLOT - profit distribution over scenarios
Profits = zeros(W[end])
for w in W
    DA_prof = sum(lambda_DA[w,t] * value(p_DA[t]) for t in T)
    balancing_prof = sum( (Imbalance[w,t]*0.9 + (1-Imbalance[w,t])*1.2) * lambda_DA[w,t] * (p_real[w,t] - value(p_DA[t])) for t in T)
    Profits[w] = DA_prof + balancing_prof
end
print("So the average profits are: €", round(sum(Profits)/W[end],digits=1))

histogram(Profits, label="Scenarios", xlabel="Profit [€]", ylabel="Frequency") #add vline at expected price
#plot(Profits, label="label", xlabel="Scenario", ylabel="Profit [€]")
#************************************************************************
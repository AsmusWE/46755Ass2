using JuMP, Gurobi
using Plots, Distributions

include("ScenGen.jl")
scenarios = GenScens() #scenarios, t, price prod imbalance

T = collect(1:24)
W_tot = collect(1:1200)

num_samples = 250

samples = sample(W_tot, num_samples, replace=false) #collect(1:250)
W = collect(1:num_samples)

lambda_DA = scenarios[samples,:,1]
p_real = scenarios[samples,:,2] 
Imbalance = scenarios[samples,:,3]

prob = ones(num_samples) ./ num_samples 
P_nom = 200 #MW

alpha = 0.9
betavars = 10
beta = collect(Float64,0:1:10) ./ betavars # code in a way that beta can be increased gradually and the results are saved
#beta = collect(Float64,0:1:10) ./ (betavars*1000)

DA_decs = zeros(betavars+1,24)
VaR = zeros(betavars+1)
CVaR = zeros(betavars+1)
Profit = zeros(betavars+1)

for b in 1:betavars+1
    #************************************************************************
    # MODEL        
    Step1_3_2 = Model(Gurobi.Optimizer)

    @variable(Step1_3_2, 0 <= p_DA[t in T] <= P_nom) #Electricity offered in DA market
    @variable(Step1_3_2, delta_t[w in W, t in T]) #Realised difference in generation and offer in DA, auxiliary
    @variable(Step1_3_2, 0 <= delta_tup[w in W, t in T]) #Realised production SURPLUS relative to DA offer
    @variable(Step1_3_2, 0 <= delta_tdown[w in W, t in T]) #Realised production DEFICIT relative to DA offer
    @variable(Step1_3_2, I_B[w in W, t in T]) #The profit balance in balancing market
    @variable(Step1_3_2, zeta) #NEW: This is actually the VaR!
    @variable(Step1_3_2, 0 <= eta[w in W]) #NEW: This is used for the CVaR

    @objective(Step1_3_2, Max,
            (1-beta[b])*(sum( prob[w] * sum( lambda_DA[w,t]*p_DA[t] + I_B[w,t] for t in T) for w in W))
                + beta[b]*(zeta - (1/(1-alpha))*sum(prob[w] * eta[w] for w in W))) #NEW: disregarding 'beta' this term is the CVaR!

    @constraint(Step1_3_2, [w in W, t in T],
                delta_t[w,t] == p_real[w,t] - p_DA[t])
    @constraint(Step1_3_2, [w in W, t in T],
                delta_t[w,t] == delta_tup[w,t] - delta_tdown[w,t])
    @constraint(Step1_3_2, [w in W, t in T],
                I_B[w,t] <= -Imbalance[w,t]*lambda_DA[w,t]*delta_tdown[w,t] #System surplus, WF deficit, pay @ DA price
                -(1-Imbalance[w,t])*1.2*lambda_DA[w,t]*delta_tdown[w,t] #System deficit, WF deficit, pay @ 1.2*DA price
                +Imbalance[w,t]*0.9*lambda_DA[w,t]*delta_tup[w,t] #System surplus, WF surplus, earn @ 0.9*DA price
                +(1-Imbalance[w,t])*lambda_DA[w,t]*delta_tup[w,t]) #System deficit, WF surplus, earn @ DA price

    @constraint(Step1_3_2, [w in W],
                -sum( lambda_DA[w,t]*p_DA[t] + I_B[w,t] for t in T) + zeta - eta[w] <= 0)
    #************************************************************************

    #************************************************************************
    # SOLVE
    set_time_limit_sec(Step1_3_2,30)
    solution = optimize!(Step1_3_2)
    println("Termination status: $(termination_status(Step1_3_2))")
    #************************************************************************

    #************************************************************************
    # SOLUTION
    if termination_status(Step1_3_2) == MOI.OPTIMAL
        println("RESULTS:")
        printstyled("objective = $(objective_value(Step1_3_2))\n";color= :blue)
    end
    #************************************************************************
    DA_decs[b,:] = value.(p_DA)
    VaR[b] = value(zeta)
    CVaR[b] = value(zeta) - (1/(1-alpha))*sum(prob[w] * value(eta[w]) for w in W)
    Profit[b] = sum( prob[w] * sum( lambda_DA[w,t]*value(p_DA[t]) + value(I_B[w,t]) for t in T) for w in W)
end

#************************************************************************
# PLOT - Markowitz curve
scatter(CVaR,Profit, label=false, color=:red, markershape=:x)
plot_Markowitz = plot!(CVaR,Profit, label="Dual-price", color=:red, xlabel="CVaR [€]", ylabel="Profit [€]", title="Markowitz curve")
hcat(beta, DA_decs)
label_DA_decs = permutedims(["h=$t" for t in T]) #we need row vector
ylimit = max(maximum(DA_decs[:,1:5]), maximum(DA_decs[:,7:24])) #only 6 was at 200, so otherwise the plot is not as useful
plot_DA = plot(beta, DA_decs, label=label_DA_decs, xlabel="β [-]", ylabel="pDA [MWh]",
    ylim=[0,ylimit], title="Trend in DA decisions", legend=:topright)

plot_sumDA = plot(beta, sum(DA_decs,dims=2), label=label_DA_decs, xlabel="β [-]", ylabel="pDA [MWh]",
    title="Trend in DA decisions", legend=:topright)

plot(plot_Markowitz, plot_sumDA, layout=(1,2), dpi=1000, size=(900,500), margin=5Plots.mm)

plot_Imb = plot(mean(Imbalance,dims=1)[1,:], legend=false)
hline!([2/3])
plot(plot_DA, plot_Imb, layout=(1,2), dpi=1000, size=(900,500), margin=5Plots.mm)
#savefig("Markowitz_DAdecs.png")
#************************************************************************

#************************************************************************ - this only works for the last beta value
# PLOT - profit distribution over scenarios
# Profits = zeros(W[end])
# for w in W
#     DA_prof = sum(lambda_DA[w,t] * value(p_DA[t]) for t in T)
#     balancing_prof = sum( (Imbalance[w,t]*0.9 + (1-Imbalance[w,t])*1.2) * lambda_DA[w,t] * (p_real[w,t] - value(p_DA[t])) for t in T)
#     Profits[w] = DA_prof + balancing_prof
# end
# print("So the average profits are: €", round(sum(Profits)/W[end],digits=1))

# histogram(Profits, label="Scenarios", xlabel="Profit [€]", ylabel="Frequency") #add vline at expected price
#plot(Profits, label="label", xlabel="Scenario", ylabel="Profit [€]")
#************************************************************************
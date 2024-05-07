using JuMP, Gurobi
using Plots, Distributions

include("ScenGen.jl")
scenarios = GenScens() #scenarios, t, price prod imbalance

T = collect(1:24)
W_tot = collect(1:1200)

num_samples = 250#-1

samples = sample(W_tot, num_samples, replace=false) #collect(1:250)
W = collect(1:num_samples)

#samples = W

lambda_DA = scenarios[samples,:,1]
p_real = scenarios[samples,:,2] 
Imbalance = scenarios[samples,:,3]

#PLOTTING and inspecting the data#
p_real_l = reshape(p_real, (num_samples*T[end],1))
lambda_DA_l = reshape(lambda_DA, (num_samples*T[end],1))
hist_seen=histogram2d(p_real_l, lambda_DA_l, show_empty_bins=true,
    normalize=:pdf, color=:plasma, margin=5Plots.mm) #bins=(45, 25),
title!("Diversity of (SEEN) input - 2D Histogram")
xlabel!("Power generation [MW]")
ylabel!("Spot price [€/MWh]")
##################################

prob = ones(num_samples) ./ num_samples 
P_nom = 200 #MW

alpha = 0.90
betavars = 10
beta = collect(Float64,0:1:10) ./ betavars # code in a way that beta can be increased gradually and the results are saved
#beta = collect(Float64,0:1:10) ./ (betavars*1000)

DA_decs = zeros(betavars+1,24)
VaR = zeros(betavars+1)
CVaR = zeros(betavars+1)
Profit = zeros(betavars+1)
CVaR_test = zeros(betavars+1)
CVaR_test_VaR_part = zeros(betavars+1)

Profits_w = zeros(betavars+1,W[end])
DA_prof_w = zeros(betavars+1,W[end])
balancing_prof_w = zeros(betavars+1,W[end])

for b in 1:betavars+1
    #************************************************************************
    # MODEL
    Step1_3_1 = Model(Gurobi.Optimizer)

    @variable(Step1_3_1, 0 <= p_DA[t in T] <= P_nom) #Electricity offered in DA market
    @variable(Step1_3_1, delta_t[w in W, t in T]) #Realised difference in generation and offer in DA, auxiliary
    @variable(Step1_3_1, I_B[w in W, t in T]) #The profit balance in balancing market
    @variable(Step1_3_1, zeta) #NEW: This is actually the VaR!
    @variable(Step1_3_1, 0 <= eta[w in W]) #NEW: This is used for the CVaR

    @objective(Step1_3_1, Max,
            (1-beta[b]) * sum( prob[w] * sum( lambda_DA[w,t]*p_DA[t] + I_B[w,t] for t in T) for w in W)
                + beta[b]*(zeta - (1/(1-alpha))*sum(prob[w] * eta[w] for w in W))) #NEW: disregarding 'beta' this term is the CVaR!

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
    DA_decs[b,:] = value.(p_DA)
    VaR[b] = value(zeta)
    CVaR[b] = value(zeta) - (1/(1-alpha))*sum(prob[w] * value(eta[w]) for w in W)
    Profit[b] = sum( prob[w] * sum( lambda_DA[w,t]*value(p_DA[t]) + value(I_B[w,t]) for t in T) for w in W)
    #the two arrays below are used to show some stuff "mathematically"
    CVaR_test[b] = VaR[b] - 1/(1-alpha) * VaR[b]*sum( prob[w]*(value(eta[w]) > 0 ? 1 : 0) for w in W) + 1/(1-alpha)*sum( prob[w]*(value(eta[w]) > 0 ? 1 : 0)*sum( lambda_DA[w,t]*value(p_DA[t]) + value(I_B[w,t]) for t in T) for w in W)
    CVaR_test_VaR_part[b] = VaR[b] - 1/(1-alpha) * VaR[b]*sum( prob[w]*(value(eta[w]) > 0 ? 1 : 0) for w in W)

    
    for w in W
        DA_prof_w[b,w] = sum(lambda_DA[w,t] * value(p_DA[t]) for t in T)
        balancing_prof_w[b,w] = sum( value(I_B[w,t]) for t in T)
        Profits_w[b,w] = DA_prof_w[b,w] + balancing_prof_w[b,w]
    end
end

#************************************************************************
# PLOT - Markowitz curve
scatter(CVaR,Profit, label=false, color=palette(:tab10), markershape=:x)
plot_Markowitz = plot!(CVaR,Profit, label="Single-price", xlabel="CVaR [€]", ylabel="Profit [€]", color=palette(:tab10), title="Markowitz curve")
hcat(beta, DA_decs)
label_DA_decs = permutedims(["h=$t" for t in T]) #we need row vector
ylimit = max(maximum(DA_decs[:,1:5]), maximum(DA_decs[:,7:24])) #otherwise the plot is not as useful
plot_DA = plot(beta, DA_decs, label=label_DA_decs, xlabel="β [-]", ylabel="pDA [MWh]",
    ylim=[0,ylimit], title="Trend in DA decisions", legend=:topright, color=palette(:tab10))
plot_sumDA = plot(beta, sum(DA_decs,dims=2), label=false, xlabel="β [-]", ylabel="pDA [MWh]",
    title="Trend in DA decisions", legend=:topright,color=palette(:tab10))
plot(plot_Markowitz, plot_sumDA, layout=(1,2), dpi=800, size=(900,500), margin=5Plots.mm)

plot_Imb = plot(mean(Imbalance,dims=1)[1,:], legend=false,color=palette(:tab10))
hline!([2/3])
plot(plot_DA, plot_Imb, layout=(1,2), dpi=800, size=(900,500), margin=5Plots.mm)
#************************************************************************

#************************************************************************ - this only works for the last beta value
# PLOT - profit distribution over scenarios

# beta_list = [0.0 0.2 0.5 1.0]
# beta_ind_list = [findfirst(beta .== beta_list[b]) for b in 1:length(beta_list)]
# hists=repeat([histogram(mean(lambda_DA,dims=1)[1,:])], length(hist_list)) #make hist array
# for b in 1:length(beta_list)
#     hists[b] = histogram(DA_prof_w[beta_ind_list[b],:], label="DA distribution β=$(beta_list[b])",
#     bins=25, normalize=true, xlabel="Profit (DA) [€]", ylabel="Probability")
#     histogram!(balancing_prof_w[beta_ind_list[b],:], label="Balancing distribution β=$(beta_list[b])",
#     bins=25, normalize=true, xlabel="Profit (balancing) [€]", ylabel="Probability", alpha=0.67)
#     vline!([VaR[beta_ind_list[b]]], label="VaR", color=:red)
# end
# plot(hists..., layout=(2,2), size=(950,550),margin=5Plots.mm, title="Single-price")

beta_list = [0.0 0.1 0.5 1.0]
beta_ind_list = [findfirst(beta .== beta_list[b]) for b in 1:length(beta_list)]
hists=repeat([histogram(mean(lambda_DA,dims=1)[1,:])], length(hist_list)) #make hist array
for b in 1:length(beta_list)
    hists[b] = histogram(Profits_w[beta_ind_list[b],:], label="Profit distribution β=$(beta_list[b])",
    bins=50, normalize=true, xlabel="Profit (total) [€]", ylabel="Probability", color=palette(:tab10))
    vline!([VaR[beta_ind_list[b]]], label="VaR", linewidth=2)
end
plot(hists..., layout=(2,2), size=(950,550),margin=5Plots.mm, dpi=800)#, title="Single-price")

histogram(Profits_w[1,:], label="Profit β=$(beta[1])", color=palette(:tab10), bins=25, normalize=:true, dpi=800)
histogram!(Profits_w[11,:], label="Profit β=$(beta[11])", alpha=0.75, bins=25, normalize=:true, 
    xlabel="Profit [total] €", ylabel="Probability", title="Single-price", dpi=800)
# histogram(Profits, label="Scenarios", xlabel="Profit [€]", ylabel="Frequency") #add vline at expected price
#plot(Profits, label="label", xlabel="Scenario", ylabel="Profit [€]")
#************************************************************************
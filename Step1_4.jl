# For Step 1.1
include("Step1_1.jl")
seen = samples
unseen = W_tot[ [!(W_tot[s] in samples) for s in W_tot] ]
#sort(seen)'
#sort(unseen)'
x = sum(DA_prof) / num_samples

lambda_DA = scenarios[:,:,1]
p_real = scenarios[:,:,2] 
Imbalance = scenarios[:,:,3]

#************************************************************************
# CALCULATIONS - average balancing profit in each scenario

balancing_prof_unseen = zeros(W_tot[end])
for w in unseen
    balancing_prof_unseen[w] = sum( (Imbalance[w,t]*0.9 + (1-Imbalance[w,t])*1.2) * lambda_DA[w,t] * (p_real[w,t] - value(p_DA[t])) for t in T)
end
println("\nSo the average balancing profits for UNSEEN scenarios are: €", round(sum(balancing_prof_unseen)/length(unseen),digits=1))
println("And for the SEEN scenarios it was: ", round(sum(balancing_prof)/length(seen),digits=1))

histogram(Profits, label="Scenarios", xlabel="Profit [€]", ylabel="Frequency") #add vline at expected price
#plot(Profits, label="label", xlabel="Scenario", ylabel="Profit [€]")
#************************************************************************

# For Step 1.2
#include("Step1_2.jl")
#seen2 = samples
#unseen2 = 


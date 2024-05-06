# For Step 1.1
include("Step1_1.jl")
seen = samples
unseen = W_tot[ [!(W_tot[s] in samples) for s in W_tot] ]
#sort(seen)'
#sort(unseen)'
p_DA_star = value.(p_DA)

lambda_DA = scenarios[:,:,1]
p_real = scenarios[:,:,2] 
Imbalance = scenarios[:,:,3]

#************************************************************************
# CALCULATIONS - average balancing profit in each scenario
x = zeros(W_tot[end]) #DA profit, unseen
y = zeros(W_tot[end]) #Balancing profit, unseen
delta = zeros(W_tot[end],T[end])
balancing_prof_unseen = zeros(W_tot[end])
for w in unseen
    x[w] = sum(lambda_DA[w,t] * p_DA_star[t] for t in T)
    delta[w,:] = p_real[w,:] .- p_DA_star
    y[w] = sum( (Imbalance[w,t]*0.9 + (1-Imbalance[w,t])*1.2) * lambda_DA[w,t] * delta[w,t] for t in T)
end
println("\n\n\nThe expected profit (SEEN) is €$(round((objective_value(Step1_1)),digits=2))")
println("The average profit (UNseen) is €$(round( (sum(x)+sum(y)) / length(unseen) ,digits=2))")

println("\nThe expected earnings in the DA market for SEEN scenarios is €$(round(sum(DA_prof)/length(seen),digits=2))")
println("The average earnings in the DA market for UNseen scenarios is €$(round(sum(x)/length(unseen),digits=2))")

println("\nThe expected profit in the BALANCING market for SEEN scenarios is: €", round(sum(balancing_prof)/length(seen),digits=1))
println("The average profit in the BALANCING market for UNseen scenarios are: €", round(sum(y)/length(unseen),digits=1))

#histogram(Profits, label="Scenarios", xlabel="Profit [€]", ylabel="Frequency") #add vline at expected price
histogram(Profits, label="seen", xlabel="Profit, balancing[€]", ylabel="Frequency", color=:red, normalize=:true, bins=25)
histogram!([x+y], label="unseen", color=:blue, alpha=0.67, normalize=:true, bins=25, dpi=800)

histogram(balancing_prof, label="seen", xlabel="Profit, balancing[€]", ylabel="Frequency", color=:red, normalize=:true, bins=25)
histogram!(y, label="unseen", color=:blue, alpha=0.67, normalize=:true, bins=25, dpi=800)
#plot(Profits, label="label", xlabel="Scenario", ylabel="Profit [€]")
#************************************************************************
#************************************************************************
#************************************************************************
#************************************************************************
#************************************************************************
# For Step 1.2
#include("Step1_2.jl")

include("Step1_2.jl")
seen = samples
unseen = W_tot[ [!(W_tot[s] in samples) for s in W_tot] ]
#sort(seen)'
#sort(unseen)'
p_DA_star_2 = value.(p_DA)

lambda_DA = scenarios[:,:,1]
p_real = scenarios[:,:,2] 
Imbalance = scenarios[:,:,3]

#************************************************************************
# CALCULATIONS - average balancing profit in each scenario
x_2 = zeros(W_tot[end]) #DA profit, unseen
y_2 = zeros(W_tot[end]) #Balancing profit, unseen
delta_2 = zeros(W_tot[end],T[end])
for w in unseen
    x_2[w] = sum(lambda_DA[w,t] * p_DA_star_2[t] for t in T)
    delta_2[w,:] = p_real[w,:] .- p_DA_star_2
    y_2[w] = sum( (Imbalance[w,t]*0.9 + (1-Imbalance[w,t])*1.2) * lambda_DA[w,t] * delta_2[w,t] for t in T)
end
println("\n\n\nThe expected profit (SEEN) is €$(round((objective_value(Step1_2)),digits=2))")
println("The average profit (UNseen) is €$(round( (sum(x_2)+sum(y_2)) / length(unseen) ,digits=2))")

println("\nThe expected earnings in the DA market for SEEN scenarios is €$(round(sum(DA_prof)/length(seen),digits=2))")
println("The average earnings in the DA market for UNseen scenarios is €$(round(sum(x_2)/length(unseen),digits=2))")

println("\nThe expected profit in the BALANCING market for SEEN scenarios is: €", round(sum(balancing_prof)/length(seen),digits=1))
println("The average profit in the BALANCING market for UNseen scenarios are: €", round(sum(y_2)/length(unseen),digits=1))

#histogram(Profits, label="Scenarios", xlabel="Profit [€]", ylabel="Frequency") #add vline at expected price
histogram(Profits, label="seen", xlabel="Profit (total) [€]", ylabel="Frequency", color=:red, normalize=:true, bins=25)
histogram!([x_2+y_2], label="unseen", color=:blue, alpha=0.67, normalize=:true, bins=25, dpi=800)

histogram(balancing_prof, label="seen", xlabel="Profit (balancing) [€]", ylabel="Frequency", color=:red, normalize=:true, bins=25)
histogram!(y_2, label="unseen", color=:blue, alpha=0.67, normalize=:true, bins=25, dpi=800)

plot(mean(p_real[seen,:],dims=1)[1,:], label="seen", color=:red)
plot!(mean(p_real[unseen,:],dims=1)[1,:], label="unseen", color=:blue)


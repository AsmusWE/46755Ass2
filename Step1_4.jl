# For Step 1.1
include("Step1_1.jl")
seen = samples
unseen = W_tot[ [!(W_tot[s] in samples) for s in W_tot] ]
####Trying out other sets of 250 samples for "seen" scenarios is done by
#### changing the seed set in "Step1_1.jl" and "Step1_2.jl"

#sort(seen)'
#sort(unseen)'

lambda_DA = scenarios[:,:,1]
p_real = scenarios[:,:,2] 
Imbalance = scenarios[:,:,3]

#PLOTTING and inspecting the data###################################
p_real_l = reshape(p_real[seen,:], (num_samples*T[end],1))
lambda_DA_l = reshape(lambda_DA[seen,:], (num_samples*T[end],1))
hist_seen=histogram2d(p_real_l, lambda_DA_l, show_empty_bins=true,
    normalize=:pdf, color=:plasma, margin=5Plots.mm) #bins=(45, 25),
title!("Diversity of SEEN input - 2D Histogram")
xlabel!("Power generation [MW]")
ylabel!("Spot price [€/MWh]")

p_real_l_unseen = reshape(p_real[unseen,:], (length(unseen)*T[end],1))
lambda_DA_l_unseen = reshape(lambda_DA[unseen,:], (length(unseen)*T[end],1))
hist_unseen=histogram2d(p_real_l_unseen, lambda_DA_l_unseen, show_empty_bins=true,
    normalize=:pdf, color=:plasma, margin=5Plots.mm)#bins=(45, 25),
title!("Diversity of UNseen input - 2D Histogram")
xlabel!("Power generation [MW]")
ylabel!("Spot price [€/MWh]")
plot(hist_seen,hist_unseen,layout=(1,2), size=(1200,550), dpi=800)

savefig("pics/inputdata.png")

plot(range(0,23), mean(p_real[seen,:],dims=1)[1,:], label="seen", color=palette(:tab10), xlabel="Time of day [h]",  ylabel="Power generation [MWh]")
plot!(range(0,23), mean(p_real[unseen,:],dims=1)[1,:], label="unseen", dpi=800, xlabel="Time of day [h]", ylabel="Power generation [MWh]")

savefig("pics_1-4/inputdata_lineplot.png")
####################################################################


#************************************************************************
# CALCULATIONS - average balancing profit in each scenario
x = zeros(length(unseen)) #DA profit, unseen
y = zeros(length(unseen)) #Balancing profit, unseen
delta = zeros(W_tot[end],T[end])
count = 0 #this is used in order to only define x's and y's corresponding to the length of the unseen sample set
for w in unseen
    count += 1
    x[count] = sum(lambda_DA[w,t] * value.(p_DA[t]) for t in T)
    delta[w,:] = p_real[w,:] .- value.(p_DA)
    y[count] = sum( (Imbalance[w,t]*0.9 + (1-Imbalance[w,t])*1.2) * lambda_DA[w,t] * delta[w,t] for t in T)
end

println("\n\n\n################################ SINGLE-price ##############################")
println("The expected profit (SEEN) is €$(round((objective_value(Step1_1)),digits=1))")
println("The average profit (UNseen) is €$(round( (sum(x)+sum(y)) / length(unseen) ,digits=1))")

println("\nThe expected earnings in the DA market for SEEN scenarios is €$(round(sum(DA_prof)/length(seen),digits=1))")
println("The average earnings in the DA market for UNseen scenarios is €$(round(sum(x)/length(unseen),digits=1))")

println("\nThe expected profit in the BALANCING market for SEEN scenarios is: €", round(sum(balancing_prof)/length(seen),digits=1))
println("The average profit in the BALANCING market for UNseen scenarios are: €", round(sum(y)/length(unseen),digits=1))
println("############################################################################\n\n\n")


#histogram(Profits, label="Scenarios", xlabel="Profit [€]", ylabel="Probability") #add vline at expected price
histogram(Profits, label="seen", xlabel="Profit (total) [€]", ylabel="Probability", color=palette(:tab10), normalize=:true, bins=25)
histogram!([x+y], label="unseen", alpha=0.67, normalize=:true, bins=25, dpi=800, title="Single-price", margin=3Plots.mm)

savefig("pics_1-4/profdist_single-price_outofsample")

histogram(balancing_prof, label="seen", xlabel="Profit (balancing) [€]", ylabel="Probability", color=palette(:tab10), normalize=:true, bins=25)
histogram!(y, label="unseen", alpha=0.67, normalize=:true, bins=25, dpi=800, title="Single-price", margin=3Plots.mm)

savefig("pics_1-4/balancing-profdist_single-price_outofsample")
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

lambda_DA = scenarios[:,:,1]
p_real = scenarios[:,:,2] 
Imbalance = scenarios[:,:,3]

#************************************************************************
# CALCULATIONS - average balancing profit in each scenario
x = zeros(length(unseen)) #DA profit, unseen
y = zeros(length(unseen)) #Balancing profit, unseen
delta = zeros(length(unseen),T[end])
delta_up = zeros(length(unseen),T[end])
delta_down = zeros(length(unseen),T[end])
count=0
for w in unseen
    count+=1
    x[count] = sum(lambda_DA[w,t] * value.(p_DA[t]) for t in T)
    delta[count,:] = p_real[w,:] .- value.(p_DA)
    for t in T
        if delta[count,t] > 0
            delta_up[count,t] = delta[count,t]
        else
            delta_down[count,t] = -delta[count,t]
        end
    end
    y[count] = sum( -Imbalance[w,t]*lambda_DA[w,t]*delta_down[count,t] #System surplus, WF deficit, pay @ DA price
    -(1-Imbalance[w,t])*1.2*lambda_DA[w,t]*delta_down[count,t] #System deficit, WF deficit, pay @ 1.2*DA price
    +Imbalance[w,t]*0.9*lambda_DA[w,t]*delta_up[count,t] #System surplus, WF surplus, earn @ 0.9*DA price
    +(1-Imbalance[w,t])*lambda_DA[w,t]*delta_up[count,t] for t in T) #System deficit, WF surplus, earn @ DA price
end
println("\n\n\n################################ DUAL-price ################################")
println("The expected profit (SEEN) is €$(round((objective_value(Step1_2)),digits=1))")
println("The average profit (UNseen) is €$(round( (sum(x)+sum(y)) / length(unseen) ,digits=1))")

println("\nThe expected earnings in the DA market for SEEN scenarios is €$(round(sum(DA_prof)/length(seen),digits=1))")
println("The average earnings in the DA market for UNseen scenarios is €$(round(sum(x)/length(unseen),digits=1))")

println("\nThe expected profit in the BALANCING market for SEEN scenarios is: €", round(sum(balancing_prof)/length(seen),digits=1))
println("The average profit in the BALANCING market for UNseen scenarios are: €", round(sum(y)/length(unseen),digits=1))
println("############################################################################\n\n\n")


#histogram(Profits, label="Scenarios", xlabel="Profit [€]", ylabel="Probability") #add vline at expected price
histogram(Profits, label="seen", xlabel="Profit (total) [€]", ylabel="Probability", color=palette(:tab10), normalize=:true, bins=25)
histogram!([x+y], label="unseen", alpha=0.67, normalize=:true, bins=25, dpi=800, title="Dual-price", margin=3Plots.mm)

savefig("pics_1-4/profdist_dual-price_outofsample")


histogram(balancing_prof, label="seen", xlabel="Profit (balancing) [€]", ylabel="Probability", color=palette(:tab10), normalize=:true, bins=25)
histogram!(y, label="unseen", alpha=0.67, normalize=:true, bins=25, dpi=800, title="Dual-price", margin=3Plots.mm)

savefig("pics_1-4/balancing_profdist_dual-price_outofsample")


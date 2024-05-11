# 46755Ass2
Repository for assignment two of the renewables course

This deliverable is segmented into two parts, Step 1 describes the offering strategy of a wind farm in the day ahead market, while step 2 describes it in the FCR-D market

Every script is used by simply running the script, which will print the relevant data and create plots. Below, the functionality of each script is described in further detail.

Most of the scripts are built based on the preceeding scripts, e.g. Step1_2 contains most of the elements from Step1_1. Only changes in scripts are described.

## Part 1:
Required packages: CSV, Dataframes, Random, JuMP, Gurobi (or other solver), Plots, Distributions

# Scengen.jl:
A script used to generate the scenarios in accordance with the problem description from step 1. 
Prices and production have been downloaded from Energinet, and 3 lists of excess/deficit values are generated randomly, with 0 indicating deficit and 1 indicating excess.
These are used to produce an array containing 1200 scenarios each containing 24 hours of prices, production normalized to 200 and imbalance values

# Step1_1.jl
Contains a model used to solve the offering problem for a one-price balancing scheme.
Running the script generates the data using Scengen.jl, solves the model as described in the report, and plots relevant values.

# Step1_2.jl
Contains a model used to solve the offering problem for a two-price balancing scheme.
Based on Step1_1.jl. The models are very similar, but in this case the production is divided in surplus and deficit, to be able to satisfy the two-price offering.

# Step1_3_1.jl
Contains a model used to solve the risk-averse offering strategy problem in a one-price balancing scheme. 
The model is solved using beta values from 0 to 1, and saves a plot containing the Markowitz curve and a plot containing the profit distribution over scenarios

# Step1_3_2.jl
Contains a model used to solve the risk-averse offering strategy problem in a one-price balancing scheme. 
Has the same functionalities as Step1_3_1 otherwise.

# Step1_4.jl
Solves Step1_1 and Step1_2 and saves plots to inspect the data, and calculates and plots the average balancing profit in each scenario

## Part 2:
Required packages: Random, JuMP, Gurobi (or other solver), Plots, Statsplots (for plotting in Step2_3, can be commented out)

# Scengen2.jl:
Contains the function generate_load_profilen(num_profiles), that produces an array of num_profiles profiles, according to the problem description

# Step2_1ALSOX.jl
Contains the function solve_relaxed(q, profiles, training_profiles). This function solves relaxed problem used to obtain the optimal bid satisfying p90.
	q is an input signifying how much the bid can be violated
	profiles is an integer signifying how many profiles the problem should be solved with
		Currently new profiles are generated each solve (with a constant random seed), profiles can be passed around to improve speed
	training_profiles is an integer signifying how many of those profiles should be used for training 
The function solve_ALSOX(epsilon=0.1, profiles=200, training_profiles=50) solves the problem using the ALSO-X algorithm. 
	Epsilon defaults to 0.1 to simulate the P90 rule, but can be changed. The rest are simply passed to solve_relaxed()
Running the script executes solve_ALSOX()

# Step2_1CVAR.jl
Contains the function solve_CVAR(). This function solves the CVAR problem and returns the bid.
Running the script executes solve_CVAR()

# Step2_2.jl
Produces bids from solve_ALSOX() and solve_CVAR(), and then computes the shortfall measured in kW per minute, and contains sums to compute whether a profile has been violated and how many minutes the bids are violated.

# Step2_3.jl
Runs solve_ALSOX() for different values of epsilon, and computes relevant values for them.
Statsplots is used to present a plot of the scenarios compared to the bid
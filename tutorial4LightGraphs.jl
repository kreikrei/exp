using Pkg
for pkg in ["LightGraphs", "Plots", "GR", "Distributions"]
    Pkg.add(pkg)
end

using Distributions
using LightGraphs
using Plots; gr()
using Random: shuffle, seed!

# make sure this tutorial is reproducible
seed!(20130810);

"""
    fraction_engaged(node, G, node_status)

Computes the fraction of neighbors engaged within the neighborhood of a given node. It uses the node status to check the engagement status of each of the node's neighbors.
"""
function fraction_engaged(
    node::Int64,
    G::SimpleGraph,
    node_status::BitVector
    )

    num_engaged_neighbors = 0
    for nbr in neighbors(G,node)
        if node_status[nbr] == true
            num_engaged_neighbors += 1
        end
    end

    return num_engaged_neighbors/length(neighbors(G,node))
end

"""
    update_node_status!(G,node_status,threshold)

This function executes the random asynchronous updates of the entire network at each time step. In this conceptualization, each time step comprises smaller time steps where a randomly shuffled node list updates at each iteration.
"""
function update_node_status!(
    G::SimpleGraph, node_status::BitVector,
    threshold::Vector{Float64}
    )

    for node in shuffle(vertices(G))
        if node_status[node] == false
            if fraction_engaged(node, G, node_status) > threshold[node]
                node_status[node] = true
            end
        end
    end

    return nothing
end

"""
    diffusion_simulation(n,z,threshold,T,n_realizations)

Executes the diffusion simulation by creating a new Watts-Strogatz graph at each realization and seeds a single node (initialization). It then updates the network for the defined number of time steps.

The idea is to run the diffusion simulation a very large number of times and count the instances where we observe a global cascade, i.e., number of nodes engaged after the simulation process is a sizeable proportion of the network.

Hyper Parameters of the model
----------
1. Number of nodes in the Watts-Strogatz graph (n)
2. Average degree (z)
3. Threshold (distribution or a specific value)
4. Time steps for simulation to be run
5. Number of realizations

Output
-----------
A vector of number of engaged nodes at the end of each realization of the simulation

Intended usage of results
-----------
Plot the cascades on the z-ϕ phase space; replicate results from "A simple model of global cascades on random networks", Watts (2002)
"""
function diffusion_simulation(
    n::Int64,
    z::Int64,
    threshold::Vector{Float64},
    T::Int64,
    n_realizations::Int64
    )

    output = Vector{Int64}(undef, n_realizations)
    beta = z/n

    for r in 1:n_realizations
        #Create small world network
        G = watts_strogatz(n,z,beta)

        # Select a single random node from network and seed
        node_status = falses(nv(G))
        node_status[sample(vertices(G))] = true

        # Update the network for predefined number of time steps
        for _ in 1:T
            update_node_status!(G, node_status, threshold)
        end

        output[r] = sum(node_status)
    end

    return output
end

const N = 10^4
z, upper, lower = 5, 0.4, 0.2

@time data = diffusion_simulation(
    N, z, rand(Truncated(Normal(),lower,upper),N), 50, 100
)

histogram(data, xlab="Number of engaged nodes", ylab="Frequency", legend=false)

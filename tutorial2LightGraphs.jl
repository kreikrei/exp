using GraphPlot, SimpleWeightedGraphs, LinearAlgebra, DataFrames, Random, CSV, Colors

Random.seed!(7)
df = DataFrame(rand([0,1],10,20), :auto)
g = SimpleWeightedGraph(ncol(df))

ew = Int[]
for i in 1:ncol(df), j in i+1:ncol(df)  # iterate over all combinations of columns
    w = dot(df[!, i], df[!, j])         # calculate how many times (i,j) occurs
    if w > 0
        push!(ew, w)
        add_edge!(g, i, j, w)
    end
end

gplot(g,nodelabel=names(df),edgelinewidth=ew,layout=random_layout)

degree_histogram(g)
degree_centrality(g)

centrality = betweenness_centrality(g,normalize=false).+1
alphas = centrality./maximum(centrality).*10
nodefillc = [RGBA(0.0,0.8,0.8,i) for i in alphas]
gplot(g,nodelabel=names(df),edgelinewidth=ew,nodefillc=nodefillc,layout=random_layout)

prim = Graph(prim_mst(g))
gplot(prim, nodelabel = names(df))

g_mst = SimpleWeightedGraph(ncol(df))
for i in kruskal_mst(g, minimize = false)
    add_edge!(g_mst,i.src,i.dst,i.weight)
end
gplot(g_mst, nodelabel = names(df))

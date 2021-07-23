using Random
using LightGraphs
using GraphPlot

G₁ = Graph(3)

add_edge!(G₁,1,2)
add_edge!(G₁,1,3)
add_edge!(G₁,2,3)

gplot(G₁,nodelabel = 1:3)

A = [
    0 1 1
    1 0 1
    1 1 0
]

G₂ = Graph(A)

@assert G₁ == G₂

G = smallgraph(:house)

nvertices = nv(G)   #number of vertices
nedges = ne(G)      #number of edges

gplot(G, nodelabel=1:nvertices, edgelabel=1:nedges)

for v in vertices(G)
    println("vertex $v")
end

for e in edges(G)
    u,v = src(e),dst(e)
    println("edge $u - $v")
end

adjacency_matrix(G)
incidence_matrix(G)

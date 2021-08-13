#TAHIIIKKKKKK
using JuMP, GLPK, LightGraphs, CSV, DataFrames

vtx = ["Banda Aceh", "Lhokseumawe", "Medan","Sibolga", "Pematang Siantar"]
veh = ["TRUK", "KRTA"]
T = [1,2,3,4]
trayek = [
    ("Banda Aceh", "Medan", "TRUK"),
    ("Banda Aceh", "Sibolga", "TRUK"),
    ("Banda Aceh",	"Pematang Siantar", "TRUK"),
    ("Lhokseumawe",	"Banda Aceh", "TRUK"),
    ("Lhokseumawe",	"Medan", "TRUK"),
    ("Lhokseumawe",	"Sibolga", "TRUK"),
    ("Lhokseumawe",	"Pematang Siantar","TRUK"),
    ("Medan", "Banda Aceh","TRUK"),
    ("Medan", "Sibolga","TRUK"),
    ("Medan", "Pematang Siantar","TRUK"),
    ("Sibolga", "Banda Aceh","TRUK"),
    ("Sibolga", "Medan","TRUK"),
    ("Sibolga", "Pematang Siantar","TRUK"),
    ("Pematang Siantar", "Banda Aceh","TRUK"),
    ("Pematang Siantar", "Medan","TRUK"),
    ("Pematang Siantar", "Sibolga","TRUK"),
    ("Medan", "Pematang Siantar", "KRTA"),
    ("Pematang Siantar", "Medan", "KRTA")
]

demand_file = CSV.File("demand.csv", header = true)
demand_matrix = AxisArray(zeros(length(vtx),length(T)); i = vtx, t = T)
for r in 1:length(demand_file)
    v = vtx[r]
    for t in T
        demand_matrix[v,t] = getproperty(demand_file[r],t)
    end
end
d(i,t) = demand_matrix[i = i,t = t]

starting_file = CSV.File("starting.csv", header = false)
starting_vector = AxisArray(zeros(length(vtx)); i = vtx)
for r in 1:length(starting_file)
    v = vtx[r]
    starting_vector[v] = getproperty(starting_file[r],1)
end
s(i) = starting_vector[i = i]

m = Model(GLPK.Optimizer)

@variable(m, o[e = trayek, t = T] >= 0, Int)
@variable(m, I[i = vtx, t = union(0,T)] >= 0, Int)

TO(v) = filter(p -> p[2] == v,trayek)
FROM(v) = filter(p -> p[1] == v,trayek)

@constraint(m, flow[i = vtx, t = T],
    sum(o[e,t] for e in TO(i)) - sum(o[e,t] for e in FROM(i)) ==
    d(i,t) + I[i,t] - I[i,t-1]
)

@constraint(m, start[i = vtx],
    I[i,0] == s(i)
)

@objective(m, Min,
    sum(o)
)

optimize!(m)

value.(m.obj_dict[:o])

trayek[10]

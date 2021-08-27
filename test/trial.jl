using Revise
using CSV, DataFrames, Distances
using Nexus, Dictionaries

struct SpaceTime
    i::String
    t::Integer
end

struct Commodity
    src::Any
    snk::Any
    ld::Integer
end

Commodity() = Commodity(nothing, nothing, 0)

Base.show(io::IO, st::SpaceTime) = print(io, "{$(st.i),$(st.t)}")
Base.show(io::IO, co::Commodity) = print(io, "load $(co.ld) from $(co.src) => $(co.snk)")

cd("C:\\Users\\Rian Aristio\\.julia\\dev\\GRIP\\test")

permintaan = CSV.File("./TestSets\\V5-E22-M2-T4_permintaan.csv") |> DataFrame
khazanah = CSV.File("./TestSets\\V5-E22-M2-T4_khazanah.csv") |> DataFrame
trayek = CSV.File("./TestSets\\V5-E22-M2-T4_trayek.csv") |> DataFrame
moda = CSV.File("./TestSets\\V5-E22-M2-T4_moda.csv") |> DataFrame

H = nrow(permintaan)
V = names(permintaan)

G = Graph()
for i in V, t in 1:H
    new_node = SpaceTime(i, t)
    add_node!(G, new_node)
end

const SRC = add_node!(G, SpaceTime("SRC", 0))
const SNK = add_node!(G, SpaceTime("SNK", H + 1))

kamus_V = dictionary(khazanah.name .=> eachrow(khazanah[:,2:end]))
kamus_M = dictionary(moda.name .=> eachrow(moda[:,2:end]))

for i in V
    key1 = add_arc!(G, SRC, SpaceTime(i, 1))
    G[SRC, SpaceTime(i, 1), key1, :moda] = i
    G[SRC, SpaceTime(i, 1), key1, :Q] = kamus_V[i].START
    G[SRC, SpaceTime(i, 1), key1, :f] = 0
    G[SRC, SpaceTime(i, 1), key1, :g] = 0
    G[SRC, SpaceTime(i, 1), key1, :w] = 1

    key2 = add_arc!(G, SpaceTime(i, H), SNK)
    G[SpaceTime(i, H), SNK, key2, :moda] = i
    G[SpaceTime(i, H), SNK, key2, :Q] = kamus_V[i].MAX
    G[SpaceTime(i, H), SNK, key2, :f] = 0
    G[SpaceTime(i, H), SNK, key2, :g] = 0
    G[SpaceTime(i, H), SNK, key2, :w] = 1

    for t in 1:H - 1
        key3 = add_arc!(G, SpaceTime(i, t), SpaceTime(i, t + 1))
        G[SpaceTime(i, t), SpaceTime(i, t + 1), key3, :moda] = i
        G[SpaceTime(i, t), SpaceTime(i, t + 1), key3, :Q] = kamus_V[i].MAX
        G[SpaceTime(i, t), SpaceTime(i, t + 1), key3, :f] = 0
        G[SpaceTime(i, t), SpaceTime(i, t + 1), key3, :g] = 0
        G[SpaceTime(i, t), SpaceTime(i, t + 1), key3, :w] = 1
    end
end


for e in eachrow(trayek)
    f_cost = haversine(
        [kamus_V[e.ori].x, kamus_V[e.ori].y],
        [kamus_V[e.dst].x, kamus_V[e.dst].y],
        6371
    ) * kamus_M[e.md].dis + kamus_M[e.md].con
    g_cost = kamus_M[e.md].var
    Q_val = kamus_M[e.md].Q
    for t in 1:H
        origin = SpaceTime(e.ori, t)
        destin = SpaceTime(e.dst, t)
        key = add_arc!(G, origin, destin)
        G[origin, destin, key, :moda] = e.md
        G[origin, destin, key, :Q] = Q_val
        G[origin, destin, key, :f] = f_cost
        G[origin, destin, key, :g] = g_cost
        G[origin, destin, key, :w] = e.w
    end
end

has_attrib(G,:w)
has_attrib(G,:f)
has_attrib(G,:g)
has_attrib(G,:Q)

const st = SpaceTime

K = Vector{Commodity}()
for i in V, t in 1:H
    load = getproperty(permintaan, i)[t]
    if load > 0
        res = Commodity(SRC, st(i, t), load)
        push!(K, res)
    else
        res = Commodity(st(i, t), SNK, -load) # dinegatifin biar jadi positif
        push!(K, res)
    end
end

total_start = sum(kamus_V[i].START for i in keys(kamus_V))
total_permintaan = sum(
    permintaan[t,i] for t in 1:H, i in 1:ncol(permintaan) if permintaan[t,i] > 0 
)
dummy = total_start - total_permintaan
push!(K, Commodity(SRC, SNK, dummy))

function δ(i, k::Commodity)
    a = k.src == i
    b = -(k.snk == i)
    return a + b
end

[δ(n, k) for n in nodes(G), k in K]

# validation time!
using JuMP, Gurobi

m = Model()

@variable(m, 0 <= x[a=arcs(G), k=eachindex(K)] <= K[k].ld, Int)

@variable(m, 0 <= y[a=arcs(G)] <= G[a,:w], Int)

@constraint(m, [n = collect(nodes(G)), k = eachindex(K)],
    sum(x[a,k] for a in arcs(G, [n], :)) -
    sum(x[a,k] for a in arcs(G, :, [n])) ==
    δ(n, K[k]) * K[k].ld
)

@constraint(m, [a = arcs(G)],
    sum(x[a,k] for k in eachindex(K)) <= G[a,:Q] * y[a]
)

@constraint(m, [a = arcs(G, [SRC], :)],
    sum(x[a,k] for k in eachindex(K)) == G[a,:Q]
)

@objective(m, Min,
    sum(G[a,:f] * y[a] for a in arcs(G)) +
    sum(G[a,:g] * x[a,k] for a in arcs(G), k in eachindex(K))
)

set_optimizer(m, Gurobi.Optimizer)
optimize!(m)

raw_x = value.(m.obj_dict[:x])
raw_y = value.(m.obj_dict[:y])

# START: path decomposition scheme
path_comm = dictionary(k => Graph() for k in eachindex(K))
for k in eachindex(K)
    flow = raw_x[arcs(G)[1:end], k]
    P = path_comm[k]

    for a in arcs(G)
        if flow[a] > 0
            key = add_arc!(P, a)
            P[a,:flow] = flow[a]
        end
    end
end

idx_k = 21
z = path_comm[idx_k]
new_paths = []

z.na
new_path = depth_first_search(z, K[idx_k].src, K[idx_k].snk)
bottle_neck = Inf
for a in arcs(new_path)
    if path_comm[idx_k][a,:flow] < bottle_neck
        bottle_neck = path_comm[idx_k][a,:flow]
    end
end

for a in arcs(new_path)
    z[a,:flow] -= bottle_neck
    if z[a,:flow] == 0
        rem_arc!(z, a)
    end
end
push!(new_paths,new_path)
# STOP Path decomposition scheme

# START construct feasible solution
using DataStructures
Comms = PriorityQueue()
for k in eachindex(K)
    Comms[k] = 1 / K[k].ld
end
    
k = dequeue!(Comms)
using Setfield
s = @set K[k].ld += 0

ρ = Dictionary()
r = Dictionary()
w = Dictionary()

y = dictionary(a => 0 for a in arcs(G))
x = dictionary(a => 0 for a in arcs(G))

s[k].ld
for a in arcs(G)
    set!(ρ, a, G[a,:Q] * y[a] - x[a])
    if ρ[a] > 0
        set!(r, a, ρ[a])
        set!(w, a, G[a,:g])
    else
        if y[a] < G[a,:w]
            set!(r, a, G[a,:Q])
            set!(w, a, G[a,:g] + (G[a,:f] / r[a]))
        else
            set!(r, a, 0)
            set!(w, a, Inf)
        end
    end
end

ρ
r
w

shortest_path = Graph()
add_arcs_from!(shortest_path, collect(arcs(G)))
for a in arcs(G)
    shortest_path[a,:flow] = w[a]
    shortest_path[a,:cap] = r[a]
end

new_path = dijkstra_shortest_path(shortest_path, K[k].src, K[k].snk)
bottle_neck = Inf
for a in arcs(new_path)
    if shortest_path[a,:cap] < bottle_neck
        bottle_neck = shortest_path[a,:cap]
    end
end
if s[k].ld < bottle_neck
    bottle_neck = s[k].ld
end

for a in arcs(new_path)
    x[a] += bottle_neck
    y[a] = ceil(x[a] / G[a,:Q])
end
tes_X = x[Arc(SpaceTime("Banda Aceh", 1), SpaceTime("Banda Aceh", 2), 1)]
ceil(tes_X / G[Arc(SpaceTime("Banda Aceh", 1), SpaceTime("Banda Aceh", 2), 1),:Q])
y
bottle_neck

s = @set s[k].ld -= bottle_neck
s[k].ld
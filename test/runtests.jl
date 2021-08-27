using Revise
using GRIP
using Test

@testset "GRIP.jl" begin
    @test 1 == 1
end

cd(@__DIR__)
using CSV, DataFrames, Distances

permintaan = CSV.File("./TestSets\\V5-E22-M2-T4_permintaan.csv") |> DataFrame
khazanah = CSV.File("./TestSets\\V5-E22-M2-T4_khazanah.csv") |> DataFrame

G = GenericGraf()
for i in names(permintaan), t in 1:nrow(permintaan)
    add_node!(G,(i,t))
end
add_node!(G, :SRC)
add_node!(G, :SNK)

for i in names(permintaan)
    add_arc!(G, :SRC, (i, 1))
    add_arc!(G, (i, nrow(permintaan)), :SNK)
    for t in 1:nrow(permintaan) - 1
        add_arc!(G, (i, t), (i, t + 1))
    end
end

println(collect(nodes(G)))

kamus_khazanah = Dict(khazanah.name .=> eachrow(khazanah[:,2:end]))

for i in names(permintaan)
    G[:SRC, (i, 1), 1][:MODA] = i
    G[:SRC, (i, 1), 1][:Q] = kamus_khazanah[i].START # will be maxed
    G[:SRC, (i, 1), 1][:f] = 0
    G[:SRC, (i, 1), 1][:g] = 0

    G[(i,nrow(permintaan)),:SNK,1][:MODA]= i
    G[(i,nrow(permintaan)),:SNK,1][:Q] = kamus_khazanah[i].MAX
    G[(i,nrow(permintaan)),:SNK,1][:f] = 0
    G[(i,nrow(permintaan)),:SNK,1][:g] = 0

    for t in 1:nrow(permintaan)-1
        G[(i, t), (i, t + 1), 1][:MODA] = i
        G[(i, t), (i, t + 1), 1][:Q] = kamus_khazanah[i].MAX
        G[(i, t), (i, t + 1), 1][:f] = 0
        G[(i, t), (i, t + 1), 1][:g] = 0
    end
end

println(collect(arcs(G)))

trayek = CSV.File("./TestSets\\V5-E22-M2-T4_trayek.csv") |> DataFrame
moda = CSV.File("./TestSets\\V5-E22-M2-T4_moda.csv") |> DataFrame

kamus_moda = Dict(moda.name .=> eachrow(moda[:,2:end]))

for e in eachrow(trayek)
    f_cost = haversine(
        [kamus_khazanah[e.ori].x,kamus_khazanah[e.ori].y],
        [kamus_khazanah[e.dst].x,kamus_khazanah[e.dst].y],
        6371
    ) * kamus_moda[e.md].dis + kamus_moda[e.md].con
    g_cost = kamus_moda[e.md].var
    Q_val = kamus_moda[e.md].Q
    for w in 1:e.w, t in 1:nrow(permintaan)
        add_arc!(G,(e.ori,t),(e.dst,t))
        G[(e.ori,t),(e.dst,t),w][:MODA] = e.md
        G[(e.ori,t),(e.dst,t),w][:f] = f_cost
        G[(e.ori,t),(e.dst,t),w][:g] = g_cost
        G[(e.ori,t),(e.dst,t),w][:Q] = Q_val
    end
end

K = Vector{Commodity}()
for i in names(permintaan), t in 1:nrow(permintaan)
    load = getproperty(permintaan, i)[t]
    if load > 0
        res = Commodity(:SRC, (i,t), load)
        push!(K, res)
    else # load < 0
        res = Commodity((i,t), :SNK, -load)
        push!(K, res)
    end
end

total_start = sum(kamus_khazanah[i].START for i in keys(kamus_khazanah))
total_permintaan = sum(
    permintaan[i,t] for i in 1:nrow(permintaan), t in 1:ncol(permintaan)
    if permintaan[i,t] > 0
)
dummy = total_start - total_permintaan
push!(K, Commodity(:SRC,:SNK,dummy))

function δ(i, k::Commodity)
    a = src(k) == i
    b = -(snk(k) == i)
    return a + b
end

[δ(n,k) for n in nodes(G), k in K]

using JuMP, Cbc, Gurobi

m = Model()

@variable(m, 0 <= x[a = arcs(G), k = eachindex(K)] <= ld(K[k]), Int)
@variable(m, y[a = arcs(G)], Bin)

@constraint(m, [n = nodes(G), k = eachindex(K)],
    sum(x[a,k] for a in filter(p -> p[1] == n, arcs(G))) -
    sum(x[a,k] for a in filter(p -> p[2] == n, arcs(G))) == δ(n, K[k]) * ld(K[k])
)

@constraint(m, [a = arcs(G)],
    sum(#=ld(K[k]) * =#x[a,k] for k in eachindex(K)) <= get(G[a], :Q, 0) * y[a]
)

@constraint(m, [a = filter(p -> p[1] == :SRC, arcs(G))],
    sum(#=ld(K[k]) * =#x[a,k] for k in eachindex(K)) == get(G[a], :Q, 0)
)

@objective(m, Min,
    sum(get(G[a], :f, 0) * y[a] for a in arcs(G)) +
    sum(get(G[a], :g, 0) * #=ld(K[k]) * =#x[a,k] for a in arcs(G), k in eachindex(K))
)

set_optimizer(m, Gurobi.Optimizer)
optimize!(m)

raw_x = value.(m.obj_dict[:x])
raw_y = value.(m.obj_dict[:y])

res_y = filter(p-> raw_y[p] == 1, arcs(G))
res_x =Dict((a,k) => raw_x[a,k] for a in collect(res_y),k in eachindex(K) if raw_x[a,k] > 0)

arcs_of(k, sol) = filter(p -> first(p)[2] == k,sol)
arcs_of(1,res_x)

struct Path
    nodelist::Vector
    keylist::Vector
end

path = Path([1,2,3,5,4],["TRUK","KERETA",3,4])

function show(io::IO, path::Path)
    res = ""
    for p in eachindex(path.keylist)
        res *= "Node($(path.nodelist[p]))--$(path.keylist[p])-->"
    end
    res *= "Node($(last(path.nodelist)))"
    print(io, "path $res")
end

G
H = complete_digraph(10)
H = random_regular_digraph(10,5)
issubset(G,H)

edgetype(G)
add_edge!(G,LightGraphs.SimpleGraphs.SimpleEdge{Int64})

@doc add_edge!

tes = LightGraphs.SimpleGraphs.SimpleEdgeIter(G)

tes.g

iterate(LightGraphs.SimpleGraphs.SimpleEdgeIter(G))

import Base:OneTo

typeof(OneTo(5))

import Base:iterate

next = iterate(tes)
while next !== nothing
    (item, state) = next

    next = iterate()
end

iterate(tes,(1,3))
for e in tes
    println(e)
end

v1 = [2=>[2=>OneTo(10),3=>OneTo(8)],3=>[3=>OneTo(6)]]
v2 = [1=>[1=>OneTo(6),3=>OneTo(7)],3=>[1=>OneTo(8)]]
v3 = [2=>[3=>OneTo(7)]]

tes_adjlist = [v1,v2,v3]
n = 3
state = (1,1,1,1)

u,i,t,b = state
list_u = tes_adjlist[u]
list_i = last(list_u[i])
list_t = last(list_i[t])

if b > length(list_t)

e = (u,first(list_u[i]),first(list_i[t]),first(list_t[b]))
state = (u,i,t,b+1)

m1 = 2 => OneTo(2)
m2 = 3 => OneTo(3)

tes = [2 => [2 => OneTo(5) .=> nothing, 3 => OneTo(4) .=> nothing], 3 => [1 => OneTo(2) .=> nothing]]



mutable struct ListNode
    data::Integer
    next::Vector{ListNode}
end

mutable struct ListNode{T}
    data::T
    prev::ListNode{T}
    next::ListNode{T}
    function ListNode{T}() where T
        node = new{T}()
        node.next = node
        node.prev = node
        return node
    end
    function ListNode{T}(data) where T
        node = new{T}(data)
        return node
    end
end

mutable struct Node{T}
    data::T
    next::Vector{Node{T}}
end

ListNode{Int64}()


function dig(d)
    stack = d
    while !isempty(stack)
        k,v = pop!(stack)
        #abis pop catet key barusan
        if typeof(v) <: Dict
            dig(v)
        else
            println(k)
        end
    end
end
a1() = sum(i for i in 1:1000)
b = @task a1()
istaskstarted(b)
schedule(b)
yield()

function fibo(n)
    Channel() do ch
        a, b = 0, 1
        for _ in 1:n
            a, b = b, a + b
            put!(ch, a)
        end
    end
end

fibo(10)

b = @task arcs

function arcs(arcmap::Dict)
    Channel() do ch
        for (key,value) in arcmap
            if typeof(value) <: Dict
                for subkey in get_keys(value)
                    res = (key,subkey...)
                    put!(ch,res)
                end
            else
                put!(ch,key)
            end
        end
    end
end

function arcs(arcmap::Dict)
    Channel() do ch
        for (key,value) in arcmap
            if typeof(value) <: Dict
                for subkey in arcs(value)
                    res = (key,subkey...)
                    put!(ch,res)
                end
            else
                put!(ch,key)
            end
        end
    end
end

tes = Dict((1,1) => Dict([(1,2),(2,3),(2,4)] .=> [Dict([2,3].=>nothing),Dict(2=>nothing),Dict([1,3].=>nothing)]))

tes[(2,2)] = Dict([(3,1),(2,3),(1,4)] .=> [Dict([2,3].=>nothing),Dict(2=>nothing),Dict([1,3].=>nothing)])

tes

edge_list = collect(arcs(tes))

function expand(list)
    d = Dict()
    for path in list
        current_level = d
        for part in path
            if part != last(path)
                if !haskey(current_level, part)
                    current_level[part] = Dict()
                end
            else
                current_level[part] = nothing
            end
            current_level = current_level[part]
        end
    end

    return d
end

tes_Expand = expand(edge_list)
tes == tes_Expand
(1)
function tambah!(d::Dict,path)
    current_level = d
    for part in path
        if part != last(path)
            if !haskey(current_level, part)
                current_level[part] = Dict()
            end
        else
            if haskey(current_level, part)
                return false #edge exists
            else
                current_level[part] = nothing
                return true #edge successfully added
            end
        end
        current_level = current_level[part]
    end
end

tes
cari(tes,dicari)

dicari = ((3,1),(3,2),2)

next_iter = iterate(dicari)
next_item = tes
while next_iter !== nothing
    (item,state) = next_iter
    println(next_item[item])
    next_item = next_item[item]
    next_iter = iterate(dicari,state)
end


iterate((3,2),2)

haskey(tes,(3,1))

function cari(d::Dict,path)
    current_level = d
    next = iterate(path)
    while next !== nothing

        current_level = current_level[part] #iter
    end
end

function hapus(d::Dict,path)
    current_level = d
    for part in path
        if haskey(current_level,part)
            if isnothing(current_level[part])
                delete!(current_level,part)
                return true
            else
                current_level = current_level[part]
            end
        else
            return false
        end
    end
end

function rapikan!(petabusur::Dict)
    @inbounds for k in keys(petabusur)
        if !isnothing(petabusur[k])
            for destination in keys(petabusur[k])
                if !haskey(petabusur, destination)
                    petabusur[destination] = nothing
                end
            end
        end
    end
    return nothing
end

function rapikah(petabusur::Dict)
    rapi = true
    @inbounds for k in keys(petabusur)
        if !isnothing(petabusur[k])
            for destination in keys(petabusur[k])
                if !haskey(petabusur, destination)
                    rapi = false
                    return rapi
                end
            end
        end
    end
    return rapi
end

rapikah(tes)
rapikan!(tes)
keys(tes)

tes
cari(tes,dihapus)
tes

to_build = collect(arcs(tes))

tes_build = expand(to_build)


dihapus = ((2,3),(3,2),1)
hapus(tes,dihapus)
tambah!(tes,dihapus)

tes

tes

abc = Vector{Tuple}()
for r in get_keys(tes)
    push!(abc,r)
end

for r in chnl
    println(r)
end


for key in get_keys(tes)
    println(key)
end

d = tes[1]

println("...........")

if i > length(list_u)
    u == n && return nothing

    u += 1
    list_u
end


tes.g.fadjlist


current_level = petabusur
for part in path
    if haskey(current_level, part) #ada komponen
        current_level = current_level[part] #langsung turun
        if isnothing(current_level) #akhir komponen eksis
            return true #lapor
        end
    else
        return false #lgsg berhenti klo gaada
    end
end

function lebihdarisatu(x)
    if x > 1
        return true
    else
        msg = ErrorException("$x tidak lebih dari satu")
        throw(msg)
        println("haha")
    end
end

tes = Dict()
tes[1] = 2
try
    tes[2]
catch KeyError
    println("hai")
end

D = Dict()

D[1] = 2

D[2] = 3

D[3] = 4

pop!(D)
D

delete!(D,1)

D[nothing] = 1
D[nothing]
u,v = (1,2); key= 1
key
D[nothing] = 2

delete!(D,nothing)
D[1] = Dict()

D[1][2] = Dict()

D[1][2][3] = 10

d = D[1][2]

key = 3

if haskey(d, key)
    println("ada")
    delete!(d,key)
else
    println("gaada")
end

t = (1,2,3)
g = Dict()
function cobaindeh(g,a,b,c = nothing)
    return g,a,b,c
end

t = 1,2,3
cobaindeh(g,t...)

try
    cobaindeh(t...)
catch end
g[1] =2
try
    g[1]
catch KeyError end

g = Dict{Any,Int128}()

g[0] = 1
g[1] = 1
for i in 2:100
    g[randstring(6)] = rand(1:i)
end

using Random

na = length(g)
using BenchmarkTools
@btime length(g)
@btime na

delete!(g,1)
fail = ErrorException("a")

keys(g)
iterate(keys(g))

iterate(g)

tes

sum(length(k) for k in values(tes[(2, 2)]))

kasih(t) = false

using Dictionaries
dict = Dictionary([1,2,3],["a","b","c"])
unset!(dict,lastindex(dict))
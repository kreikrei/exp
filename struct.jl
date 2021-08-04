struct vtx
    x::Float64
    y::Float64
    MAX::Int64
    MIN::Int64
    START::Int64
    d::Vector{Int64}
end

struct lin
    src::String
    dst::String
    md::String
end

struct attrib
    f::Float64
    g::Float64
    lim::Int64
    Q::Int64
end

struct veh
    var::Float64
    con::Float64
    dist::Float64
    Q::Int64
end

#Accessors
src(e::lin) = e.src
dst(e::lin) = e.dst
md(e::lin) = e.md

#=
first uncontrollable input is a graph G = (V,E)
where

V => all khazanah // Vector{Int64}
each v ∈ V is associated with a MIN and MAX limit and a position coordinate x and y
each vertex will also be associated with a starting inventory and an external demand (?)
=#

using CSV, DataFrames

khznh = CSV.File("khazanah.csv") |> DataFrame
prmntn = CSV.File("permintaan.csv") |> DataFrame
@assert khznh.name == names(prmntn) #names in khazanah must be covered by permintaan

const T = [1:nrow(prmntn);]

const vertex_data = Ref{Any}(nothing)
V() = vertex_data[]
V(i) = vertex_data[][i]

khznh_Dict = Dict{String,vtx}()
for r in eachrow(khznh)
    khznh_Dict[r.name] = vtx(r.x, r.y, r.MAX, r.MIN, r.START, prmntn[:,r.name])
end
vertex_data[] = khznh_Dict

#=
E => all lin (lintasan) // Vector{lin}
each e ∈ E consist of a src (source), dst (destination), and mod (mode)
each md (mode) is a class which is associated with:
Q (capacity), f (variable cost), and g (fixed cost)
and g has a distance and constant compoent

IMPORTANT FUNCTIONS
in(v) => all lin going in to vertex v
out(v) => all lin going out from vertex v
=#

using Distances

trayek = CSV.File("trayek.csv") |> DataFrame
kndrn = CSV.File("kendaraan.csv") |> DataFrame

kendaraan_Dict = Dict{String,veh}()
for r in eachrow(kndrn)
    kendaraan_Dict[r.name] = veh(r.var,r.con,r.dist,r.Q)
end

trayek_Dict = Dict{lin,attrib}()
for r in eachrow(trayek)
    trayek_Dict[lin(r.src,r.dst,r.md)] = attrib(
        kendaraan_Dict[r.md].var, kendaraan_Dict[r.md].con +
        haversine([V(r.src).x,V(r.src).y], [V(r.dst).x,V(r.dst).y]) *
        kendaraan_Dict[r.md].dist, r.lim, kendaraan_Dict[r.md].Q
    )
end

trayek_Dict


"""
    distribute(starting,demand,vertices,edges)

beside demand, everything else is independent of time (starting vertices edges).
jdi penentu periode waktu adalah data demand (ada brp kolom)

LEGIBLE INPUT:
1. sum starting >= sum demand (MEMANG BISA DIPENUHI)
2. graph yg dibentuk dr unique lin (terlepas dr moda) is conenected
3. sum lim*cap all lin >= sum demand (MEMANG BISA DITRANSPORT)
"""

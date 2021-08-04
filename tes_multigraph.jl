struct lin{T}
    src::T
    dst::T
    md::T
    w::Integer
end

mutable struct multigraph{T}
    list::Vector{lin{T}}
    ne::Integer
end

struct slot{T}
    src::T
    dst::T
    md::T
    w::Integer
    t::Integer
end

mutable struct distplan{T}
    sched::Vector{slot{T}}
    ne::Integer
end

function distribute(g::multigraph,T::Integer;method::String)
    #finds rencana distribusi for given context
end

function f(edge)
    if isa(edge,lin)
        #calculate fixed cost
    elseif isa(edge,slot)
        return f(lin(edge.src,edge.dst,edge.md,edge.w))
    end
end

function g(edge)
    if isa(edge,lin)
        #calculate variable cost
    elseif isa(edge,slot)
        return g(lin(edge.src,edge.dst,edge.md,edge.w))
    end
end

khznh = CSV.File("khazanah.csv") |> DataFrame
prmntn = CSV.File("permintaan.csv") |> DataFrame
trayek = CSV.File("trayek.csv") |> DataFrame
kndrn = CSV.File("kendaraan.csv") |> DataFrame

#=
ada dua koleksi atribut => V (khazanah) dan M (moda)
V nyimpen x y max min starting dan demand
M nyimpen biaya tetap, biaya variabel, dan kapasitas moda
=#

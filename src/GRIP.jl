module GRIP

import Base:show
using CSV, DataFrames, Distances
using JuMP, Clp, Cbc

include("Graf.jl")

export
Commodity, src, snk, ld

struct Commodity
    src::Any
    snk::Any
    ld::Integer
end

Commodity() = Commodity(nothing, nothing, 0)

src(co::Commodity) = co.src
snk(co::Commodity) = co.snk
ld(co::Commodity) = co.ld

show(io::IO, co::Commodity) = print(io,"load $(ld(co)) from $(src(co)) => $(snk(co))")

end

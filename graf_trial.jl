import Base: show, ==

struct Node{G}
    id::G
end

show(io::IO, n::Node) = print(io, "$(n.id)")
==(m::Node, n::Node) = m.id == n.id
Node(p, q, r...) = Node(tuple(p, q, r...))

struct Arc
    u::Node
    v::Node
    key::Integer
end

Base.show(io::IO, a::Arc) = print(io, "Arc $(a.u) => $(a.v) key $(a.key)")
Arc(u, v, key) = Arc(Node(u), Node(v), key)
Arc(t) = Arc(Node(t[1]), Node(t[2]), t[3])

const AttribDict = Dict{Symbol,Any}
KeysDict(AD::DataType)::DataType = Dict{Integer,AD}
NbrsDict(KD::DataType)::DataType = Dict{Node,KD}
NDict(NbD::DataType)::DataType = Dict{Node,NbD}

mutable struct AdjDict
    adj::NDict(
        NbrsDict(
            KeysDict(AttribDict)
        )
    )
end

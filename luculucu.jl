using caramel

#TRIAL COLGEN
using JuMP, Cbc, Clp

mp = Model()

#EMPTY/TEST COLUMN
first_col = Dict(E() .=> 0)
first_col[lin("Medan", "Sibolga", "TRUK", 16)] = 500
first_col[lin("Medan", "Banda Aceh", "TRUK", 12)] = 1000

#SET INITIAL RESTRICTED MASTER COLUMN(S)
R = Vector{Dict}()
push!(R,first_col)

@variable(mp, θ[r = R, t = T] >= 0)
@variable(mp, V(i).MIN <= I[i = keys(V()), t = vcat(0,T)] <= V(i).MAX)
@variable(mp, 0 <= slack[e = E(), t = T] <= e.w)
@variable(mp, 0 <= surp[e = E(), t = T] <= e.w)

@constraint(mp, [i = keys(V()), t = T],
    I[i, t - 1] + sum(netflow(r)[i] * θ[r, t] for r in R) == V(i).d[t] + I[i, t]
)

@constraint(mp, [i = keys(V())],
    I[i,0] == V(i).START
)

@objective(mp, Min,

)



for r in R
    tes_flow = netflow(r)
    println(tes_flow)
end

#function netflow(column) will output dictionary of vertex => netflow at that vertex
function netflow(column::Dict)
    net = Dict(keys(V()) .=> 0)

    for i in keys(net)
        in_flow = sum(column[e] for e in IN(i))
        out_flow = sum(column[e] for e in OUT(i))
        net[i] = in_flow - out_flow
    end

    return net
end


#TRIAL COLGEN
using JuMP, Cbc, Clp

mp = Model()

#SET INITIAL RESTRICTED MASTER COLUMN(S)
R = Vector{Dict}()

@variable(mp, 0 <= θ[r = 1:length(R), t = T()] <= 1)
@variable(mp, I[i = V(), t = vcat(0,T())])
@variable(mp, 0 <= dummy[e = E(), t = T()] <= 0.125 * w(e))

@constraint(mp, λ[i = V(), t = T()],
    I[i, t - 1] + sum(netflow(R[r])[i] * θ[r, t] for r in 1:length(R)) +
    sum(Q(e) * dummy[e, t] for e in IN(i)) - sum(Q(e) * dummy[e, t] for e in OUT(i)) ==
    V(i).d[t] + I[i, t]
)

@constraint(mp, [i = V()],
    I[i,0] == V(i).START
)

@constraint(mp, [i = V(), t = T()],
    V(i).MIN <= I[i,t] <= V(i).MAX
)

@constraint(mp, δ[t = T()],
    sum(θ[r,t] for r in 1:length(R)) <= 1
)

@objective(mp, Min,
    sum(cost(R[r]) * θ[r,t] for r in 1:length(R), t in T()) +
    sum(f(e) * dummy[e,t] + g(e) * Q(e) * dummy[e,t] for e in E(), t in T())
)

set_optimizer(mp,Gurobi.Optimizer)
optimize!(mp)

duals_1 = dual.(mp.obj_dict[:λ])
duals_2 = dual.(mp.obj_dict[:δ])

value.(mp.obj_dict[:θ])
value.(mp.obj_dict[:dummy])
value.(mp.obj_dict[:I])

t = 2
sp = Model()

@variable(sp, p_sp[e = E()] >= 0, Int)
@variable(sp, o_sp[e = E()] >= 0, Int)

@constraint(sp, [e = E()], o_sp[e] <= p_sp[e] * Q(e))
@constraint(sp, [e = E()], p_sp[e] <= w(e))

@objective(sp, Min,
    sum(
        (f(e) - duals_1[src(e),t] + duals_1[dst(e),t]) * p_sp[e]
        for e in E()
    )
)

set_optimizer(sp,Gurobi.Optimizer)
optimize!(sp)

value.(sp.obj_dict[:p_sp])
value.(sp.obj_dict[:o_sp])

newcol = Dict{Int64,var}()
for e in E()
    newcol[e] = var(value(sp.obj_dict[:o_sp][e]), value(sp.obj_dict[:p_sp][e]))
end

push!(R,newcol)

netflow(R[1])
cost(R[1])

#function netflow(column) will output dictionary of vertex => netflow at that vertex
function netflow(column::Dict)
    net = Dict(V() .=> 0)

    for i in keys(net)
        in_flow = sum(column[e].o for e in IN(i))
        out_flow = sum(column[e].o for e in OUT(i))
        net[i] = in_flow - out_flow
    end

    return net
end

function cost(column::Dict)
    fixed = sum(f.(keys(column)) .* getproperty.(collect(values(column)), :p))
    variable = sum(g.(keys(column)) .* getproperty.(collect(values(column)), :o))

    return fixed + variable
end

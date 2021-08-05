#TRIAL COLGEN
using JuMP, Cbc, Clp

mp = Model()
T = [1,2,3,4]

#SET INITIAL RESTRICTED MASTER COLUMN(S)
R = Vector{col}()
OUT("Medan")

push!(R,col)
push!(R,second_col)

@variable(mp, 0 <= θ[r = 1:length(R), t = T] <= 1)
@variable(mp, I[i = keys(V()), t = vcat(0,T)])
@variable(mp, 0 <= dummyflow[e = E(), t = T] <= w(e) * Q(e))

@constraint(mp, λ[i = keys(V()), t = T],
    I[i, t - 1] + sum(netflow(R[r])[i] * θ[r, t] for r in 1:length(R)) +
    sum(dummyflow[e, t] for e in IN(i)) == sum(dummyflow[e,t] for e in OUT(i)) +
    V(i).d[t] + I[i, t]
)

@constraint(mp, [i = keys(V())],
    I[i,0] == V(i).START
)

@constraint(mp, [i = keys(V()), t = T],
    V(i).MIN <= I[i,t] <= V(i).MAX
)

@constraint(mp, δ[t = T],
    sum(θ[r,t] for r in 1:length(R)) <= 1
)

@objective(mp, Min,
    sum(cost(R[r]) * θ[r,t] for r in 1:length(R), t in T) +
    sum(dummyflow[e,t]/Q(e) * f(e) + dummyflow[e,t] * g(e) for e in E(), t in T)
)

set_optimizer(mp,Clp.Optimizer)
optimize!(mp)

duals_1 = dual.(mp.obj_dict[:λ])
duals_2 = dual.(mp.obj_dict[:δ])

value.(mp.obj_dict[:θ])
value.(mp.obj_dict[:dummyflow])
value.(mp.obj_dict[:I])

t = 2
sp = Model()

@variable(sp, o_sp[e = E()] >= 0, Int)
@variable(sp, p_sp[e = E()] >= 0, Int)

@constraint(sp, [e = E()], o_sp[e] <= p_sp[e] * Q(e))
@constraint(sp, [e = E()], p_sp[e] <= w(e))

@objective(sp, Min,
    sum(
        f(e) * p_sp[e] + g(e) * o_sp[e]
        for e in E()
    ) -
    sum(
        o_sp[e] * duals[src(e),t] - o_sp[e] * duals[dst(e),t]
        for e in E()
    )
)

using Gurobi
set_optimizer(sp,Gurobi.Optimizer)
optimize!(sp)

sum(value.(sp.obj_dict[:p_sp]))
sum(value.(sp.obj_dict[:o_sp]))


#function netflow(column) will output dictionary of vertex => netflow at that vertex
function netflow(column::Dict)
    net = Dict(keys(V()) .=> 0)

    for i in keys(net)
        in_flow = sum(column[e].o for e in IN(i))
        out_flow = sum(column[e].o for e in OUT(i))
        net[i] = in_flow - out_flow
    end

    return net
end

function cost(column::Dict)
    fixed = sum(f.(keys(column)) .* p.(values(column)))
    variable = sum(g.(keys(column)) .* o.(values(column)))

    return fixed + variable
end


cost(R[1])
cost(R[2])


o.(values(R[1]))

tesmodel = raw_model_IP(V(),E(),M(),T)
optimize!(tesmodel)

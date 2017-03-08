export minimize, minimize!

include("problems/split.jl")
include("problems/primal.jl")
include("problems/dual.jl")

#TODO implement also minimize!
minimize(h::OptTerm, args...)                         = minimize(CostFunction([h]),args...)
minimize(h::CostFunction, args...)                    = minimize(h, Array{OptTerm,1}(0), args...)
minimize(h::CostFunction, cstr::OptTerm, args...)     = minimize(h, [cstr], args...)

function minimize{T<:OptTerm}(cf::CostFunction, cstr::Array{T,1}, slv::Solver = ZeroFPR() )
	#add constraints to cost function
	for c in cstr
		cf += c
	end
	g, smooth, nonsmooth = split(cf::CostFunction)
	if length(g) >  1 
		error("problem not supported") 
	end
	if isempty(g) 
		if isempty(smooth)
			error("only non smooth terms are present we should smooth a term")   
			# here we should have the call problem(nonsmooth)
		else
			push!(g,pop!(smooth))
		end
	end 
	if isempty(nonsmooth)
		P = problem(g[1], smooth) 
	else
		P = problem(g[1], smooth, nonsmooth) # if fi[1] <: SmoothTerm creates Primal else Dual
	end
	                                      # in Dual if errors call problem(nonsmooth)
	solve(P,slv)
end

		















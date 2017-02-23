type ZeroFPR <: ForwardBackwardSolver
	tol::Float64
	maxit::Int64
	verbose::Int64
	mem::Int64
	halt::Function
	gamma::Float64
	it::Int
	normfpr::Float64
	cost::Float64
	time::Float64
	linesearch::Bool
	name::AbstractString
	cnt_matvec::Int
	cnt_prox::Int
end

"""
# Zero Fixed Point Residual Solver

Default solver of RegLS.

## Usage

* `slv = ZeroFPR()` creates a `Solver` object that can be used in the function `solve`.

* Can be used with convex and noncovex regularizers.

* After solving a problem use `show(slv)` to visualize number of iterations, fixed point residual value, cost funtion value and time elapsed.


## Keyword Arguments

* `tol::Float64=1e-8`: tolerance used in stopping criterion
* `maxit::Int64=10000`: maximum number of iterations
* `mem::Int64=5`: L-BFGS memory
* `verbose::Int64=1`: `0` verbose off, `1` print every 100 iteration, `2` print every iteration
* `stp_cr::Function`: custom stopping criterion function
  * this function may be specified by the user and must have the following structure:

    `myhalt(slv::ForwardBackwardSolver,normfpr0::Float64,Fcurr::Float64,Fprev::Float64)`

    * `normfpr0` is the fixed point residual at x0
    * `Fcurr` is the objective value at the current iteration
    * `Fprev` is the objective value at the previous iteration
    * example: `myhalt(slv,normfpr0,FBE,FBEx) = slv.normfpr < tol`

* `gamma::Float64=Inf`: stepsize γ, if γ = Inf upper bound is computed using:

  γ0 = || x0-(x0+ɛ) || / || ∇f(x0) - ∇f(x0+ɛ) ||

* `linesearch::Bool=true`: activates linesearch on stepsize γ
"""

ZeroFPR(;tol::Float64 = 1e-8,
	 maxit::Int64 = 10000,
         mem::Int64 = 5,
	 verbose::Int64 = 1,
	 halt::Function = halt_default,
	 gamma::Float64 = Inf,
	 linesearch::Bool = true) =
ZeroFPR(tol,
	maxit,
	verbose,
	mem,
	halt,
	gamma,
        0, Inf, Inf, NaN, linesearch, "ZeroFPR", 0, 0)

function solve!{T <: AffineOp}(A::T, g::ProximableFunction, slv::ZeroFPR)

	tic()

	x = optArray(A)
	At = A'

	LBFGS = lbfgs(x,slv.mem)
	beta = 0.05

	resx = A*x
	fx = 0.5*deepvecnorm(resx)^2
	gradx = At*resx
	slv.cnt_matvec += 2

	if slv.gamma == Inf # compute upper bound for Lipschitz constant using fd
		resx_eps  = A*(x+sqrt(eps()))
		gradx_eps = At*(resx_eps)
		slv.cnt_matvec += 2
		Lf = deepvecnorm(gradx-gradx_eps)/(sqrt(eps()*deeplength(x)))
		slv.gamma = (1-beta)/Lf
	end

	sigma = beta/(4*slv.gamma)
	tau = 1.

	# compute least squares residual and gradient
	xbar, gxbar = prox(g, x-slv.gamma*gradx, slv.gamma)
	slv.cnt_prox += 1
	r = x - xbar
	slv.normfpr = deepvecnorm(r)
	uppbnd = fx - real(deepvecdot(gradx,r)) + 1/(2*slv.gamma)*slv.normfpr^2
	FBEx = uppbnd + gxbar

	# initialize variables
	fxbar, normfpr0, FBEprev, = NaN, NaN, NaN
	rbar_prev = deepcopy(x)
	rbar      = deepcopy(x)
	xbar_prev = deepcopy(x)
	d         = deepcopy(x)
	ATAd      = deepcopy(x)
	gradstep  = deepcopy(x)
	gradxbar = deepcopy(x)
	xbarbar = deepcopy(x)
	Ad        = deepcopy(resx)
	resxbar = deepcopy(resx)

	for slv.it = 1:slv.maxit

		# stopping criterion
		if slv.halt(slv, normfpr0, FBEx, FBEprev) break end
		FBEprev = FBEx

		A_mul_B!(resxbar,A,xbar)
		slv.cnt_matvec += 1
		fxbar = 0.5*deepvecnorm(resxbar)^2

		# line search on gamma
		if slv.linesearch == true
			for j = 1:32
				if fxbar <= uppbnd break end
				slv.gamma = 0.5*slv.gamma
				sigma = 2*sigma
				gradstep .= (*).(-slv.gamma, gradx)
				gradstep .+= x
				gxbar = prox!(g, gradstep, xbar, slv.gamma)
				slv.cnt_prox += 1
				r .= (-).(x, xbar)
				slv.normfpr = deepvecnorm(r)
				A_mul_B!(resxbar,A,xbar)
				slv.cnt_matvec += 1
				fxbar = 0.5*deepvecnorm(resxbar)^2
				uppbnd = fx - real(deepvecdot(gradx,r)) + 1/(2*slv.gamma)*slv.normfpr^2
			end
		end

		if slv.it == 1 normfpr0 = copy(slv.normfpr) end

		# evaluate FBE at x
		FBEx = uppbnd + gxbar

		slv.cost = fxbar+gxbar
		# print out stuff
		print_status(slv)

		# compute rbar
		A_mul_B!(gradxbar, At, resxbar)
		slv.cnt_matvec += 1
		gradstep .= (*).(-slv.gamma, gradxbar)
		gradstep .+= xbar
		prox!(g, gradstep, xbarbar, slv.gamma)
		slv.cnt_prox += 1
		rbar .=(-).(xbar, xbarbar)

		# compute direction according to L-BFGS
		if slv.it == 1
			deepcopy!(d,-rbar)
		else
			update!(LBFGS, xbar, xbar_prev, rbar, rbar_prev)
			A_mul_B!(d,LBFGS, rbar)
		end

		# store xbar and rbar for later use
		deepcopy!(rbar_prev,rbar)
		deepcopy!(xbar_prev,xbar)

		# line search on tau
		level = FBEx - sigma*slv.normfpr^2
		tau = 1.0
		typeof(A) <: LinearOp ? A_mul_B!(Ad, A,  d) : A_mul_B!(Ad, A.A,  d)
		A_mul_B!(ATAd,At, Ad)
		slv.cnt_matvec += 2
		for j = 1:32
			x .= (+).(xbar_prev, (*).(tau,d))
			resx .= (+).(resxbar, (*).(tau,Ad))
			fx = 0.5*deepvecnorm(resx)^2
			gradx .= (+).(gradxbar, (*).(tau,ATAd))
			gradstep .= (*).(-slv.gamma, gradx)
			gradstep .+= x
			gxbar = prox!(g, gradstep, xbar, slv.gamma)
			slv.cnt_prox += 1
			r .= (-).(x, xbar)
			slv.normfpr = deepvecnorm(r)
			uppbnd = fx - real(deepvecdot(gradx,r)) + 1/(2*slv.gamma)*slv.normfpr^2
			if uppbnd + gxbar <= level break end
			tau = 0.4*tau
		end

	end

	print_status(slv, 2*(slv.verbose>0))

	slv.time = toq()

	return xbar, slv
end

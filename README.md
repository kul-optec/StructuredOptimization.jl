# StructuredOptimization.jl

[![Build status](https://github.com/JuliaFirstOrder/StructuredOptimization.jl/workflows/CI/badge.svg)](https://github.com/JuliaFirstOrder/StructuredOptimization.jl/actions?query=workflow%3ACI)
[![codecov](https://codecov.io/gh/JuliaFirstOrder/StructuredOptimization.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/JuliaFirstOrder/StructuredOptimization.jl)
[![Aqua QA](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)

[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://juliafirstorder.github.io/StructuredOptimization.jl/stable)
[![](https://img.shields.io/badge/docs-latest-blue.svg)](https://juliafirstorder.github.io/StructuredOptimization.jl/latest)

StructuredOptimization.jl is a high-level modeling language
that utilizes a syntax that is very close to
the mathematical formulation of an optimization problem.

This user-friendly interface
acts as a parser to utilize
three different packages:

* [ProximalOperators.jl](https://github.com/JuliaFirstOrder/ProximalOperators.jl)

* [AbstractOperators.jl](https://github.com/kul-optec/AbstractOperators.jl)

* [ProximalAlgorithms.jl](https://github.com/JuliaFirstOrder/ProximalAlgorithms.jl)

StructuredOptimization.jl can handle large-scale convex and nonconvex problems with nonsmooth cost functions.

It supports complex variables as well.

## Installation

To install the package, hit `]` from the Julia command line to enter the package manager, then

```julia
pkg> add StructuredOptimization
```

## Usage

A *least absolute shrinkage and selection operator* (LASSO) can be solved with only few lines of code:

```julia
julia> using StructuredOptimization

julia> n, m = 100, 10;                # define problem size

julia> A, y = randn(m,n), randn(m);   # random problem data

julia> x = Variable(n);               # initialize optimization variable

julia> λ = 1e-2*norm(A'*y,Inf);       # define λ    

julia> @minimize ls( A*x - y ) + λ*norm(x, 1); # solve problem

julia> ~x                             # inspect solution
100-element Array{Float64,1}:
  0.0
  0.0
  0.0
  0.440254
  0.0
  0.0
  0.0
[...]
```

See the [documentation](https://juliafirstorder.github.io/StructuredOptimization.jl/latest) for more details about the type of problems StructuredOptimization.jl can handle and the [demos](https://juliafirstorder.github.io/StructuredOptimization.jl/stable/demos/) to check out some examples.

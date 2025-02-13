module StructuredOptimization

using LinearAlgebra
using RecursiveArrayTools
using AbstractOperators
using ProximalOperators
using ProximalAlgorithms

import ProximalAlgorithms: ZeroFPR, PANOC, PANOCplus
export ZeroFPR, PANOC, PANOCplus

ProximalAlgorithms.value_and_gradient(f, x) = begin
  y, fy = gradient(f, x)
  return fy, y
end

include("syntax/syntax.jl")
include("calculus/precomposeNonlinear.jl") # TODO move to ProximalOperators?
include("arraypartition.jl") # TODO move to ProximalOperators?

# problem parsing
include("solvers/terms_extract.jl")
include("solvers/terms_properties.jl")
include("solvers/terms_splitting.jl")

# solver calls
include("solvers/solvers_options.jl")
include("solvers/build_solve.jl")
include("solvers/minimize.jl")

end

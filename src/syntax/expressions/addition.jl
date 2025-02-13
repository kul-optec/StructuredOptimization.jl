import Base: +, -

"""
	+(ex1::AbstractExpression, ex2::AbstractExpression)

Add two expressions.

# Examples

```julia
julia> x,y = Variable(5), Variable(5)
(Variable(Float64, (5,)), Variable(Float64, (5,)))

julia> ex1 = x+y

julia> z = Variable(2)
Variable(Float64, (2,))

julia> ex2 = randn(5,2)*z

```

Notice that in order for two expressions to be added toghether their associated `AbstractOperator`
must have the same codomain:

```julia
julia> operator(ex1)
[I,I]  ℝ^5  ℝ^5 -> ℝ^5

julia> operator(ex2)
▒  ℝ^2 -> ℝ^5

julia> ex3 = ex1 + ex2

```

It is also possible to use broadcasted addition:
```julia
julia> z = Variable(1)
Variable(Float64, (1,))

julia> ex3.+z

```

"""
function (+)(a::AbstractExpression, b::AbstractExpression)
  A = convert(Expression,a)
  B = convert(Expression,b)
	if variables(A) == variables(B)
    return Expression{length(A.x)}(A.x,affine(A)+affine(B))
	else
		opA = affine(A)
		xA = variables(A)
		opB = affine(B)
		xB = variables(B)
    xNew, opNew = Usum_op(xA,xB,opA,opB,true)
    return Expression{length(xNew)}(xNew,opNew)
	end
end
# sum expressions

function (-)(a::AbstractExpression, b::AbstractExpression)
  A = convert(Expression,a)
  B = convert(Expression,b)
	if variables(A) == variables(B)
    return Expression{length(A.x)}(A.x,affine(A)-affine(B))
	else
		opA = affine(A)
		xA = variables(A)
		opB = affine(B)
		xB = variables(B)
    xNew, opNew = Usum_op(xA,xB,opA,opB,false)
    return Expression{length(xNew)}(xNew,opNew)
	end
end

#unsigned sum affines with single variables
function Usum_op(xA::Tuple{Variable}, xB::Tuple{Variable}, A::AbstractOperator, B::AbstractOperator, sign::Bool)
  xNew  = (xA...,xB...)
  opNew = sign ? hcat(A,B) : hcat(A,-B)
	return xNew, opNew
end

#unsigned sum: HCAT + AbstractOperator
function Usum_op(xA::NTuple{N,Variable}, xB::Tuple{Variable}, A::HCAT{N}, B::AbstractOperator, sign::Bool) where {N}
	if xB[1] in xA
    idx = findfirst(xA.==Ref(xB[1]))
    S = sign ? A[idx]+B : A[idx]-B
		xNew = xA
    opNew = hcat(A[1:idx-1],S,A[idx+1:N]  )
	else
    xNew  = (xA...,xB...)
    opNew = sign ? hcat(A,B) : hcat(A,-B)
	end
	return xNew, opNew
end

#unsigned sum: AbstractOperator+HCAT
function Usum_op(xA::Tuple{Variable}, xB::NTuple{N,Variable}, A::AbstractOperator, B::HCAT{N}, sign::Bool) where {N}
	if xA[1] in xB
    idx = findfirst(xA.==Ref(xB[1]))
    S = sign ? A+B[idx] : B[idx]-A
		xNew = xB
    opNew = sign ? hcat(B[1:idx-1],S,B[idx+1:N]  ) : -hcat(B[1:idx-1],S,B[idx+1:N]  )
	else
    xNew  = (xA...,xB...)
    opNew = sign ? hcat(A,B) : hcat(A,-B)
	end

	return xNew, opNew
end

#unsigned sum: HCAT+HCAT
function Usum_op(xA::NTuple{NA,Variable}, xB::NTuple{NB,Variable}, A::HCAT{NB}, B::HCAT{NB}, sign::Bool) where {NA,NB}
	xNew = xA
	opNew = A
	for i in eachindex(xB)
		xNew, opNew = Usum_op(xNew, (xB[i],), opNew, B[i], sign)
	end
  return xNew,opNew
end

#unsigned sum: multivar AbstractOperator + AbstractOperator
function Usum_op(
	xA::NTuple{N,Variable}, xB::Tuple{Variable}, A::AbstractOperator, B::AbstractOperator, sign::Bool
) where {N}
	if xB[1] in xA
		Z = Zeros(A)       #this will be an HCAT
    xNew, opNew = Usum_op(xA,xB,Z,B,sign)
		opNew += A
	else
    xNew  = (xA...,xB...)
    opNew = sign ? hcat(A,B) : hcat(A,-B)
	end
	return xNew, opNew
end

"""
	+(ex::AbstractExpression, b::Union{AbstractArray,Number})

Add a scalar or an `Array` to an expression:

# Example

```julia
julia> x = Variable(10)
Variable(Float64, (10,))

julia> ex = x+4

```

Notice that in order to add an array to `ex`, `b` must belong to the codomain
of the associated `AbstractOperator` of `ex`.

```julia
julia> b = randn(10);

julia> size(b), eltype(b)
((10,), Float64)

julia> size(affine(ex),1), codomainType(affine(ex))
((10,), Float64)

julia> ex + b

```

"""
function (+)(a::AbstractExpression, b::Union{AbstractArray,Number})
  A = convert(Expression,a)
  return Expression{length(A.x)}(A.x,AffineAdd(affine(A),b))
end

(+)(a::Union{AbstractArray,Number}, b::AbstractExpression) = b+a

function (-)(a::AbstractExpression, b::Union{AbstractArray,Number})
  A = convert(Expression,a)
  return Expression{length(A.x)}(A.x,AffineAdd(affine(A),b,false))
end

function (-)(a::Union{AbstractArray,Number}, b::AbstractExpression)
  B = convert(Expression,b)
  return Expression{length(B.x)}(B.x,-AffineAdd(affine(B),a))
end
# sum with array/scalar

#broadcasted + -

function Broadcast.broadcasted(::typeof(+),a::AbstractExpression, b::AbstractExpression)
  A = convert(Expression,a)
  B = convert(Expression,b)
  if size(affine(A),1) != size(affine(B),1)
    if prod(size(affine(A),1)) > prod(size(affine(B),1))
      B = Expression{length(B.x)}(variables(B),
                                  BroadCast(affine(B),size(affine(A),1)))
    elseif prod(size(affine(B),1)) > prod(size(affine(A),1))
      A = Expression{length(A.x)}(variables(A),
                                  BroadCast(affine(A),size(affine(B),1)))
		end
    return A+B
	end
  return A+B
end

function Broadcast.broadcasted(::typeof(-),a::AbstractExpression, b::AbstractExpression)
  A = convert(Expression,a)
  B = convert(Expression,b)
  if size(affine(A),1) != size(affine(B),1)
    if prod(size(affine(A),1)) > prod(size(affine(B),1))
      B = Expression{length(B.x)}(variables(B),
                                  BroadCast(affine(B),size(affine(A),1)))
    elseif prod(size(affine(B),1)) > prod(size(affine(A),1))
      A = Expression{length(A.x)}(variables(A),
                                  BroadCast(affine(A),size(affine(B),1)))
		end
    return A-B
	end
  return A-B
end

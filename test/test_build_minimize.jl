using ProximalAlgorithms

x = Variable(10)
A = randn(5, 10)
y = Variable(7)
B = randn(5, 7)
b = randn(5)

println("\nTesting @minimize \n")
~x .= 0.
~y .= 0.
slv, = @minimize ls(A*x - B*y + b) st norm(x, 2) <= 1e4, norm(y, 1) <= 1.0 with PANOCplus()
~x .= 0.
slv, = @minimize ls(A*x - b) st norm(x, 1) <= 1.0 with PANOCplus()
~x .= 0.
slv, = @minimize ls(A*x - b) st norm(x, 1) <= 1.0
~x .= 0.
slv, = @minimize ls(A*x - b) + norm(x, 1) with PANOCplus()
~x .= 0.
slv, = @minimize ls(A*x - b) + norm(x, 1)
~x .= 0.
slv, = @minimize ls(A*x - b)

#TODO many many more tests
Random.seed!(12345)
x = Variable(5)
A = randn(10, 5)
b = randn(10)

println("\nTesting @minimize nonlinear \n")
slv, = @minimize ls(sigmoid(A*x,10) - b)+norm(x,1) with PANOCplus(tol = 1e-6)
xpg = copy(~x)
~x .= 0.
slv, = @minimize ls(sigmoid(A*x,10) - b)+norm(x,1) with ZeroFPR(tol = 1e-6)
xz = copy(~x)
~x .= 0.
slv, = @minimize ls(sigmoid(A*x,10) - b)+norm(x,1) with PANOC(tol = 1e-6)
xp = copy(~x)
~x .= 0.

@test norm(xz-xpg) <= 1e-4
@test norm(xp-xpg) <= 1e-4

# test nonconvex Rosenbrock function with known minimum
function test_solver(solver)
	x = Variable(1)
	y = Variable(1)
	a, b = 2.0, 100.0

	cf = norm(x - a)^2 + b * norm(pow(x, 2) - y)^2
	@minimize cf + 1e-10 * norm(x, 1) + 1e-10 * norm(y, 1) with solver

	@test norm(~x - [a]) < 1e-4
	@test norm(~y - [a^2]) < 1e-4
end
solvers = [ZeroFPR(; tol=1e-6), PANOC(; tol=1e-6)]
for solver in solvers
	test_solver(solver)
end

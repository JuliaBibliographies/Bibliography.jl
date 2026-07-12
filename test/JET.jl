@testset "Code linting (JET.jl)" begin
    JET.test_package(Bibliography; target_modules = (Bibliography,))
end

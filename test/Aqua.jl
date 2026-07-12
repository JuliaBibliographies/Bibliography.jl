@testset "Aqua.jl" begin
    Aqua.test_all(Bibliography; deps_compat = false)

    @testset "Dependencies compatibility (no extras)" begin
        Aqua.test_deps_compat(Bibliography; check_extras = false)
    end
end

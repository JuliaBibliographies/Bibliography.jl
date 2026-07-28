@testset "Aqua.jl" begin
    # Aqua builds a registry-only wrapper for this check, which cannot resolve
    # the local BibInternal 0.4 / BibParser 0.3 development stack.
    # Re-enable persistent_tasks when those versions have been registered.
    Aqua.test_all(Bibliography; deps_compat = false, persistent_tasks = false)

    @testset "Dependencies compatibility (no extras)" begin
        Aqua.test_deps_compat(Bibliography; check_extras = false)
    end
end

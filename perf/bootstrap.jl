import Pkg

Pkg.activate(@__DIR__)
perfchecker = get(ENV, "PERFCHECKER_PATH",
    normpath(joinpath(@__DIR__, "..", "..", "PerfChecker")))
isdir(perfchecker) && Pkg.develop(path = perfchecker)
Pkg.instantiate()

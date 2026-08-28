import Pkg

Pkg.activate(@__DIR__)
perfchecker = get(ENV, "PERFCHECKER_PATH",
    normpath(joinpath(@__DIR__, "..", "..", "PerfChecker")))
isdir(perfchecker) && Pkg.develop(path = perfchecker)
Pkg.instantiate()

using BenchmarkTools
using PerfChecker
include("suite.jl")

profile = isempty(ARGS) ? :quick : Symbol(first(ARGS))
result = run_suite(bibliography_software_suite(); profile, strict = false)
write_suite_reports(result, joinpath(@__DIR__, "results", string(profile)))
suite_passed(result) || throw(PerfChecker.SuiteRunError(result))

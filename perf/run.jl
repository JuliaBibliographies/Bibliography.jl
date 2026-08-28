include("bootstrap.jl")

using BenchmarkTools
using PerfChecker

profile = isempty(ARGS) ? :quick : Symbol(first(ARGS))
result = run_suite_file(joinpath(@__DIR__, "entrypoint.jl"); profile,
    reports = joinpath(@__DIR__, "results", string(profile)), strict = false)
suite_passed(result) || throw(PerfChecker.SuiteRunError(result))

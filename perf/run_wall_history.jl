include("bootstrap.jl")

using PerfChecker

suite = load_software_suite(joinpath(@__DIR__, "entrypoint.jl"))
full_plan = plan_suite(suite; profile = :historical)
wall_plan = filter_suite_plan(full_plan; backends = :wall_profile, sort = :plan)
result = run_suite_repl(wall_plan; interactive = false, strict = false,
    reports = joinpath(@__DIR__, "results", "historical-wall"))
suite_passed(result) || throw(PerfChecker.SuiteRunError(result))

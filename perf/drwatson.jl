include("bootstrap.jl")

using DrWatson
using PerfChecker

suite = load_software_suite(joinpath(@__DIR__, "entrypoint.jl"))
profile = Symbol(get(ENV, "PERFCHECKER_PROFILE", "quick"))
plan = plan_suite(suite; profile)

cached, cache_path = drwatson_produce_or_load(
    Dict("suite" => string(suite.id), "profile" => string(profile));
    directory = joinpath(@__DIR__, "results", "drwatson"), tag = false) do _
    run_suite(plan; strict = false)
end
result = cached["result"]

write_suite_reports(result, joinpath(@__DIR__, "results", string(profile)))
println("DrWatson cache: $cache_path")
suite_passed(result) || throw(PerfChecker.SuiteRunError(result))

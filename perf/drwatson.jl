include("bootstrap.jl")

using DrWatson
using PerfChecker

suite = load_software_suite(joinpath(@__DIR__, "entrypoint.jl"))
profile = Symbol(get(ENV, "PERFCHECKER_PROFILE", "quick"))
cached, cache_path = drwatson_run_suite(suite; profile,
    directory = joinpath(@__DIR__, "results", "drwatson"), tag = false)
println("DrWatson cache: $cache_path")
get(cached, "passed", false) || error("The cached PerfChecker suite did not pass")

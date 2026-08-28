include("bootstrap.jl")

using Oxygen
using PerfChecker

suite = load_software_suite(joinpath(@__DIR__, "entrypoint.jl"))
profile = Symbol(get(ENV, "PERFCHECKER_PROFILE", "quick"))
host = get(ENV, "PERFCHECKER_HOST", "127.0.0.1")
port = parse(Int, get(ENV, "PERFCHECKER_PORT", "8080"))
serve_suite(suite; profile, host, port)

include("bootstrap.jl")

using Oxygen
using PerfChecker

store = joinpath(@__DIR__, "results")
host = get(ENV, "PERFCHECKER_HOST", "127.0.0.1")
port = parse(Int, get(ENV, "PERFCHECKER_PORT", "8080"))
serve_suite(store; host, port)

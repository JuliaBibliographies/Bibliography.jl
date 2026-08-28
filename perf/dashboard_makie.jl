include("bootstrap.jl")

using CairoMakie
using PerfChecker

suite = load_software_suite(joinpath(@__DIR__, "entrypoint.jl"))
profile = Symbol(get(ENV, "PERFCHECKER_PROFILE", "quick"))
figure = suite_dashboard(suite; profile)
display(figure)

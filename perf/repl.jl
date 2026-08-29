include("bootstrap.jl")

using PerfChecker
using UnicodePlots

suite = load_software_suite(joinpath(@__DIR__, "entrypoint.jl"))
profile = Symbol(get(ENV, "PERFCHECKER_PROFILE", "historical"))
result = run_suite_repl(suite; profile,
    reports = joinpath(@__DIR__, "results", string(profile)))
comparison = compare_suite_versions(PerfChecker._suite_run_bundle(result))
isempty(comparison.series) || display(terminal_plot(comparison))

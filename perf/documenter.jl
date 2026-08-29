include("bootstrap.jl")

using Documenter
using PerfChecker

profile = get(ENV, "PERFCHECKER_PROFILE", "historical")
bundles = list_run_bundles(joinpath(@__DIR__, "results", profile, "bundles"))
isempty(bundles) && error("No $profile PerfChecker bundle is available")
destination = get(ENV, "PERFCHECKER_DOC_PAGE",
    joinpath(@__DIR__, "generated", "performance.md"))
bundle = read_run_bundle(last(bundles)["bundle_path"])
println("Performance page: ",
    documenter_page(bundle, destination;
        title = "Bibliography performance"))

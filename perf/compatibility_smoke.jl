import Pkg

Pkg.activate(@__DIR__)
perfchecker = get(ENV, "PERFCHECKER_PATH",
    normpath(joinpath(@__DIR__, "..", "..", "PerfChecker")))
isdir(perfchecker) && Pkg.develop(path = perfchecker)
Pkg.instantiate()

using BenchmarkTools
using PerfChecker
include("suite.jl")

function released(package::PackageSuite, versions)
    return PackageSuite(package.package; id = package.id,
        environment = package.environment, source = package.source,
        dev_sources = package.dev_sources, versions = VersionNumber.(versions),
        release_pins = package.release_pins,
        features = package.features, include_dev = false)
end

suite = bibliography_software_suite()
compatibility = SoftwareSuite(:bibliography_compatibility,
    [
        released(suite.packages[1], [v"0.1.0", v"0.2.12", v"0.3.0", v"0.4.0"]),
        released(suite.packages[2], [v"0.1.0", v"0.1.3", v"0.1.4", v"0.3.0"]),
        released(suite.packages[3], [v"0.1.0", v"0.4.0"])];
    description = "Oldest and API-boundary releases of the Bibliography suite")

result = run_suite(compatibility; profile = :historical, strict = false)
write_suite_reports(result, joinpath(@__DIR__, "results", "compatibility"))
suite_passed(result) || throw(PerfChecker.SuiteRunError(result))

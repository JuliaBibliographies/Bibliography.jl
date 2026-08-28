using PerfChecker

const BIBLIOGRAPHY_PERF_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const BIBINTERNAL_PERF_SOURCE = get(
    ENV, "BIBINTERNAL_PATH", joinpath(BIBLIOGRAPHY_PERF_ROOT, "BibInternal"))
const BIBPARSER_PERF_SOURCE = get(
    ENV, "BIBPARSER_PATH", joinpath(BIBLIOGRAPHY_PERF_ROOT, "BibParser"))
const BIBLIOGRAPHY_PERF_SOURCE = get(
    ENV, "BIBLIOGRAPHY_PATH", joinpath(BIBLIOGRAPHY_PERF_ROOT, "Bibliography"))

include(joinpath(BIBINTERNAL_PERF_SOURCE, "perf", "suite.jl"))
include(joinpath(BIBPARSER_PERF_SOURCE, "perf", "suite.jl"))

function _bibliography_pins(internal, parser)
    Any[
        (name = "BibInternal", version = internal),
        (name = "BibParser", version = parser)]
end

function bibliography_release_pins()
    pins = Dict{VersionNumber, Vector{Any}}()
    pins[v"0.1.0"] = _bibliography_pins(v"0.1.0", v"0.1.0")
    pins[v"0.2.0"] = _bibliography_pins(v"0.2.0", v"0.1.3")
    pins[v"0.2.1"] = _bibliography_pins(v"0.2.1", v"0.1.4")
    for version in (v"0.2.2", v"0.2.3")
        pins[version] = _bibliography_pins(v"0.2.2", v"0.1.7")
    end
    pins[v"0.2.4"] = _bibliography_pins(v"0.2.3", v"0.1.8")
    for version in (v"0.2.5", v"0.2.6", v"0.2.7", v"0.2.8", v"0.2.9",
        v"0.2.10", v"0.2.11")
        pins[version] = _bibliography_pins(v"0.2.4", v"0.1.9")
    end
    for version in (v"0.2.12", v"0.2.13", v"0.2.14", v"0.2.15")
        pins[version] = _bibliography_pins(v"0.3.0", v"0.1.16")
    end
    pins[v"0.2.16"] = _bibliography_pins(v"0.3.0", v"0.2.0")
    for version in (v"0.2.17", v"0.2.18", v"0.2.19", v"0.2.20")
        pins[version] = _bibliography_pins(v"0.3.3", v"0.2.1")
    end
    for version in (v"0.3.0", v"0.3.1")
        pins[version] = _bibliography_pins(v"0.3.7", v"0.2.2")
    end
    pins[v"0.4.0"] = _bibliography_pins(v"0.4.0", v"0.3.0")
    return pins
end

function bibliography_perf_suite(;
        source = normpath(joinpath(@__DIR__, "..")),
        bibinternal_source = normpath(joinpath(@__DIR__, "..", "..", "BibInternal")),
        bibparser_source = normpath(joinpath(@__DIR__, "..", "..", "BibParser")),
        environment = joinpath(@__DIR__, "runner"))
    common = Dict(:samples => 20, :evals => 1, :seconds => 0.2)
    features = [
        FeatureSpec(:import_bibtex; description = "Import BibTeX into the public model",
            entrypoint = joinpath(@__DIR__, "features", "import_bibtex.jl"),
            comparison_key = "bibliography-import/v1", options = common),
        FeatureSpec(:export_bibtex; description = "Export the public model as BibTeX",
            entrypoint = joinpath(@__DIR__, "features", "export_bibtex.jl"),
            comparison_key = "bibliography-export/v1", options = common),
        FeatureSpec(
            :web_render; description = "Render the web-facing bibliography surface",
            entrypoint = joinpath(@__DIR__, "features", "web_render.jl"),
            comparison_key = "bibliography-web/v1", options = common),
        FeatureSpec(:read_and_filter;
            description = "Read and filter through the normalized document API",
            entrypoint = joinpath(@__DIR__, "features", "read_and_filter.jl"),
            since = v"0.4.0", comparison_key = "bibliography-query/v1", options = common)]
    return PackageSuite("Bibliography"; source, environment, versions = :all,
        dev_sources = [bibinternal_source, bibparser_source],
        release_pins = bibliography_release_pins(), features)
end

function bibliography_software_suite()
    return SoftwareSuite(:bibliography,
        [
            bibinternal_perf_suite(; source = BIBINTERNAL_PERF_SOURCE,
                environment = joinpath(BIBINTERNAL_PERF_SOURCE, "perf", "runner")),
            bibparser_perf_suite(; source = BIBPARSER_PERF_SOURCE,
                bibinternal_source = BIBINTERNAL_PERF_SOURCE,
                environment = joinpath(BIBPARSER_PERF_SOURCE, "perf", "runner")),
            bibliography_perf_suite(; source = BIBLIOGRAPHY_PERF_SOURCE,
                bibinternal_source = BIBINTERNAL_PERF_SOURCE,
                bibparser_source = BIBPARSER_PERF_SOURCE,
                environment = joinpath(BIBLIOGRAPHY_PERF_SOURCE, "perf", "runner"))];
        description = "Public software surface of Bibliography, BibParser, and BibInternal")
end

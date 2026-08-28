include("bootstrap.jl")

using Oxygen
using PerfChecker

suite = load_software_suite(joinpath(@__DIR__, "entrypoint.jl"))
profile = Symbol(get(ENV, "PERFCHECKER_PROFILE", "quick"))
host = get(ENV, "PERFCHECKER_HOST", "127.0.0.1")
port = parse(Int, get(ENV, "PERFCHECKER_PORT", "8080"))
reports_root = joinpath(@__DIR__, "results")
token_digest = get(ENV, "PERFCHECKER_TOKEN_SHA256", "")
authenticator = isempty(token_digest) ? nothing : studio_token_authenticator(Dict(
    token_digest => Dict("id" => get(ENV, "PERFCHECKER_USER", "bibliography-admin"),
        "name" => get(ENV, "PERFCHECKER_USER_NAME", "Bibliography administrator"),
        "roles" => ["admin"])))
serve_suite(suite; profile, host, port, reports_root, authenticator,
    allow_remote_control = !isempty(token_digest))

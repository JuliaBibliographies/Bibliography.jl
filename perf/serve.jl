include("bootstrap.jl")

using Oxygen
using PerfChecker
using WGLMakie

suite = load_software_suite(joinpath(@__DIR__, "entrypoint.jl"))
profile = Symbol(get(ENV, "PERFCHECKER_PROFILE", "quick"))
host = get(ENV, "PERFCHECKER_HOST", "127.0.0.1")
port = parse(Int, get(ENV, "PERFCHECKER_PORT", "8080"))
reports_root = joinpath(@__DIR__, "results")
token_digest = get(ENV, "PERFCHECKER_TOKEN_SHA256", "")
users_file = get(ENV, "PERFCHECKER_USERS_FILE", "")
authenticator = if !isempty(users_file)
    studio_token_authenticator(users_file)
elseif !isempty(token_digest)
    studio_token_authenticator(Dict(token_digest => Dict(
        "id" => get(ENV, "PERFCHECKER_USER", "bibliography-admin"),
        "name" => get(ENV, "PERFCHECKER_USER_NAME", "Bibliography administrator"),
        "roles" => ["admin"])))
else
    nothing
end
remote_control = !(host in ("127.0.0.1", "localhost", "::1"))
serve_suite(suite; profile, host, port, reports_root, authenticator,
    allow_remote_control = remote_control, secure_cookies = remote_control)

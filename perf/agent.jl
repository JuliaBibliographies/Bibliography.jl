include("bootstrap.jl")

using Oxygen
using PerfChecker

suite = load_software_suite(joinpath(@__DIR__, "entrypoint.jl"))
server = get(ENV, "PERFCHECKER_SERVER", "http://127.0.0.1:8080/perfchecker/v1")
token = get(ENV, "PERFCHECKER_AGENT_TOKEN", "")
isempty(token) && error("PERFCHECKER_AGENT_TOKEN is required")
agent_id = get(ENV, "PERFCHECKER_AGENT_ID",
    get(ENV, "COMPUTERNAME", "bibliography-agent"))
poll_seconds = parse(Float64, get(ENV, "PERFCHECKER_AGENT_POLL_SECONDS", "2"))
heartbeat_seconds = parse(
    Float64, get(ENV, "PERFCHECKER_AGENT_HEARTBEAT_SECONDS", "30"))
max_jobs = parse(Int, get(ENV, "PERFCHECKER_AGENT_MAX_JOBS", string(typemax(Int))))
once = lowercase(get(ENV, "PERFCHECKER_AGENT_ONCE", "false")) in
       ("1", "true", "yes", "on")

run_studio_agent(suite; server, token, agent_id, poll_seconds, heartbeat_seconds,
    max_jobs, once)

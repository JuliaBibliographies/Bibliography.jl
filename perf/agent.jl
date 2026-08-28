include("bootstrap.jl")

using Oxygen
using PerfChecker

suite = load_software_suite(joinpath(@__DIR__, "entrypoint.jl"))
server = get(ENV, "PERFCHECKER_SERVER", "http://127.0.0.1:8080/perfchecker/v1")
token = get(ENV, "PERFCHECKER_AGENT_TOKEN", "")
isempty(token) && error("PERFCHECKER_AGENT_TOKEN is required")
agent_id = get(ENV, "PERFCHECKER_AGENT_ID",
    get(ENV, "COMPUTERNAME", "bibliography-agent"))

run_studio_agent(suite; server, token, agent_id)

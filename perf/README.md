# Bibliography performance suite

This directory defines feature-level performance contracts for the complete
Bibliography software surface: `BibInternal`, `BibParser`, and `Bibliography`.
Every measurement is executed in a fresh Malt worker. The worker environment
contains the benchmark backend and the selected package version, but it never
loads PerfChecker or any dashboard dependency. Results include a median series
for every comparable package/feature/metric, adjacent-release comparisons, and
development-versus-latest-release comparisons. Unsupported and failed targets
remain visible instead of being silently skipped.

Run the current local sources:

```powershell
julia --startup-file=no --project=perf perf/run.jl quick
```

Run representative releases from every compatibility line plus the local
sources:

```powershell
julia --startup-file=no --project=perf perf/run.jl ci
```

Run every registered release:

```powershell
julia --startup-file=no --project=perf perf/run.jl historical
```

Collect only the Julia 1.12 wall-time profiles for every historical target
while retaining the existing timing/allocation history:

```powershell
julia --startup-file=no --project=perf perf/run_wall_history.jl
```

Exercise the oldest release and every workload API boundary before a full
historical campaign:

```powershell
julia --startup-file=no --project=perf perf/compatibility_smoke.jl
```

Set `PERFCHECKER_PATH`, `BIBINTERNAL_PATH`, `BIBPARSER_PATH`, or
`BIBLIOGRAPHY_PATH` to override the default sibling checkouts. JSON, Markdown,
and JUnit reports, version series/comparisons, plus a portable observation bundle are written below
`perf/results/<profile>/` for local review, Oxygen browsing, and CI artifact
collection.

## Interfaces

All interfaces stay in the controller and launch the same Malt-isolated runs:

```powershell
# Oxygen Performance Studio: configure, reorder, launch and compare
julia --startup-file=no --project=perf perf/serve.jl

# Read-only Oxygen browser for already collected bundles
julia --startup-file=no --project=perf perf/serve_results.jl

# Makie dashboard; runs the selected profile before displaying it
julia --startup-file=no --project=perf perf/dashboard_makie.jl

# DrWatson cached experiment
julia --startup-file=no --project=perf perf/drwatson.jl

# Pluto launcher
julia --startup-file=no --project=perf -e 'using Pluto; Pluto.run(notebook="perf/dashboard.jl")'

# Guided REPL selection with progress bar and UnicodePlots summary
julia --startup-file=no --project=perf perf/repl.jl

# Generate a Documenter-ready performance page from a stored bundle
julia --startup-file=no --project=perf perf/documenter.jl

# Build and execute a Julia 1.12 JuliaC smoke executable
julia --startup-file=no --project=. perf/juliac.jl
```

The JuliaC smoke entry point exercises the lossless BibTeX read, canonical
projection, and normalized write path used when Bibliography is embedded as a
dependency. Build products stay below the ignored `perf/results/juliac/`
directory. The default `no` trim mode verifies executable packaging without
changing Julia's reachability semantics. Pass `safe`, `unsafe`, or
`unsafe-warn` explicitly when investigating the experimental Julia 1.12
trimmer; the strict `safe` mode is expected to reject dynamic format and error
paths that are valid in the normal package API.

The REPL uses the same inclusive version bounds, package/feature/backend
filters, search and stable sort modes as the Studio. It returns the same
revisioned `SuitePlan`, shows progress for every worker, and can be scripted
through `filter_suite_plan` and `run_suite_repl`. Loading `UnicodePlots` adds
terminal-native version plots without loading Makie. Loading `Documenter`
adds performance-page generation; loading `DocumenterVitepress` adds a
`MarkdownVitepress` build entry point over the same bundle.

The Oxygen Studio embeds real WGLMakie figures. Large histories are selected by
inclusive version range, package/feature/backend filters and batch actions;
cards can be sorted by semantic version, package or feature and use stable
colour labels. Its plot picker covers release
trajectories, per-version distributions, regression deltas, time/allocation
trade-offs, allocations grouped by source file, top `file:line` allocation
sites, a version-by-line heatmap, allocation-share pie charts, and CPU or
allocation flame graphs. The same plot grammar can be rendered in a
local GLMakie window or exported with CairoMakie for CI artifacts.

Each benchmark feature has a matching allocation feature. Those allocation
runs use the same feature entrypoint and version window in a separate Malt
worker using Julia's allocation profiler. The measured process still
does not load PerfChecker, WGLMakie, Oxygen, Pluto, or DrWatson.
Each benchmark feature also has a matching CPU-profile feature. It warms the
workload, samples only the isolated worker with Julia's `Profile` standard
library, and stores portable call stacks for the flame-graph view.
On Julia 1.12 and newer, every benchmark also has a task wall-time profile for
finding waits and scheduler delays that CPU sampling does not expose.

Use `PERFCHECKER_PROFILE` to select `quick`, `ci`, or `historical` for the
controller scripts. `perf/github-actions.yml` is the ready-to-copy CI workflow;
move it to `.github/workflows/performance.yml` once the PerfChecker branch has
been merged into its public `main` branch.

The Studio is local-only by default at `http://127.0.0.1:8080/perfchecker/v1/`.
Completed bundles and the durable job/session/agent state remain on disk below
`perf/results/`; interrupted controller jobs are recovered after restart.

## Hosted controller and remote agents

For a network-facing controller, provide a TOML user store (recommended) or the
legacy single SHA-256 digest. Clear tokens are never stored:

```powershell
$env:PERFCHECKER_HOST = "0.0.0.0"
$env:PERFCHECKER_USERS_FILE = "C:\\secure\\perfchecker-users.toml"
julia --startup-file=no --project=perf perf/serve.jl
```

```toml
[[users]]
id = "package-developer"
name = "Package developer"
roles = ["runner", "agent"]
agent_ids = ["benchmark-windows-01"]
token_sha256 = "<64 hexadecimal characters>"
```

Put TLS in front of Oxygen. The supplied token identity has the `admin` role;
production deployments can pass an external bearer-token/OIDC validator and a
custom authorizer to `serve_suite`. The built-in roles are `admin`, `runner`,
and `agent`.

On another machine with the same suite revision and package sources, start a
pull-based agent:

```powershell
$env:PERFCHECKER_SERVER = "https://perf.example.org/perfchecker/v1"
$env:PERFCHECKER_AGENT_TOKEN = "<agent token>"
$env:PERFCHECKER_AGENT_ID = "benchmark-windows-01"
julia --startup-file=no --project=perf perf/agent.jl
```

For a bounded CI or WSL smoke run, set `PERFCHECKER_AGENT_ONCE=true` or
`PERFCHECKER_AGENT_MAX_JOBS`; polling and lease renewal can be tuned with
`PERFCHECKER_AGENT_POLL_SECONDS` and `PERFCHECKER_AGENT_HEARTBEAT_SECONDS`.

The web UI can target the server process, any available remote agent, or one
named agent. Agent work uses expiring lease tokens, heartbeats and bounded
retry; the controller can cancel queued or running jobs. An agent accepts only server-generated run identifiers, verifies
the suite-plan revision locally, starts the same fresh Malt workers, then sends
the portable result bundle back to Oxygen.

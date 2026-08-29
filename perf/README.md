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
```

The Oxygen Studio embeds real WGLMakie figures. Its plot picker covers release
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

Use `PERFCHECKER_PROFILE` to select `quick`, `ci`, or `historical` for the
controller scripts. `perf/github-actions.yml` is the ready-to-copy CI workflow;
move it to `.github/workflows/performance.yml` once the PerfChecker branch has
been merged into its public `main` branch.

The Studio is local-only by default at `http://127.0.0.1:8080/perfchecker/v1/`.
Its matrix supports pointer drag-and-drop, explicit add/remove and move buttons,
and keyboard operation. Completed bundles remain on disk under
`perf/results/jobs/`; the Studio also indexes existing CI and historical
bundles anywhere below `perf/results/`. The lightweight job queue itself is
held in the controller process.

## Hosted controller and remote agents

For a network-facing controller, provide the SHA-256 digest of a personal token.
The clear token is never stored in the suite:

```powershell
$env:PERFCHECKER_HOST = "0.0.0.0"
$env:PERFCHECKER_TOKEN_SHA256 = "<sha256 digest>"
julia --startup-file=no --project=perf perf/serve.jl
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

The web UI can target the server process, any available remote agent, or one
named agent. An agent accepts only server-generated run identifiers, verifies
the suite-plan revision locally, starts the same fresh Malt workers, then sends
the portable result bundle back to Oxygen.

# Bibliography performance suite

This directory defines feature-level performance contracts for the complete
Bibliography software surface: `BibInternal`, `BibParser`, and `Bibliography`.
Every measurement is executed in a fresh Malt worker. The worker environment
contains the benchmark backend and the selected package version, but it never
loads PerfChecker or any dashboard dependency.

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
and JUnit reports are written below `perf/results/<profile>/` for local review
and CI artifact collection.

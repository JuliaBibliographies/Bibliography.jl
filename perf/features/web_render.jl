using Bibliography

function perf_setup()
    path = tempname() * ".bib"
    write(path, """@article{lovelace2026,
      title = {A reusable performance contract},
      author = {Ada Lovelace},
      journal = {Julia Studies},
      volume = {1},
      year = {2026}
    }
    """)
    return path
end

perf_workload(path) = Bibliography.bibtex_to_web(path)

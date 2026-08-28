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
    return Bibliography.import_bibtex(path)
end

perf_workload(bibliography) = Bibliography.export_bibtex(bibliography)

using Bibliography

function perf_setup()
    return """@article{lovelace2026,
      title = {A reusable performance contract},
      author = {Ada Lovelace},
      journal = {Julia Studies},
      volume = {1},
      year = {2026}
    }
    """
end

function perf_workload(input)
    document = Bibliography.read_bibliography(input; format = :BibTeX, check = :none)
    return Bibliography.filter_bibliography(document) do entry
        occursin("performance", lowercase(entry.title))
    end
end

@testset "format-agnostic API" begin
    bib = """
    @article{z,
      author = {Zulu, Zoe},
      title = {Last},
      journal = {Journal},
      year = {2024}
    }

    @article{a,
      author = {Alpha, Ada},
      title = {First},
      journal = {Journal},
      year = {2020}
    }
    """

    document = read_bibliography(bib)
    @test document.format == :BibTeX
    @test document.source == bib
    @test length(document.entries) == 2

    entries = bibliography_entries(document)
    @test collect(keys(entries)) == ["z", "a"]
    @test entries["a"].title == "First"

    @test validate(document).ok
    @test write_bibliography(document; mode = :original) == bib
    normalized = write_bibliography(document)
    @test occursin("@article{z", normalized)
    @test occursin("title", normalized)

    selected = select(document, ["a"])
    @test length(selected.entries) == 1
    @test selected.entries[1].id == "a"

    filtered = filter_bibliography(document) do entry
        entry.date.year == "2024"
    end
    @test length(filtered.entries) == 1
    @test filtered.entries[1].id == "z"

    sort_bibliography!(document)
    @test [entry.id for entry in document.entries] == ["a", "z"]

    mktempdir() do dir
        target = joinpath(dir, "refs.bib")
        written = write_bibliography(target, document)
        @test read(target, String) == written
    end
end

@testset "format-agnostic BibLaTeX validation" begin
    biblatex = """
    @online{dataset,
      title = {Dataset},
      date = {2024-03-15},
      url = {https://example.test/data}
    }
    """
    document = read_bibliography(biblatex; format = :BibLaTeX)
    @test validate(document).ok
    @test bibliography_entries(document)["dataset"].date.year == "2024"
end

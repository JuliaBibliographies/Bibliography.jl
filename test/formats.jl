@testset "all-format import/export round-trips" begin
    source = """
    @article{lovelace1843,
      author = {Lovelace, Ada},
      editor = {Editor, Erin},
      title = {Computing & Engines},
      journal = {Scientific Notes},
      year = {1843},
      month = {12},
      day = {10},
      volume = {3},
      number = {2},
      pages = {1--10},
      publisher = {Example Press},
      address = {London},
      doi = {10.1234/example},
      url = {https://example.test/paper},
      note = {Round trip}
    }
    """
    original = read_bibliography(source; format = :BibTeX)
    expected = only(original.entries)

    for format in (:BibTeX, :BibLaTeX, :CSL, :RIS, :EndNote, :MODS)
        encoded = write_bibliography(original; format)
        @test !isempty(encoded)
        decoded = read_bibliography(encoded; format)
        @test isempty(decoded.diagnostics)
        @test length(decoded.entries) == 1
        actual = only(decoded.entries)
        @test actual.id == expected.id
        @test actual.title == expected.title
        @test actual.date.year == expected.date.year
        @test only(actual.authors).last == "Lovelace"
    end

    cff = write_bibliography(original; format = :CFF)
    @test occursin("cff-version", cff)
    cff_document = read_bibliography(cff; format = :CFF)
    @test isempty(cff_document.diagnostics)
    @test only(cff_document.entries).title == expected.title

    @test write_bibliography(original; mode = :original) == source
    @test_throws ArgumentError write_bibliography(original; format = :Unknown)
end

@testset "multi-entry and type coverage" begin
    source = """
    @book{book,
      author={Hopper, Grace}, title={Compilers}, publisher={Press}, year={1952}
    }
    @inproceedings{paper,
      author={Turing, Alan}, title={Machines}, booktitle={Proceedings}, year={1936}
    }
    @techreport{report,
      author={Lovelace, Ada}, title={Notes}, institution={Lab}, year={1843}
    }
    """
    document = read_bibliography(source)
    for format in (:BibTeX, :BibLaTeX, :CSL, :RIS, :EndNote, :MODS)
        encoded = write_bibliography(document; format)
        decoded = read_bibliography(encoded; format, check = :none)
        @test isempty(decoded.diagnostics)
        @test length(decoded.entries) == 3
        @test Set(entry.title for entry in decoded.entries) ==
              Set(["Compilers", "Machines", "Notes"])
    end

    for entry in document.entries
        single = BibInternal.BibliographyDocument(format = :BibTeX, entries = [entry])
        encoded = write_bibliography(single; format = :CFF)
        decoded = read_bibliography(encoded; format = :CFF)
        @test isempty(decoded.diagnostics)
        @test only(decoded.entries).title == entry.title
    end
end

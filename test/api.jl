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

    @test Bibliography.validate(document).ok
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

@testset "legacy BibTeX import is permissive by default" begin
    loose = """
    @inproceedings{loose,
      author = {Doe, Jane},
      title = {Proceedings-like Entry},
      year = {2024}
    }
    """
    imported = import_bibtex(loose)
    @test haskey(imported, "loose")
    @test imported["loose"].title == "Proceedings-like Entry"
    @test_throws "missing the booktitle" import_bibtex(loose; check = :error)
end

@testset "format-agnostic BibLaTeX validation" begin
    biblatex = """
    @online{dataset,
      author = {Doe, Jane},
      title = {Dataset},
      date = {2024-03-15},
      url = {https://example.test/data}
    }
    """
    document = read_bibliography(biblatex; format = :BibLaTeX)
    @test Bibliography.validate(document).ok
    @test bibliography_entries(document)["dataset"].date.year == "2024"
end

@testset "format and product rule profiles compose" begin
    lazyweb = BibInternal.RuleProfile(
        name=:LazyWeb,
        global_rules=[BibInternal.RequiredField("labels")],
        global_fields=Set(["labels"]),
    )
    profile = Bibliography.compose_rule_profiles(
        :BibTeX,
        lazyweb;
        name=:LazyWebBibTeX,
    )
    @test isempty(profile.diagnostics)
    @test "labels" in BibInternal.profile_field_names(profile, "article")

    source = """
    @article{demo,
      author = {Doe, Jane},
      title = {A result},
      journal = {Journal},
      year = {2026}
    }
    """
    document = Bibliography.read_bibliography(source)
    result = Bibliography.validate(document; profile)
    @test !result.ok
    @test any(
        diagnostic ->
            diagnostic.code == :missing_required_field &&
            diagnostic.field == "labels",
        result.diagnostics,
    )

    cff = Bibliography.rule_profile(:CFF)
    @test any(
        rule -> rule isa BibInternal.RequiredField && rule.name == "title",
        cff.global_rules,
    )
    @test_throws ArgumentError Bibliography.validate(
        document;
        profile,
        ruleset=BibInternal.BIBTEX_RULESET,
    )
end

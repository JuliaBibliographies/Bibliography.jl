using FileIO
using Test
using ReferenceTests

@testset "FileIO" begin
    for file in ["test.bib"] #, "xampl.bib"] #, "ignace_ref.bib"]
        test_import = Bibliography.import_bibtex("../examples/$file")
        result = Bibliography.export_web(test_import)

        # FIXME - this test is failing (probably due to changes in ReferenceTests.jl)
        # test re-exporting to bib file
        # result = Bibliography.export_bibtex("result.bib", test_import)
        # Sys.WORD_SIZE == 64 && @test_reference "$file" result

        # if file == "test.bib"
        #     # test re-exporting a selection to bib file
        #     selection = ["CitekeyArticle", "CitekeyBook"]
        #     test_select = Bibliography.select(test_import, selection)
        #     result = Bibliography.export_bibtex("result.bib", test_select)
        #     Sys.WORD_SIZE == 64 && @test_reference "test-selection.bib" result
        # end

        # rm("result.bib")
    end

    testdata = """@inproceedings{demo2020proceedings,
    organization  = {DemoOrg},
    pages         = {1--10},
    doi           = {10.1000/001-1-001-00001-1_001},
    author        = {Demo, D},
    note          = {cited by 0},
    year          = {2020},
    booktitle     = {Demo Booktitle},
    title         = {Demo Title}
    }"""

    write("demo.bib", testdata)
    Bibliography.import_bibtex(testdata)
    mybib = Bibliography.import_bibtex("demo.bib")
    Bibliography.export_bibtex("demo_export.bib", mybib)
    mybib2 = Bibliography.import_bibtex("demo_export.bib")

    custom = """@article{custom2026,
    author = {Doe, Jane},
    title = {Preserved metadata},
    journal = {Journal of Metadata},
    year = {2026},
    swp-labels = {Julia, optimization},
    institution-color = {navy-gold},
    custom-project-id = {project-42}
    }"""
    custom_bib = Bibliography.import_bibtex(custom)
    custom_export = Bibliography.export_bibtex(custom_bib)
    @test occursin("swp-labels", custom_export)
    @test occursin("institution-color", custom_export)
    @test occursin("custom-project-id", custom_export)
    custom_roundtrip = Bibliography.import_bibtex(custom_export)
    @test custom_roundtrip["custom2026"].fields["swp-labels"] ==
          "Julia, optimization"
    @test custom_roundtrip["custom2026"].fields["institution-color"] ==
          "navy-gold"
    @test custom_roundtrip["custom2026"].fields["custom-project-id"] ==
          "project-42"

    rm("demo.bib")
    rm("demo_export.bib")

    include("sort_bibliography.jl")
    include("staticweb.jl")
    include("cff.jl")
    include("test-fileio.jl")
end

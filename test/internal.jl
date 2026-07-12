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

    rm("demo.bib")
    rm("demo_export.bib")

    include("api.jl")
    include("sort_bibliography.jl")
    include("staticweb.jl")
    include("cff.jl")
    include("test-fileio.jl")
    include("formats.jl")
end

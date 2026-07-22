using Bibliography
using ReferenceTests

@testset "cff" begin
    bib = Bibliography.import_cff("../examples/CITATION.cff")
    rm("CITATION.cff", force = true)
    Bibliography.export_cff(bib)
    # TODO - generate a test file for 32 bits architecture
    if Sys.WORD_SIZE == 64
        @test_reference "CITATION.cff.txt" read("CITATION.cff", String)
    end
    rm("CITATION.cff")
end

@testset "cff export tolerates partial dates" begin
    entry = only(values(Bibliography.import_bibtex("""
        @misc{undated, title={Undated software}, author={Doe, Jane}}
        """)))
    destination = tempname() * ".cff"
    exported = Bibliography.export_cff(entry; destination, add_preferred=false)
    @test !haskey(exported, "date-released")
    @test isfile(destination)
end

@testset "cff import derives stable identifiers without a DOI" begin
    destination = tempname() * ".cff"
    write(destination, """
cff-version: 1.2.0
message: Cite this work.
title: Research software
authors:
  - family-names: Doe
    given-names: Jane
date-released: "2025-01-02"
""")
    first_import = Bibliography.import_cff(destination)
    second_import = Bibliography.import_cff(destination)
    @test first_import.id == second_import.id == "cff-research-software-2025"
    @test first_import.title == "Research software"
end

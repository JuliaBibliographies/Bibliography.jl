using Bibliography

@testset "cff" begin
    bib = Bibliography.import_cff("../examples/CITATION.cff")
    mktempdir() do dir
        target = joinpath(dir, "CITATION.cff")
        exported = Bibliography.export_cff(bib; destination = target)
        @test exported["cff-version"] == "1.2.0"
        @test isfile(target)
        imported = Bibliography.import_cff(target)
        @test imported.title == bib.title
        @test imported.authors == bib.authors
    end
end


@testset "CFF collection" begin
    source = """
    @book{hopper1952,
      author = {Hopper, Grace}, title = {Compilers}, publisher = {Press}, year = {1952}
    }
    @article{lovelace1843,
      author = {Lovelace, Ada}, title = {Notes}, journal = {Scientific Memoirs}, year = {1843}
    }
    """
    bibliography = read_bibliography(source; format = :BibTeX)

    mktempdir() do directory
        paths = export_cff_collection(bibliography; destination = directory)
        @test basename.(paths) == ["hopper1952.cff", "lovelace1843.cff"]
        @test all(isfile, paths)

        imported = import_cff_collection(directory)
        @test collect(keys(imported)) == ["hopper1952", "lovelace1843"]
        @test [entry.title for entry in values(imported)] == ["Compilers", "Notes"]
        @test [only(entry.authors).last for entry in values(imported)] ==
              ["Hopper", "Lovelace"]

        explicit = import_cff_collection(reverse(paths))
        @test collect(keys(explicit)) == ["lovelace1843", "hopper1952"]
    end

    mktempdir() do directory
        write(joinpath(directory, "duplicate.cff"), "")
        @test_throws ArgumentError import_cff_collection(
            [joinpath(directory, "duplicate.cff"), joinpath(directory, "duplicate.cff")])
    end
    @test_throws ArgumentError import_cff_collection("not-a-cff-directory")
end

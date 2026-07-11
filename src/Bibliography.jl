module Bibliography

# BibInternal
import BibInternal
import BibInternal: AbstractEntry, Entry

# BibParser
import BibParser
import BibParser: BibTeX, CFF

# Others
import DataStructures
import DataStructures.OrderedSet
import FileIO

export export_bibtex, import_bibtex
export export_cff, import_cff
export export_web, bibtex_to_web
export bibliography_entries, filter_bibliography, read_bibliography, validate, write_bibliography
export select
export sort_bibliography!

include("select.jl")
include("sort_bibliography.jl")
include("bibtex.jl")
include("cff.jl")
include("csl.jl")
include("api.jl")
include("staticweb.jl")
include("fileio.jl")

"""
    export_bibtex(target, bibliography)
Export a bibliography to BibTeX format.
"""
function export_bibtex(target, bibliography)
    data = export_bibtex(bibliography)
    if target != ""
        f = open(target, "w")
        write(f, data)
        close(f)
    end
    return data
end

"""
    bibtex_to_web(source::String)
Convert a BibTeX file to a web compatible format, specifically for the [StaticWebPages.jl](https://github.com/Humans-of-Julia/StaticWebPages.jl) package.
"""
bibtex_to_web(source) = export_web(import_bibtex(source))

end # module

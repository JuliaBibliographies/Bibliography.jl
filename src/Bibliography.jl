module Bibliography

# BibInternal
import BibInternal
import BibInternal: AbstractEntry, Entry

# BibParser
import BibParser
import BibParser: BibTeX

# Others
import DataStructures
import DataStructures.OrderedSet
import FileIO
import JSONSchema
import YAML

export export_bibtex, import_bibtex
export export_biblatex, export_ris
export export_csl, export_endnote, export_mods
export export_cff, import_cff, export_cff_collection, import_cff_collection
export export_web, bibtex_to_web
export bibliography_entries, filter_bibliography, read_bibliography, validate,
       write_bibliography
export select
export sort_bibliography!

include("select.jl")
include("sort_bibliography.jl")
include("bibtex.jl")
include("cff.jl")
include("csl.jl")
include("ris.jl")
include("api.jl")
include("staticweb.jl")
include("fileio.jl")

export_csl(args...) = throw(ArgumentError("The CSL writer extension is not loaded."))
function export_endnote(args...)
    throw(ArgumentError("The EndNote writer extension is not loaded."))
end
export_mods(args...) = throw(ArgumentError("The MODS writer extension is not loaded."))

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

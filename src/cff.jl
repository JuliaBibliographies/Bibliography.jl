import Dates: Dates, Date
import YAML

"""
    import_cff(input) -> Entry
Import a CFF file and convert it to the internal bibliography format.
"""
function import_cff(input)
    # TODO decide how to treat errors
    entry, _ = BibParser.parse_file(input, :CFF)
    return entry
end

"""
    import_cff_collection(source) -> OrderedDict{String, Entry}

Import a collection of independent CFF documents. `source` can be a directory
containing `.cff` files or a vector of file paths. Each file stem becomes the
entry id, making directory export/import round-trips preserve bibliography
keys without adding non-standard fields to the CFF documents.
"""
function import_cff_collection(source::AbstractString)
    isdir(source) || throw(ArgumentError("CFF collection source is not a directory: $source"))
    inputs = sort!(filter(path -> lowercase(splitext(path)[2]) == ".cff",
        readdir(source; join = true)))
    return import_cff_collection(inputs)
end

function import_cff_collection(inputs::AbstractVector{<:AbstractString})
    entries = DataStructures.OrderedDict{String, Entry}()
    for input in inputs
        id = splitext(basename(input))[1]
        haskey(entries, id) &&
            throw(ArgumentError("Duplicate CFF collection id: $id"))
        entry, ok = BibParser.parse_file(input, :CFF)
        ok || throw(ArgumentError("Could not import CFF document: $input"))
        entries[id] = Entry(entry.access, entry.authors, entry.booktitle, entry.date,
            entry.editors, entry.eprint, id, entry.in, entry.fields, entry.note,
            entry.title, entry.type)
    end
    return entries
end

const BIB_TO_CFF_TYPES = Dict{String, String}(
    ["article" => "article"
     "book" => "book"
     "booklet" => "pamphlet"
     "manual" => "manual"
     "proceedings" => "proceedings"
     "unpublished" => "unpublished"]
)
"""
    export_cff(e::Entry, destination::String="CITATION.cff", version::String="1.2.0", add_preferred::Bool=true) -> Dict{String, Any}

Export an `Entry` to a CFF file (default is `CITATION.cff`).
"""
function cff_dict(e::Entry; version::String = "1.2.0", add_preferred::Bool = true)
    cff = Dict{String, Any}()

    # mandatory fields
    cff["authors"] = map(
        name -> Dict(
            "family-names" => na_if_empty(name.last),
            "given-names" => na_if_empty(name.first * name.middle),
            "name-particle" => na_if_empty(name.particle),
            "name-suffix" => na_if_empty(name.junior)
        ),
        e.authors
    )
    cff["cff-version"] = version
    cff["message"] = "If you use this software, please cite it using the metadata from this file."
    cff["title"] = e.title

    isempty(e.access.doi) || (cff["doi"] = e.access.doi)
    isempty(e.access.url) || (cff["repository-code"] = e.access.url)
    released = cff_parse_date(e.date)
    isempty(released) || (cff["date-released"] = released)

    if add_preferred
        preferred = deepcopy(cff)
        delete!(preferred, "cff-version")
        delete!(preferred, "message")

        start = split(e.in.pages, "--")
        isempty(first(start)) || (preferred["start"] = first(start))
        length(start) == 2 && !isempty(last(start)) && (preferred["end"] = last(start))
        isempty(e.in.journal) || (preferred["journal"] = e.in.journal)
        isempty(e.in.number) || (preferred["issue"] = e.in.number)
        isempty(e.in.volume) || (preferred["volume"] = e.in.volume)
        preferred["year"] = e.date.year
        isempty(e.in.publisher) ||
            (preferred["publisher"] = Dict("name" => e.in.publisher))
        preferred["type"] = get(BIB_TO_CFF_TYPES, e.type, "generic")

        cff["preferred-citation"] = preferred
    end

    return cff
end

"""
    export_cff(e::Entry; destination::String = "CITATION.cff",
               version::String = "1.2.0", add_preferred::Bool = true)

Export an `Entry` to a CFF file and return the generated dictionary.
"""
function export_cff(e::Entry; destination::String = "CITATION.cff",
        version::String = "1.2.0", add_preferred::Bool = true)
    cff = cff_dict(e; version, add_preferred)
    YAML.write_file(destination, cff)
    return cff
end

"""
    export_cff_collection(bibliography; destination, version="1.2.0",
                          add_preferred=true) -> Vector{String}

Export every bibliography entry as an independent, specification-compliant
CFF document in `destination`. Files are named `<entry-id>.cff`; the returned
vector contains their paths in bibliography order.
"""
function export_cff_collection(bibliography; destination::AbstractString,
        version::String = "1.2.0", add_preferred::Bool = true)
    entries = bibliography_entries(bibliography)
    mkpath(destination)
    paths = String[]
    for (id, abstract_entry) in entries
        occursin(r"^[A-Za-z0-9][A-Za-z0-9._-]*$", id) || throw(ArgumentError(
            "CFF collection entry id '$id' cannot be used safely as a file name."))
        entry = BibInternal.canonical(abstract_entry)
        path = joinpath(destination, string(id, ".cff"))
        export_cff(entry; destination = path, version, add_preferred)
        push!(paths, path)
    end
    return paths
end

function cff_parse_date(date::BibInternal.Date)
    any(isempty, (date.year, date.month, date.day)) && return ""
    return string(Date(parse(Int, date.year), parse(Int, date.month), parse(Int, date.day)))
end

"""
    na_if_empty(str::AbstractString) -> AbstractString

Use placeholder value if string param is empty.
"""
function na_if_empty(str::AbstractString)
    isempty(str) ? "N/A" : str
end

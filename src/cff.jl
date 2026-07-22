import Dates: Dates, Date
import YAML

"""
    import_cff(input; id="") -> Entry
Import a CFF file and convert it to the internal bibliography format.

When no identifier is supplied, a deterministic internal identifier is derived
from the CFF title and release year. CFF itself has no citation-key field.
"""
function import_cff(input; id::AbstractString="")
    content = YAML.load_file(input; dicttype=Dict{String,Any})
    identifier = isempty(id) ? cff_identifier(input) : String(id)
    # BibParser 0.2.x fails while generating an identifier for CFF records
    # without a DOI. Supplying a deterministic identifier also makes repeated
    # imports stable.
    entry, valid = parse_cff_entry(input, content, identifier)
    valid || throw(ArgumentError("Invalid or unsupported CFF file: $input"))
    return entry
end

function parse_cff_entry(input, content::AbstractDict, identifier::AbstractString)
    haskey(content, "preferred-citation") &&
        return BibParser.CFF.parse_file(input; id=identifier)

    # BibParser 0.2.x validates a root-only CFF correctly, then assumes a
    # reference `type` that the CFF root schema does not define. Parse through
    # a temporary, schema-valid preferred citation while leaving the source
    # document untouched.
    synthesized = deepcopy(content)
    citation = Dict{String,Any}(
        "authors" => deepcopy(content["authors"]),
        "title" => content["title"],
        "type" => "software",
    )
    for field in (
        "abstract", "date-released", "doi", "identifiers", "repository-code",
        "url",
    )
        haskey(content, field) && (citation[field] = deepcopy(content[field]))
    end
    synthesized["preferred-citation"] = citation
    temporary = tempname() * ".cff"
    try
        YAML.write_file(temporary, synthesized)
        return BibParser.CFF.parse_file(temporary; id=identifier)
    finally
        isfile(temporary) && rm(temporary; force=true)
    end
end

function cff_identifier(input)
    content = YAML.load_file(input; dicttype=Dict{String,Any})
    citation = get(content, "preferred-citation", content)
    title = strip(string(get(citation, "title", get(content, "title", "citation"))))
    date = string(get(citation, "date-released", get(content, "date-released", "")))
    year_match = match(r"\b\d{4}\b", date)
    year = year_match === nothing ? "" : year_match.match
    slug = lowercase(replace(title, r"[^\pL\pN]+" => "-"))
    slug = strip(slug, ['-'])
    isempty(slug) && (slug = "citation")
    return isempty(year) ? "cff-$slug" : "cff-$slug-$year"
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
function export_cff(e::Entry; destination::String = "CITATION.cff",
        version::String = "1.2.0", add_preferred::Bool = true)
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
    release_date = cff_parse_date(e.date)
    release_date === nothing || (cff["date-released"] = string(release_date))

    if add_preferred
        preferred = deepcopy(cff)
        delete!(preferred, "cff-version")
        delete!(preferred, "message")

        start = split(e.in.pages, "--")
        preferred["start"] = na_if_empty(start[1])
        preferred["end"] = na_if_empty(length(start) == 2 ? start[2] : "")
        preferred["journal"] = na_if_empty(e.in.journal)
        preferred["issue"] = na_if_empty(e.in.number)
        preferred["volume"] = na_if_empty(e.in.volume)
        publisher = Dict{String, String}()
        publisher["name"] = na_if_empty(e.in.publisher)
        preferred["publisher"] = publisher
        preferred["type"] = get(BIB_TO_CFF_TYPES, e.type, "generic")

        cff["preferred-citation"] = preferred
    end

    YAML.write_file(destination, cff)

    return cff
end

function cff_parse_date(date::BibInternal.Date)
    parts = (date.year, date.month, date.day)
    any(isempty, parts) && return nothing
    try
        return Date(parse(Int, date.year), parse(Int, date.month), parse(Int, date.day))
    catch error
        error isa ArgumentError || rethrow()
        return nothing
    end
end

"""
    na_if_empty(str::AbstractString) -> AbstractString

Use placeholder value if string param is empty.
"""
function na_if_empty(str::AbstractString)
    isempty(str) ? "N/A" : str
end

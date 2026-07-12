const BibliographyDocument = BibInternal.BibliographyDocument
const LosslessEntry = BibInternal.LosslessEntry

"""
    read_bibliography(input; format = :auto, check = :error)

Read a bibliography from a path, stream, or string and return a lossless
`BibInternal.BibliographyDocument`.
"""
function read_bibliography(input; format::Symbol = :auto, check = :error)
    return BibParser.parse_bibliography(input; format, check)
end

"""
    bibliography_entries(bibliography)

Return an ordered dictionary of canonical entries keyed by entry id.
"""
function bibliography_entries(document::BibliographyDocument)
    entries = DataStructures.OrderedDict{String, Entry}()
    for entry in document.entries
        entries[entry.id] = BibInternal.canonical(entry)
    end
    return entries
end

bibliography_entries(bibliography::AbstractDict) = bibliography

function bibliography_entries(entries::AbstractVector{<:BibInternal.AbstractEntry})
    bibliography = DataStructures.OrderedDict{String, Entry}()
    for entry in entries
        canonical = BibInternal.canonical(entry)
        bibliography[canonical.id] = canonical
    end
    return bibliography
end

function _ruleset(format::Symbol)
    format == :BibLaTeX && return BibInternal.BIBLATEX_RULESET
    return BibInternal.BIBTEX_RULESET
end

"""
    validate(bibliography; ruleset)

Validate a bibliography document or collection of entries and return a
`BibInternal.ValidationResult`.
"""
function validate(document::BibliographyDocument; ruleset = _ruleset(document.format))
    return BibInternal.validate(document, ruleset)
end

function validate(bibliography::AbstractDict; ruleset = BibInternal.BIBTEX_RULESET)
    diagnostics = BibInternal.Diagnostic[]
    for entry in values(bibliography)
        append!(diagnostics,
            BibInternal.validate(BibInternal.canonical(entry), ruleset).diagnostics)
    end
    return BibInternal.ValidationResult(diagnostics)
end

"""
    write_bibliography([target], bibliography; format = :BibTeX, mode = :normalized)

Write or return a bibliography string. With `mode = :original` or
`mode = :preserved`, a lossless document returns its original source when
available. With `mode = :normalized`, entries are emitted from the canonical
view.
"""
function write_bibliography(
        bibliography; format::Symbol = :BibTeX, mode::Symbol = :normalized)
    if mode in (:original, :preserved) &&
       bibliography isa BibliographyDocument &&
       !isempty(bibliography.source)
        return bibliography.source
    end
    mode == :normalized ||
        throw(ArgumentError("Unsupported bibliography write mode: $mode"))
    return _write_normalized(Val(format), bibliography_entries(bibliography))
end

_write_normalized(::Val{:BibTeX}, bibliography) = export_bibtex(bibliography)
_write_normalized(::Val{:BibLaTeX}, bibliography) = export_biblatex(bibliography)
function _write_normalized(::Val{:CFF}, bibliography)
    YAML.write(cff_dict(only(values(bibliography))))
end
_write_normalized(::Val{:RIS}, bibliography) = export_ris(bibliography)

function _write_normalized(::Val{format}, bibliography) where {format}
    throw(ArgumentError("The $format writer extension is not loaded."))
end

function write_bibliography(target::AbstractString, bibliography; kwargs...)
    data = write_bibliography(bibliography; kwargs...)
    open(target, "w") do io
        write(io, data)
    end
    return data
end

"""
    filter_bibliography(bibliography, predicate)

Filter entries with `predicate(entry)`, preserving document metadata when the
input is a lossless document.
"""
function filter_bibliography(document::BibliographyDocument, predicate::Function)
    return BibliographyDocument(
        format = document.format,
        entries = [entry for entry in document.entries if predicate(entry)],
        blocks = document.blocks,
        diagnostics = document.diagnostics,
        source = document.source,
        metadata = document.metadata
    )
end

function filter_bibliography(bibliography::AbstractDict, predicate::Function)
    values_type = valtype(typeof(bibliography))
    filtered = DataStructures.OrderedDict{String, values_type}()
    for (key, entry) in bibliography
        predicate(entry) && (filtered[key] = entry)
    end
    return filtered
end

function filter_bibliography(predicate::Function, document::BibliographyDocument)
    filter_bibliography(document, predicate)
end

function filter_bibliography(predicate::Function, bibliography::AbstractDict)
    filter_bibliography(bibliography, predicate)
end

function select(
        document::BibliographyDocument,
        selection::AbstractVector{<:AbstractString};
        complementary::Bool = false
)
    selected = Set(String.(selection))
    return filter_bibliography(document, entry -> begin
        contains = entry.id in selected
        complementary ? !contains : contains
    end)
end

function sort_bibliography!(document::BibliographyDocument, sorting_rule::Symbol = :key)
    ordered = bibliography_entries(document)
    sort_bibliography!(ordered, sorting_rule)
    by_id = Dict(entry.id => entry for entry in document.entries)
    empty!(document.entries)
    append!(document.entries, [by_id[id] for id in keys(ordered)])
    return document
end

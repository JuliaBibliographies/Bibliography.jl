module BibliographyCSLExt

import Bibliography
import Bibliography: _write_normalized, export_csl
import JSON3

function _name(name)
    isempty(name.last) && return Dict("literal" => Bibliography.name_to_string(name))
    return Dict(
        "family" => name.last,
        "given" => join(filter(!isempty, [name.first, name.middle]), " "),
        "non-dropping-particle" => name.particle,
        "suffix" => name.junior
    )
end

function _item(entry)
    type = get(
        Dict(
            "article" => "article-journal", "incollection" => "chapter",
            "inproceedings" => "paper-conference", "techreport" => "report",
            "phdthesis" => "thesis", "mastersthesis" => "thesis"),
        entry.type,
        entry.type)
    parts = Any[]
    for value in (entry.date.year, entry.date.month, entry.date.day)
        isempty(value) && break
        parsed = tryparse(Int, value)
        push!(parts, isnothing(parsed) ? value : parsed)
    end
    return Dict(
        "id" => entry.id, "type" => type, "title" => entry.title,
        "author" => _name.(entry.authors), "editor" => _name.(entry.editors),
        "container-title" => isempty(entry.in.journal) ? entry.booktitle : entry.in.journal,
        "issued" => Dict("date-parts" => [parts]), "publisher" => entry.in.publisher,
        "publisher-place" => entry.in.address, "page" => entry.in.pages,
        "volume" => entry.in.volume, "issue" => entry.in.number,
        "DOI" => entry.access.doi, "URL" => entry.access.url,
        "ISBN" => entry.in.isbn, "ISSN" => entry.in.issn, "note" => entry.note
    )
end

function export_csl(bibliography::AbstractDict)
    JSON3.write([_item(e) for e in values(bibliography)])
end
Bibliography._write_normalized(::Val{:CSL}, bibliography) = export_csl(bibliography)

end

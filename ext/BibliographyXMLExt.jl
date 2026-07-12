module BibliographyXMLExt

import Bibliography
import Bibliography: _write_normalized, export_endnote, export_mods
import EzXML

function _xml(value)
    replace(string(value), '&' => "&amp;", '<' => "&lt;", '>' => "&gt;", '"' => "&quot;")
end

function _names(names)
    return join(("<author><style>$(_xml(Bibliography.name_to_string(n)))</style></author>"
    for n in names))
end

function _endnote_entry(entry)
    type = get(
        Dict("article" => "Journal Article", "book" => "Book",
            "incollection" => "Book Section", "inproceedings" => "Conference Paper",
            "techreport" => "Report", "phdthesis" => "Thesis", "misc" => "Web Page"),
        entry.type, entry.type)
    return """<record><rec-number>$(_xml(entry.id))</rec-number><ref-type>$type</ref-type>
    <contributors><authors>$(_names(entry.authors))</authors><secondary-authors>$(_names(entry.editors))</secondary-authors></contributors>
    <titles><title><style>$(_xml(entry.title))</style></title><secondary-title><style>$(_xml(isempty(entry.in.journal) ? entry.booktitle : entry.in.journal))</style></secondary-title></titles>
    <dates><year><style>$(_xml(entry.date.year))</style></year></dates><publisher><style>$(_xml(entry.in.publisher))</style></publisher>
    <volume><style>$(_xml(entry.in.volume))</style></volume><number><style>$(_xml(entry.in.number))</style></number><pages><style>$(_xml(entry.in.pages))</style></pages>
    <electronic-resource-num><style>$(_xml(entry.access.doi))</style></electronic-resource-num><urls><related-urls><url><style>$(_xml(entry.access.url))</style></url></related-urls></urls></record>"""
end

function export_endnote(bibliography::AbstractDict)
    "<xml><records>" * join((_endnote_entry(e) for e in values(bibliography))) *
    "</records></xml>"
end

function _mods_name(name)
    if isempty(name.first) && isempty(name.particle)
        return "<name type=\"corporate\"><namePart>$(_xml(name.last))</namePart></name>"
    end
    return "<name type=\"personal\"><namePart type=\"family\">$(_xml(name.last))</namePart><namePart type=\"given\">$(_xml(join(filter(!isempty, [name.first, name.middle]), " ")))</namePart></name>"
end

function _mods_entry(entry)
    genre = get(
        Dict("article" => "article", "book" => "book",
            "inproceedings" => "conference paper"),
        entry.type,
        entry.type)
    host = isempty(entry.in.journal) ? entry.booktitle : entry.in.journal
    return """<mods ID="$(_xml(entry.id))"><genre>$genre</genre><titleInfo><title>$(_xml(entry.title))</title></titleInfo>
    $(join(_mods_name.(entry.authors)))<relatedItem type="host"><titleInfo><title>$(_xml(host))</title></titleInfo></relatedItem>
    <originInfo><dateIssued>$(_xml(entry.date.year))</dateIssued><publisher>$(_xml(entry.in.publisher))</publisher><place><placeTerm>$(_xml(entry.in.address))</placeTerm></place></originInfo>
    <identifier type="local">$(_xml(entry.id))</identifier><location><url>$(_xml(entry.access.url))</url></location></mods>"""
end

function export_mods(bibliography::AbstractDict)
    "<modsCollection xmlns=\"http://www.loc.gov/mods/v3\">" *
    join((_mods_entry(e) for e in values(bibliography))) * "</modsCollection>"
end
Bibliography._write_normalized(::Val{:EndNote}, bibliography) = export_endnote(bibliography)
Bibliography._write_normalized(::Val{:MODS}, bibliography) = export_mods(bibliography)

end

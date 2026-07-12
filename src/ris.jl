const BIB_TO_RIS_TYPES = Dict(
    "article" => "JOUR",
    "book" => "BOOK",
    "booklet" => "GEN",
    "inbook" => "CHAP",
    "incollection" => "CHAP",
    "inproceedings" => "CPAPER",
    "mastersthesis" => "THES",
    "phdthesis" => "THES",
    "techreport" => "RPRT",
    "unpublished" => "UNPB"
)

function _ris_tag(tag, value)
    isempty(value) && return ""
    return join(("$tag  - $line\n" for line in split(string(value), '\n')))
end

function export_ris(entry::Entry)
    data = _ris_tag("TY", get(BIB_TO_RIS_TYPES, entry.type, "GEN"))
    data *= _ris_tag("ID", entry.id)
    data *= join((_ris_tag("AU", name_to_string(name)) for name in entry.authors))
    data *= join((_ris_tag("ED", name_to_string(name)) for name in entry.editors))
    data *= _ris_tag("TI", entry.title)
    data *= _ris_tag("T2", entry.booktitle)
    data *= _ris_tag("JO", entry.in.journal)
    date = join(filter(!isempty, [entry.date.year, entry.date.month, entry.date.day]), "/")
    data *= _ris_tag("PY", date)
    data *= _ris_tag("VL", entry.in.volume)
    data *= _ris_tag("IS", entry.in.number)
    pages = split(entry.in.pages, r"--?"; limit = 2)
    !isempty(pages) && (data *= _ris_tag("SP", first(pages)))
    length(pages) == 2 && (data *= _ris_tag("EP", last(pages)))
    data *= _ris_tag("PB", entry.in.publisher)
    data *= _ris_tag("DO", entry.access.doi)
    data *= _ris_tag("UR", entry.access.url)
    data *= _ris_tag("N1", entry.note)
    return data * "ER  -\n"
end

export_ris(bibliography) = join((export_ris(entry) for entry in values(bibliography)), "\n")

"""
    import_bibtex(input; check = :none)
Import a BibTeX file or parse a BibTeX string and convert it to the internal bibliography format.
The `check` keyword argument can be set to `:none` (or `nothing`), `:warn`, or `:error` to raise appropriate logs.
"""
function import_bibtex(input::AbstractString; check = :none)
    source = String(input)
    (occursin('\n', source) || occursin('\r', source)) &&
        return BibParser.BibTeX.parse_string(source; check)
    try
        return isfile(source) ? BibParser.BibTeX.parse_file(source; check) :
               BibParser.BibTeX.parse_string(source; check)
    catch error
        if error isa Base.IOError
            return BibParser.BibTeX.parse_string(source; check)
        end
        rethrow()
    end
end

function import_bibtex(input; check = :none)
    return isfile(input) ? BibParser.BibTeX.parse_file(input; check) :
           BibParser.BibTeX.parse_string(input; check)
end

"""
    int_to_spaces(n)

Make a string of `n` spaces.
"""
int_to_spaces(n) = repeat(" ", n)

const spaces = Dict{String, String}(
    map(s -> (string(s) => int_to_spaces(BibInternal.space(s))), BibInternal.fields)
)

"""
    field_to_bibtex(key, value)

Convert an entry field to BibTeX format.
"""
function field_to_bibtex(key, value)
    isempty(value) && return ""
    space = get(spaces, key) do
        int_to_spaces(BibInternal.space(Symbol(key)))
    end
    o, f = occursin('@', value) ? ('"', '"') : ('{', '}')
    return " $key$space = $o$value$f,\n"
end

"""
    name_to_string(name::BibInternal.Name)

Convert a name in an `Entry` to a string.
"""
function name_to_string(name)
    str = "$(name.particle)"
    if str != "" != name.last
        str *= " "
    end
    str *= name.last
    str *= name.junior == "" ? "" : ", $(name.junior)"
    if name.first != ""
        str *= ", $(name.first)"
    end
    if name.middle != ""
        str *= " $(name.middle)"
    end
    return str
end

"""
    names_to_strings(names)

Convert a collection of names to a BibTeX string.
"""
function names_to_strings(names)
    return join((name_to_string(name) for name in names), " and ")
end

"""
    access_to_bibtex!(fields, a)

Transform the how-to-`access` field to a BibTeX string.
"""
function access_to_bibtex!(fields, a)
    fields["doi"] = a.doi
    fields["howpublished"] = a.howpublished
    return fields["url"] = a.url
end

"""
    date_to_bibtex!(fields, date)

Convert a date to a BibTeX string.
"""
function date_to_bibtex!(fields, date)
    fields["day"] = date.day
    fields["month"] = date.month
    return fields["year"] = date.year
end

"""
    eprint_to_bibtex!(fields, eprint)

Convert eprint information to a BibTeX string.
"""
function eprint_to_bibtex!(fields, ep)
    fields["archivePrefix"] = ep.archive_prefix
    fields["eprint"] = ep.eprint
    return fields["primaryClass"] = ep.primary_class
end

"""
    in_to_bibtex!(fields::BibInternal.Fields, i::BibInternal.In)

Convert the "published `in`" information to a BibTeX string.
"""
function in_to_bibtex!(fields, in_)
    fields["address"] = in_.address
    fields["chapter"] = in_.chapter
    fields["edition"] = in_.edition
    fields["institution"] = in_.institution
    fields["isbn"] = in_.isbn
    fields["issn"] = in_.issn
    fields["journal"] = in_.journal
    fields["number"] = in_.number
    fields["organization"] = in_.organization
    fields["pages"] = in_.pages
    fields["publisher"] = in_.publisher
    fields["school"] = in_.school
    fields["series"] = in_.series
    return fields["volume"] = in_.volume
end

"""
    export_bibtex(e::Entry)

Export an `Entry` to a BibTeX string.
"""
function _write_bibtex(io::IO, e::Entry)
    fields = copy(e.fields)
    sizehint!(fields, length(e.fields) + 32)
    access_to_bibtex!(fields, e.access)
    fields["author"] = names_to_strings(e.authors)
    fields["booktitle"] = e.booktitle
    date_to_bibtex!(fields, e.date)
    fields["editor"] = names_to_strings(e.editors)
    eprint_to_bibtex!(fields, e.eprint)
    in_to_bibtex!(fields, e.in)
    fields["note"] = e.note
    fields["title"] = e.title

    print(io, '@', e.type == "eprint" ? "misc" : e.type, '{', e.id)
    for (name, value) in fields
        isempty(value) && continue
        print(io, ",\n")
        space = get(spaces, name) do
            int_to_spaces(BibInternal.space(Symbol(name)))
        end
        open_char, close_char = occursin('@', value) ? ('"', '"') : ('{', '}')
        print(io, ' ', name, space, " = ", open_char, value, close_char)
    end
    print(io, "\n}")
    return io
end

function export_bibtex(e::Entry)
    io = IOBuffer()
    _write_bibtex(io, e)
    return String(take!(io))
end

function export_biblatex(e::Entry)
    fields = copy(e.fields)
    fields["author"] = names_to_strings(e.authors)
    fields["editor"] = names_to_strings(e.editors)
    fields["title"] = e.title
    fields["booktitle"] = e.booktitle
    fields["date"] = join(filter(!isempty, [e.date.year, e.date.month, e.date.day]), "-")
    fields["journaltitle"] = e.in.journal
    fields["location"] = e.in.address
    fields["publisher"] = e.in.publisher
    fields["institution"] = e.in.institution
    fields["pages"] = e.in.pages
    fields["volume"] = e.in.volume
    fields["number"] = e.in.number
    fields["doi"] = e.access.doi
    fields["url"] = e.access.url
    fields["eprint"] = e.eprint.eprint
    fields["eprinttype"] = e.eprint.archive_prefix
    fields["eprintclass"] = e.eprint.primary_class
    fields["note"] = e.note
    foreach(key -> delete!(fields, key), ("day", "month", "year", "journal", "address"))
    body = join((field_to_bibtex(name, value)
    for (name, value) in fields if !isempty(value)))
    isempty(body) && return "@$(e.type){$(e.id)}"
    return "@$(e.type){$(e.id),\n" * body[1:(end - 2)] * "\n}"
end

"""
    export_bibtex(bibliography)

Export a bibliography to a BibTeX string.
"""
function export_bibtex(bibliography)
    io = IOBuffer()
    first_entry = true
    for entry in values(bibliography)
        first_entry || print(io, "\n\n")
        _write_bibtex(io, entry)
        first_entry = false
    end
    first_entry || write(io, '\n')
    return String(take!(io))
end

"""
    export_biblatex(bibliography)

Export a bibliography to BibLaTeX format.
"""
function export_biblatex(bibliography)
    return join((export_biblatex(entry) for entry in values(bibliography)), "\n\n")
end

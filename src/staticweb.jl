const type_to_label = Dict{String, String}([
    "article" => "journal",
    "book" => "book",
    "booklet" => "booklet",
    "eprint" => "eprint",
    "inbook" => "book chapter",
    "incollection" => "book section",
    "inproceedings" => "conference",
    "manual" => "manual",
    "mastersthesis" => "master's thesis",
    "misc" => "other",
    "phdthesis" => "doctoral thesis",
    "proceedings" => "proceedings",
    "techreport" => "report",
    "unpublished" => "other"
])

"""
    xtitle(entry

Format the title of an `Entry` for web export.
"""
function xtitle(entry)
    return isdefined(entry, :title) ? entry.title : get(entry.fields, "title", "")
end

"""
    xnames(entry, editors = false; names = :full)

Format the name of an `Entry` for web export.

# Arguments:
- `entry`: an entry
- `editors`: `true` if the name describes editors
- `names`: :full (full names) or :last (last names + first name abbreviation)
"""
function xnames(
        entry,
        editors = false;
        names = :full # Current options: :last, :full
)
    # forces the names to be editors' name if the entry are Proceedings
    if !editors && entry.type ∈ ["proceedings"]
        return xnames(entry, true)
    end
    entry_names = editors ? entry.editors : entry.authors

    if names == :last
        parts = map(s -> [s.particle, s.last, s.junior], entry_names)
    else
        parts = map(s -> [s.first, s.middle, s.particle, s.last, s.junior], entry_names)
    end

    entry_names = map(parts) do s
        return join(filter(!isempty, s), " ")
    end
    str = join(entry_names, ", ")
    return replace(str, r"[\n\r ]+" => " ") # TODO: make it cleaner (is replace still necessary)
end

"""
    xin(entry)

Format the appears-`in` field of an `Entry` for web export.
"""
function xin(entry)
    str = ""
    temp_last = false
    temp = []
    if entry.type == "article"
        temp = [
            entry.in.journal,
            entry.in.volume * (entry.in.number != "" ? "($(entry.in.number))" : ""),
            entry.in.pages,
            entry.date.year
        ]
    elseif entry.type == "book"
        temp = [entry.in.publisher, entry.in.address, entry.date.year]
    elseif entry.type == "booklet"
        temp = [entry.access.howpublished, entry.date.year]
    elseif entry.type == "eprint"
        if isempty(entry.eprint.archive_prefix)
            str *= entry.eprint.eprint
        else
            str *= "$(entry.eprint.archive_prefix):$(entry.eprint.eprint) [$(entry.eprint.primary_class)]"
        end
    elseif entry.type == "inbook"
        temp = [
            entry.booktitle,
            isempty(entry.in.chapter) ? entry.in.pages : entry.in.chapter,
            entry.in.publisher,
            entry.in.address
        ]
    elseif entry.type == "incollection"
        # TODO: check if this new or the old format is/was correct, that "editors" seems out of place (and the title was switched with the names)?
        temp = [
            "In $(entry.booktitle)",
            "editors",
            xnames(entry, true),
            entry.in.pages * ". " * entry.in.publisher, # TODO: conditional ". " if one of the strings is empty?
            entry.in.address,
            entry.date.year
        ]
    elseif entry.type == "inproceedings"
        temp_last = entry.in.publisher != ""
        temp = [
            " In " * entry.booktitle,
            entry.in.series,
            entry.in.pages,
            entry.in.address,
            entry.date.year,
            entry.in.publisher
        ]
    elseif entry.type == "manual"
        temp = [entry.in.organization, entry.in.address, entry.date.year]
    elseif entry.type ∈ ["mastersthesis", "phdthesis"]
        temp = [
            (entry.type == "mastersthesis" ? "Master's" : "PhD") * " thesis",
            entry.in.school,
            entry.in.address,
            entry.date.year
        ]
    elseif entry.type == "misc"
        temp_last = get(entry.fields, "note", "") != "" &&
                    entry.access.howpublished != "" &&
                    entry.date.year != ""
        temp = [entry.access.howpublished
                entry.date.year
                get(entry.fields, "note", "")]
    elseif entry.type == "proceedings"
        temp_last = entry.in.publisher != ""
        temp = [
            (entry.in.volume != "" ? "Volume $(entry.in.volume) of " : "") *
            entry.in.series,
            entry.in.address,
            entry.date.year,
            entry.in.publisher
        ]
        # TODO: check if this old line here was a hidden bug
        # str *= entry.in.publisher != "" ? ". $(entry.in.address)" : ""
    elseif entry.type == "techreport"
        temp = [
            entry.in.number != "" ? "Technical Report $(entry.in.number)" : "",
            entry.in.institution,
            entry.in.address,
            entry.date.year
        ]
    elseif entry.type == "unpublished"
        temp = [get(entry.fields, "note", ""), entry.date.year]
    end
    if temp_last
        str *= something(join(filter!(!isempty, temp), ", ", ". "), "")
    else
        str *= something(join(filter!(!isempty, temp), ", "), "")
    end
    if !isempty(str)
        str *= "."
    end
    return str
end

"""
    xyear(entry)

Format the year of an `Entry` for web export.
"""
xyear(entry) = entry.date.year

"""
    xlink(entry)

Format the download link of an `Entry` for web export.
"""
function xlink(entry)
    if entry.access.doi != ""
        return "https://doi.org/" * entry.access.doi
    elseif entry.access.url != ""
        return entry.access.url
    end
    return ""
end

"""
    xfile(entry)

Format the downloadable path of an `Entry` file for web export.
"""
xfile(entry) = "files/$(entry.id).pdf"

"""
    xcite(entry)

Format the BibTeX cite output of an `Entry` for web export.
"""
xcite(entry) = string(entry)

"""
    xlabels(entry)

Format the labels of an `Entry` for web export.
"""
function xlabels(entry)
    str = get(entry.fields, "swp-labels", "")
    if isempty(str)
        str = get(entry.fields, "labels", "")
    end
    if isempty(str)
        return [entry.type]
    end
    return split(str, r"[\n\r ]*,[\n\r ]*")
end

"""
    Publication

A structure to store all the information necessary for web export.
"""
struct Publication
    id::String
    type::String
    title::String
    names::String
    in::String
    year::String
    link::String
    file::String
    cite::String
    abstract::String
    labels::Vector{String}
end

"""
    Publication(entry)

Construct a `Publication` compatible with the StaticWebPages web export.
"""
function Publication(entry)
    id = entry.id
    type = entry.type
    title = entry.title
    names = xnames(entry)
    in_ = xin(entry)
    year = xyear(entry)
    link = xlink(entry)
    file = xfile(entry)
    cite = export_bibtex(entry)
    abstract = get(entry.fields, "abstract", "")
    labels = xlabels(entry)
    return Publication(
        id, type, title, names, in_, year, link, file, cite, abstract, labels)
end

"""
    export_web(bibliography::DataStructures.OrderedDict{String,BibInternal.Entry})

Export a bibliography in internal format to the web format used by
`StaticWebPages.jl`. The same representation is also used by
`DocumenterCitations.jl`.
"""
function export_web(bibliography)
    entries = Vector{Publication}()
    for entry in values(bibliography)
        p = Publication(entry)
        push!(entries, p)
    end
    return entries
end

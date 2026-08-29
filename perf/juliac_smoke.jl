using Bibliography

const SAMPLE_BIBTEX = """
@article{lovelace2026,
  title = {A reusable performance contract},
  author = {Ada Lovelace},
  journal = {Julia Studies},
  year = {2026}
}
"""

function @main(args::Vector{String})::Cint
    input = isempty(args) ? SAMPLE_BIBTEX : read(only(args), String)
    document = Bibliography.read_bibliography(input, Val(:BibTeX); check = :none)
    output = Bibliography.write_bibliography(
        document, Val(:BibTeX); mode = :normalized)
    occursin("lovelace2026", output) || return 2
    println(Core.stdout, length(document.entries))
    return 0
end

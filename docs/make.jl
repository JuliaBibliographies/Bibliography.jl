using Documenter, Bibliography, BibParser, BibInternal

makedocs(
    sitename = "Bibliography.jl",
    authors = "Jean-François BAFFIER",
    format = Documenter.HTML(
        prettyurls = true,
        canonical = "https://juliabibliographies.github.io/Bibliography.jl",
        edit_link = "master"
    ),
    pages = [
        "Bibliography" => "index.md",
        # "BibTeX" => "bibtex.md",
        # "BibTeX - automa" => "bibtex_automa.md",
        # "CSL-JSON" => "csl.md",
        "BibInternal" => "internal.md",
        "BibParser" => "parser.md"
    ]
)

deploydocs(;
    repo = "github.com/JuliaBibliographies/Bibliography.jl.git", devbranch = "master")

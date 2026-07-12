Bibliography is the orchestration layer of the bibliography stack.

Use it when you want a simple API for common operations:

- import a bibliography from BibTeX, BibLaTeX, RIS, CFF, CSL-JSON, EndNote, or
  MODS;
- validate or filter a bibliography document;
- sort entries;
- export to BibTeX, BibLaTeX, RIS, CFF, CSL-JSON, or the StaticWebPages web
  format.

```julia
using Bibliography

bib = read_bibliography("references.bib")
validate(bib)
selected = select(bib, ["lovelace1843"])
write_bibliography("references.out.bib", selected)
```

```@contents
```

```@autodocs
Modules = [Bibliography]
```

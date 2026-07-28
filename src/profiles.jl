const _CANONICAL_FIELDS = Set(keys(BibInternal.CANONICAL_FIELD_SPECS))

function _exchange_profile(
        name::Symbol;
        rules = BibInternal.AbstractBibliographyRule[]
)
    BibInternal.RuleProfile(
        name = name,
        version = v"1.0.0",
        global_rules = rules,
        global_fields = _CANONICAL_FIELDS
    )
end

const _FORMAT_RULE_PROFILES = Dict{Symbol, BibInternal.RuleProfile}(
    :BibTeX => BibInternal.BIBTEX_PROFILE,
    :BibLaTeX => BibInternal.BIBLATEX_PROFILE,
    :CSL => _exchange_profile(:CSL),
    :RIS => _exchange_profile(:RIS),
    :EndNote => _exchange_profile(:EndNote),
    :MODS => _exchange_profile(:MODS),
    :CFF => _exchange_profile(
        :CFF;
        rules = BibInternal.AbstractBibliographyRule[
            BibInternal.RequiredField("author"),
            BibInternal.RequiredField("title")
        ]
    ),
    :Web => _exchange_profile(:Web)
)

"""
    rule_profile(format)

Return the canonical validation profile associated with a supported
bibliography format. Exchange-format profiles deliberately validate the
canonical input required by the current exporter; source schema validation
remains the parser's responsibility.
"""
function rule_profile(format::Symbol)
    haskey(_FORMAT_RULE_PROFILES, format) ||
        throw(ArgumentError("No bibliography rule profile for format $format"))
    return _FORMAT_RULE_PROFILES[format]
end

function _composed_profile_name(format::Symbol, overlays)
    names = String[string(format)]
    append!(names, string.(getproperty.(overlays, :name)))
    return Symbol(join(names, "__"))
end

"""
    compose_rule_profiles(format, overlays...; name)

Compose a destination format profile with product, project, or institution
overlays.
"""
function compose_rule_profiles(
        format::Symbol,
        overlays::BibInternal.RuleProfile...;
        name::Symbol = _composed_profile_name(format, overlays)
)
    BibInternal.compose_profiles(rule_profile(format), overlays...; name)
end

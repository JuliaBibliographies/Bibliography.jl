"""
    select(
        bibliography::DataStructures.OrderedDict{String,Entry},
        selection::Vector{String};
        complementary::Bool = false
        )

Select a subset of bibliography entries by key.

If `complementary` is `true`, the keys in `selection` are excluded instead of
kept.
"""
function select(
        bibliography::DataStructures.OrderedDict{String, Entry},
        selection::Vector{String};
        complementary::Bool = false
)
    selected_bib = DataStructures.OrderedDict{String, Entry}()
    old_keys = keys(bibliography)
    new_keys = complementary ? setdiff(old_keys, selection) : intersect(old_keys, selection)

    for key in new_keys
        selected_bib[key] = bibliography[key]
    end

    return selected_bib
end

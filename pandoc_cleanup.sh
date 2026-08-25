source="Mainmatter/Pandoc Conversions/Adaptive Probabilistic Shielding by Learning MDPs for Safe Reinforcement Learning.typ"
target="Mainmatter/Adaptive Probabilistic Shielding by Learning MDPs for Safe Reinforcement Learning.typ"

# preamble
echo "#import \"../Config/Macros.typ\" : *">"$target"
echo "" >>"$target"

# replacements
sed -r "$source" \
    -e 's|"graphics/|"../Graphics/RV26/|g' \
    -e 's| sect | inter |g' \
    -e 's|([0-9])\\linewidth|\1*100%|g' \
    -e 's|([0-9])\\textwidth|\1*100%|g' \
    -e 's|\\linewidth|100%|g' \
    -e 's|\\textwidth|100%|g' \
    -e 's|#cite| #cl|g' \
    -e 's|[A-Za-z.]+ #link\(<(.*)>\)\[\d+\]|@\1|g' \
    -e 's|[A-Za-z.]+ #link\(<(.*)>\)\[\\\[.+\\\]\]|@\1|g' \
    >> "$target"
# [A-Z][a-z]+ #link\(\<(.*)\>\)\[\\\[.*\\\]\]
# @(DBLP:[^ ]+)
# #label("$1")
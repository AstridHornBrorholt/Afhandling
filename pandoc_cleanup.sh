sed -r "Mainmatter/Pandoc Conversions/Uppaal Coshy: Automatic Synthesis of Compact Shields for Hybrid Systems.typ" \
    -e 's|"Graphics/|"../Graphics/RP25/|g' \
    -e 's| sect | inter |g' \
    -e 's|([0-9])\\linewidth|\1*100%|g' \
    -e 's|([0-9])\\textwidth|\1*100%|g' \
    -e 's|\\linewidth|100%|g' \
    -e 's|\\textwidth|100%|g' \
    -e 's| ?#cite\((".*"), (".*"), (".*"), (".*"), (".*")\)| #cite(label(\1)) #cite(label(\2)) #cite(label(\3)) #cite(label(\4)) #cite(label(\5))|g' \
    -e 's| ?#cite\((".*"), (".*"), (".*"), (".*")\)| #cite(label(\1)) #cite(label(\2)) #cite(label(\3)) #cite(label(\4))|g' \
    -e 's| ?#cite\((".*"), (".*"), (".*")\)| #cite(label(\1)) #cite(label(\2)) #cite(label(\3))|g' \
    -e 's| ?#cite\((".*"), (".*")\)| #cite(label(\1)) #cite(label(\2))|g' \
    -e 's| ?#cite\((".*")\)| #cite(label(\1))|g' \
    -e 's|[A-Za-z.]+ #link\(<(.*)>\)\[\d+\]|@\1|g' \
    -e 's|[A-Za-z.]+ #link\(<(.*)>\)\[\\\[.+\\\]\]|@\1|g' \
    > "Mainmatter/Uppaal Coshy: Automatic Synthesis of Compact Shields for Hybrid Systems.typ"
# [A-Z][a-z]+ #link\(\<(.*)\>\)\[\\\[.*\\\]\]
# @(DBLP:[^ ]+)
# #label("$1")
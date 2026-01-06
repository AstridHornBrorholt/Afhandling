sed -r "Mainmatter/Pandoc Conversions/Shielded Reinforcement Learning for Hybrid Systems.typ"\
    -e 's|"graphics/|"../Graphics/|g' \
    -e 's|([0-9])\\linewidth|\1*100%|g' \
    -e 's|([0-9])\\textwidth|\1*100%|g' \
    -e 's|\\linewidth|100%|g' \
    -e 's|\\textwidth|100%|g' \
    -e 's| ?#cite\((".*"), (".*"), (".*")\)| #cite(label(\1)) #cite(label(\2)) #cite(label(\3))|g' \
    -e 's| ?#cite\((".*"), (".*")\)| #cite(label(\1)) #cite(label(\2))|g' \
    -e 's| ?#cite\((".*")\)| #cite(label(\1))|g' \
    -e 's|Section #link\(<(.*)>\)\[[0-9]+\]|@\1|g' \
    -e 's|Fig\. #link\(<(.*)>\)\[\\\[.*\\\]\]|@\1|g' \
    -e 's|Fig\. #link\(<(.*)>\)\[[0-9]+\](\(\w\))?|@\1|g' \
    > "Mainmatter/Shielded Reinforcement Learning for Hybrid Systems.typ"
# [A-Z][a-z]+ #link\(\<(.*)\>\)\[\\\[.*\\\]\]
# @(DBLP:[^ ]+)
# #label("$1")
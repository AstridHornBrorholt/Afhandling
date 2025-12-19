#import "Config/Styles.typ": apply_style

// /* Regexes
// #cite\("(.*)", "(.*)", "(.*)"\)
// #cite\("(.*)", "(.*)""\)
// #cite\("(.*)""\)
// Section #link\(<(.*)>\)\[\d+\]
// Fig\. #link\(<(.*)>\)\[\\\[.*\\\]\]
// Fig\. #link\(<(.*)>\)\[\d+\](\(\w\))?
// [A-Z][a-z]+ #link\(<(.*)>\)\[\\\[.*\\\]\]
// @(DBLP:[^ ]+)
//    #label("$1")

#show: apply_style

#set document(
    title: "PhD Thesis",  // TODO: Change
    author: "Astrid Horn Brorholt",
)

#include "Frontmatter/Title Page.typ"
#pagebreak(weak: true)
#include "Frontmatter/Colophon.typ"
#pagebreak(weak: true)
#include "Frontmatter/CV.typ"
#pagebreak(weak: true)
#include "Frontmatter/Abstract.typ"
#pagebreak(weak: true)
#include "Frontmatter/Dansk Abstract.typ"
#pagebreak(weak: true)

#outline(title: "Table of Contents")
#pagebreak(weak: true)

#include "Mainmatter/Introduction.typ"
#pagebreak(to: "odd", weak: true)

#include "Mainmatter/Shielded Reinforcement Learning for Hybrid Systems.typ"
#pagebreak(to: "odd", weak: true)
#include "Mainmatter/Efficient Shield Synthesis via State-space Transformation.typ"
#pagebreak(to: "odd", weak: true)
#include "Mainmatter/Compositional Shielding and Reinforcement Learning for Multi-agent Systems.typ"
#pagebreak(to: "odd", weak: true)
#include "Mainmatter/Uppaal Coshy: Automatic Synthesis of Compact Shields for Hybrid Systems.typ"
#pagebreak(to: "odd", weak: true)

#bibliography("Bibliography.bib")
#import "Config/Styles.typ": apply_style

#show: apply_style
#set page(numbering: none)
#align(center)[_This page is intentionally left blank_]
#pagebreak(to: "even")
#include "Frontmatter/Title Page.typ"
#pagebreak(weak: true)
#counter(page).update(1)
#set page(numbering: "i")
#include "Frontmatter/Colophon.typ"
#pagebreak(to: "even", weak: true)
// #include "Frontmatter/CV.typ"
// #pagebreak(weak: true)
#include "Frontmatter/Abstract.typ"
#pagebreak(weak: true)
#include "Frontmatter/Dansk Abstract.typ"
#pagebreak(weak: true)

#outline(title: "Table of Contents", depth: 3)

#pagebreak(weak: true)
#counter(page).update(1)
#set page(numbering: "1")
#pagebreak(to: "even")
#include "Mainmatter/Introduction.typ"
#pagebreak(to: "even", weak: true)

#include "Mainmatter/Shielded Reinforcement Learning for Hybrid Systems.typ"
#pagebreak(to: "even", weak: true)
#include "Mainmatter/Efficient Shield Synthesis via State-space Transformation.typ"
#pagebreak(to: "even", weak: true)
#include "Mainmatter/Uppaal Coshy: Automatic Synthesis of Compact Shields for Hybrid Systems.typ"
#pagebreak(to: "even", weak: true)
#include "Mainmatter/Compositional Shielding and Reinforcement Learning for Multi-agent Systems.typ"
#pagebreak(to: "even", weak: true)
#include "Mainmatter/Adaptive Probabilistic Shielding by Learning MDPs for Safe Reinforcement Learning.typ"
#pagebreak(to: "even", weak: true)
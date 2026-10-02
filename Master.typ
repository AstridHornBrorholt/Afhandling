#import "Config/Styles.typ": apply_style
#import "Config/Macros.typ": add-period, skip-linebreak
#import "@preview/hydra:0.6.3": hydra

#show: apply_style
#set page(numbering: none)
#include "Frontmatter/Title Page.typ"
#pagebreak(weak: true)
#counter(page).update(1)
#set page(numbering: "i")
#include "Frontmatter/Colophon.typ"
#pagebreak(weak: true)
#include "Frontmatter/Acknowledgements.typ"
#pagebreak(weak: true)
#include "Frontmatter/Abstract.typ"
#pagebreak(weak: true)
#include "Frontmatter/Dansk Abstract.typ"
#pagebreak(weak: true)

#outline(title: "Table of Contents", depth: 3)

#set page(
  header: context {
    if calc.odd(here().page()) {
      align(center, emph(hydra(1, skip-starting: false, display: skip-linebreak)))
    } else {
      align(center, emph(hydra(2, skip-starting: false, display: add-period)))
    }
  }
)

#pagebreak(to: "odd", weak: true)
#counter(page).update(1)
#set page(numbering: "1")

#include "Mainmatter/Introduction.typ"
#heading("", outlined: false, numbering: none)  // Removes header from these pagebreaks
#pagebreak(to: "odd", weak: true)
#include "Mainmatter/Shielded Reinforcement Learning for Hybrid Systems.typ"
#heading("", outlined: false, numbering: none)  // Removes header from these pagebreaks
#pagebreak(to: "odd", weak: true)
#include "Mainmatter/Efficient Shield Synthesis via State-space Transformation.typ"
#heading("", outlined: false, numbering: none)  // Removes header from these pagebreaks
#pagebreak(to: "odd", weak: true)
#include "Mainmatter/Uppaal Coshy: Automatic Synthesis of Compact Shields for Hybrid Systems.typ"
#heading("", outlined: false, numbering: none)  // Removes header from these pagebreaks
#pagebreak(to: "odd", weak: true)
#include "Mainmatter/Compositional Shielding and Reinforcement Learning for Multi-agent Systems.typ"
#heading("", outlined: false, numbering: none)  // Removes header from these pagebreaks
#pagebreak(to: "odd", weak: true)
#heading("", outlined: false, numbering: none)  // Removes header from these pagebreaks
#include "Mainmatter/Adaptive Probabilistic Shielding by Learning MDPs for Safe Reinforcement Learning.typ"
#import "../Config/Macros.typ": *
#import "../Config/Styles.typ": *

#show: apply_style
#set page(numbering: "I")

#let (
  theorem, lemma, corollary,
  remark, proposition, example,
  proof, definition, rules: thm-rules
) = default-theorems("thm-group", lang: "en", thm-numbering: thm-numbering-linear)

= Style & Macro Showcase
(Top-level headings represent papers by default.)

This document demonstrates the custom styles and macros. \ #lorem(50)

== Text Styles

Normal text.

Inline code: `let x = 42`

Emoji test 😊 💥 🤖 ☺ ☹

Footnote test.#footnote[Test footnote.]

== Headings (Level 2)
#lorem(10)

=== Level 3
#lorem(10)

==== Level 4
#lorem(10)

===== Level 5
#lorem(10)

== Info Boxes

#infobox(
  [This is content inside an infobox. It is only used in one of the papers.],
  name: [Infobox  title]
)

== Contribution boxes

#contribution[
A concise description of a contribution.
]

#contribution(papers: "Papers A & B")[
A contribution linked to specific papers.
]

== Hypothesis box

#hypothesis[
There is only ever going to be one of these, but it seems common to use a bespoke graphical element.
]

== Shorthand Macros

$shield hatshield tildeshield mdp mg emdp ls powerset(X) argmax_(x in X) arg fehu$

#prism, #uppaal, #uppaalsmc, #uppaalstratego, #stratego, #uppaalcoshy, #caap, #coshy, 

$1st, 2nd, 3rd, 4th, 1^st, 2^nd, 3^rd, 4^th$ 

$ pi models_(>=θ) phi and pi' modelsnot_(>=θ) phi$


== Math-boxes


#theorem(name: "Theorem example")[
  This is a theorem. With an equation

  $ a^2 + b^2 = c^2 $

  And some more text.
]

#proof[
  And proofs go nicely after theorems. 
  
  #lorem(20)
]

#lemma[A lemma as well]

Some more text to break up the boxes: 
#lorem(20)

#definition(name: "Definition example")[
  This is a definition. With an equation

  $ sqrt(-1) = i $

  And some more text.
]

#example(name: "Example example")[
  This is an example \ #lorem(20)
]

#lorem(30)

#remark(name: "A remark")[
  #lorem(20)
]


== Editorial Markup

(None of this will appear in the final version.)

#todo[Todos are presented like this. \ #lorem(20)]

#question[Should this be moved to another paper? \ #lorem(20)]

#new[
This section presents entirely new material. \ #lorem(50)
]

#updated[
This section has been revised since the previous draft. \ #lorem(50)
]

Citation missing #citationneeded[]

Citation missing with note #citationneeded[Source?]

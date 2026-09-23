#import "../Config/Macros.typ": *
#import "../Config/Styles.typ": *

#show: apply_style
#set page(numbering: "I")

#let (
  theorem, lemma, corollary,
  remark, proposition, example,
  proof, definition, rules: thm-rules
) = default-theorems("thm-group", lang: "en", thm-numbering: thm-numbering-linear)

This document demonstrates the custom styles and macros. Emoji test: ☺️ 🤖 🌏

== Boxes

#contribution[
A concise description of a contribution.
]

#contribution(papers: "Papers A & B")[
A contribution linked to specific papers.
]

#hypothesis[
There is only ever going to be one of these, but it seems common to use a bespoke graphical element.
]

#theorem(name: "Theorem example")[
  This is a theorem. With an equation

  $ a^2 + b^2 = c^2 $

  And some more text.
]

#proof[
  And proofs go nicely after theorems. 
]

#lemma[A lemma as well]

#definition(name: "Definition example")[
  This is a definition. With an equation

  $ sqrt(-1) = i $

  And some more text.
]

#example(name: "Example example")[
  This is an example \ #lorem(20)
]


#remark(name: "A remark")[
  #lorem(20)
]

== UPPAAL Highlighting

#[
  #set par(justify: false)

  #set table(
    fill: (_, y) => {
      if y == 5 {
         cmyk(6%, 0%, 0%, 6%)
      } else {
        (none, cmyk(0%, 0%, 0%, 4%)).at(calc.rem(y, 2))
      }
    }
  )


  #show regex("acontrol"): set text(fill: emerald.darken(30%), weight: "bold")
  #show regex("minE"): set text(fill: nephritis.darken(30%), weight: "bold")
  #show regex("saveStrategy"): set text(fill: nephritis.darken(30%), weight: "bold")
  #show regex("loadStrategy"): set text(fill: nephritis.darken(30%), weight: "bold")
  #show regex("simulate"): set text(fill: nephritis.darken(30%), weight: "bold")
  #show regex("Pr"): set text(fill: nephritis.darken(30%), weight: "bold")
  #show regex("E"): set text(fill: nephritis.darken(30%), weight: "bold")
  #show regex("strategy"): set text(fill: nephritis.darken(30%))
  #show regex("under"): set text(fill: nephritis.darken(30%))
  #show regex("max:"): set text(fill: nephritis.darken(30%))
  #show regex("\".*\""): set text(fill: carrot.darken(30%))
  #show regex("\d+"): set text(fill: black.darken(30%))
  
  

  #figure(
    table(
      columns: 3,
      align: (col, row) => (right,left,left,).at(col),
      inset: 6pt,
      table.header([#strong[\#]], [#strong[Query]], [#strong[Result]]),
      [1], [```
      strategy efficient 
        = minE(c) [<=120] {} -> {v, p} : <> time>=120
      ```], [$checkmark$],

      [2], [``` simulate [<=120]{ p, v } under efficient```], [$checkmark$],
      [3], [``` E[<=120;100] (max: c) under efficient```], [$approx 0$],
      [4], [``` Pr[<=120;10000] (<> Ball.Stop) under efficient```], [$lr([0.9995 semi 1])$],

      [5], [``` 
      strategy shield = acontrol: A[] !Ball.Stop 
        { v[-13, 13]:1300, p[0, 11]:550, Ball.location }
      ```], [$checkmark$],

      [6], [``` saveStrategy("shield.json", shield)```], [$checkmark$],
    ),
    caption: [Queries run on the #emph[bouncing ball] model. New query
      type highlighted. All statistical results are given with a 99%
      confidence interval.],
  )<tab:bb_queries>
]

Text words, keyword: #keyword("keyword")
type: #type("type")
location: #location("location")
invariant: #invariant("invariant")
rate: #rate("rate")
select: #select("select")
guard: #guard("guard")
sync: #sync("sync")
update: #update("update")
weight: #weight("weight")
transition: #transition("transition")

== Key figures

#grid(columns: 2,
  figure(image("../Graphics/Intro/CPS.drawio.pdf", width: 100%),
    caption: [A cyber-physical system ]
  ),
  figure(include("../Graphics/Intro/Post-shielding.typ"),
    caption: [Post-shielding],
  ),
  figure(image("../Graphics/Intro/BB Ball.pdf"), caption: [#uppaal "Ball" template from COSHY. \ #hide("a")]
  ),
  figure(image("../Graphics/Intro/V-table 500.png", width: 50%),
    caption: [Value $max_a Q(s, a)$ and best action \ after 500 episodes.]
  )
)
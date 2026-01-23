#import "Colours.typ" : *


#let infobox(content, title: none, width: 100%) = {
  set align(left)
  stack(dir: ttb,
    box({set text(fill: white); title}, stroke: none, inset: 1em, fill: wetasphalt, width: width),
    box(content, stroke: none, inset: 1em, fill: clouds, width: width),
  )
}

#let fallback = {set text(fill: white); $nabla$}
#let shield = $fallback #h(-0.65em) #image("../Graphics/Shield.svg", height: 0.6em)$

#shield

// https://forum.typst.app/t/how-can-i-label-the-columns-and-rows-of-a-matrix/2220/3
#let labelmat(
  collabels,
  rowlabels,
  ..args
) = context {
  let numcols = collabels.len()
  let numrows = rowlabels.len()
  let matentries = args.pos().chunks(numcols)
  let matheight = matentries.map(
    row => calc.max(..row.map(i => measure(i).height))
  ).sum() + 10pt * numrows
  let delimcell(delim) = table.cell(
    rowspan: numrows, 
    box(inset: (top: -5pt, left: -5pt), $lr(delim, size: #matheight)$)
  )
  table(
    columns: (auto, 7pt, ..(auto,) * numcols, 7pt),
    stroke: none,
    ..args.named(),
    [], [], ..collabels, [],
    ..for (rowindx, (rowlab, rowentries)) in rowlabels.zip(matentries).enumerate() {(
      rowlab,
      ..if rowindx == 0 {(delimcell($\[$),)},
      ..rowentries,
      ..if rowindx == 0 {(delimcell($\]$),)},
    )},
  )
}

#labelmat(
  ("a", "b", "c"),
  ("d", "e", "f"),
  $alpha_r display(beta_s / delta)$, $0$, $1$,
  $1$, $2$, $display(sum_2^n i^2)$,
  $1$, $2$, $3$,
  align: center + horizon
)

#let todo(content) = {
  set text(font: "Fira Code", size: 8pt, fill: wetasphalt) 
  [\ ]
  h(-3.8em)
  text(fill: green, weight: "bold")[TODO: ]
  content
  [ \ ]
}

#let citationneeded(content) = {
  if (not (content == [] or content == none)) {
    [\[#text(size: 7pt, fill: red, content)\]]
  } else {
      [\[#text(size: 7pt, fill: red, "Citation Needed")\]]
  }
}

// Cite Label (CL) shorthand to use mostly with dblp
#let cl(label_string) = cite(label(label_string))

#let Act = $A c t$
#let mdp = $cal(M)$
#let powerset(x) = $scr(P)(#x)$
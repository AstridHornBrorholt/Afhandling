#import "Colours.typ" : *


#let infobox(content, name: none, width: 100%) = {
  set align(left)
  stack(dir: ttb,
    box({set text(fill: white); name}, stroke: none, inset: 1em, fill: wetasphalt, width: width),
    box(content, stroke: none, inset: 1em, fill: clouds, width: width),
  )
}

#let fallback = {set text(fill: rgb(0, 0, 0, 0)); $nabla$}
#let shield = $fallback #h(-0.65em) #image("../Graphics/Shield.svg", height: 0.6em)$

#let hatshield = $fallback #h(-0.65em)  hat(#image("../Graphics/Shield.svg", height: 0.6em))$
#let tildeshield = $fallback #h(-0.65em)  tilde(#image("../Graphics/Shield.svg", height: 0.6em))$

#shield
#hatshield

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


#let question(content) = {
  set text(font: "Fira Code", size: 8pt, fill: wetasphalt) 
  [\ ]
  h(-6.3em)
  text(fill: peterriver, weight: "bold")[question: ]
  content
  [ \ ]
}

#let new(content) = {

  move(rotate(text(fill: nephritis, weight: "bold")[New], -90deg, origin: left), dx: -12pt, dy: 17pt)
  v(-1.8em)
  block(content, 
    stroke: (left: (thickness: 2pt, paint: nephritis)),
    outset: (left: 4pt),
    )
}

#let updated(content) = {

  move(rotate(text(fill: carrot, weight: "bold")[updated], -90deg, origin: left), dx: -12pt, dy: 35pt)
  v(-1.8em)
  block(content, 
    stroke: (left: (thickness: 2pt, paint: carrot)),
    outset: (left: 4pt),
    )
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

#let comment(content) = [ #h(1fr) $triangle.r$ #content ]

#let Act = $A c t$
#let mdp = $cal(M)$
#let mg = $cal(G)$
#let ls = $cal(L)$
#let powerset(x) = $scr(P)(#x)$
#let argmax = $op("arg max", limits: #true)$
#let argmin = $op("arg min", limits: #true)$

#let intersection = $inter$
#let intersect = $intersection$

#let models = $scripts(models)$
#let modelsnot = $cancel(models, length: #90%)$
#let widehat(body) = text(font: "Latin Modern Math", $hat(body)$)

Numerals
#let th = "th"
#let nd = "nd"

// The Elder Futhark
#let fehu = "ᚠ"
#let uruz = "ᚢ"
#let thurisaz = "ᚦ"
#let ansuz = "ᚨ"
#let raido = "ᚱ"
#let kaunan = "ᚲ"
#let gebo = "ᚷ"
#let wunjo = "ᚹ"
#let hagalaz = "ᚺ"
#let naudiz = "ᚾ"
#let isaz = "ᛁ"
#let jera = "ᛃ"
#let eiwaz = "ᛇ"
#let perth = "ᛈ"
#let algiz = "ᛉ"
#let sowilo = "ᛊ"
#let tiwaz = "ᛏ"
#let berkanan = "ᛒ"
#let ehwaz = "ᛖ"
#let mannaz = "ᛗ"
#let laguz = "ᛚ"
#let ingwaz = "ᛜ"
#let dagaz = "ᛞ"
#let othala = "ᛟ"

// "Double or Nothing" example
#let flip = smallcaps(text("flip", font: "Gentium Book Plus"))
#let stop = smallcaps(text("stop", font: "Gentium Book Plus"))

// "Smoker" example
#let lung = "🫁"
#let lungexplode = lung + h(-1em) + text("💥", size: 0.9em)
#let lungsparkle = lung + h(-.4em) + text("✨", size: 0.9em)
#let smoke = smallcaps(text("smoke", font: "Gentium Book Plus"))
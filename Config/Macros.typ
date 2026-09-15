#import "Colours.typ" : *


#let infobox(content, name: none, width: 100%) = {
  set align(left)
  stack(dir: ttb,
    box({set text(fill: white); name}, stroke: none, inset: 1em, fill: wetasphalt, width: width),
    box(content, stroke: none, inset: 1em, fill: clouds, width: width),
  )
}

#let annotate(..args) = { // From the docs 
  box(place(..args))
  // Word-joiner
  sym.wj 
  // The zero-width weak spacing serves to discard spaces between the function call and the next word.
  h(0pt, weak: true)
}

#let fallback = {set text(fill: rgb(255, 255, 255, 0), size: 0.8em); $nabla$}
#let shield = $fallback#annotate(bottom + right, image("../Graphics/Shield.svg", height: 0.6em), dx: -0.1em)$

#let hatshield = $hat(fallback)#annotate(bottom + right, image("../Graphics/Shield.svg", height: 0.6em), dx: -0.1em)$
#let tildeshield = $tilde(fallback)#annotate(bottom + right, image("../Graphics/Shield.svg", height: 0.6em), dx: -0.1em)$

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
#let cl(..label_strings) = {for label_string in label_strings.pos() {cite(label(label_string))}
}

#let paperref(label, with-title: false) = context{
  let h = locate(label)
  
  if not with-title {
    link(h, [Paper #numbering("A", ..counter(heading).at(h))])
  } else {
    link(h, {
        [Paper ]
        numbering("A", ..counter(heading).at(h))
        [: ]
        show linebreak: none
        query(label).first().body
      }
    )
   }
}

#let contribution(papers: none, body) = {
  show figure: set block(spacing: 0.5em)
  figure(
  kind: "contribution",
  supplement: [Contribution],
  caption: [],
  placement: none,
  if {papers != none } [*(#papers)*\ ]+
  [
    #body
  ]
)}

#let comment(content) = [ #h(1fr) $triangle.r$ #content ]

#let skew(content) = {set math.frac(style: "skewed"); content}

#let Act = $A c t$
#let mdp = $cal(M)$
#let mg = $cal(G)$
#let emdp = $cal(E)$
#let ls = $cal(L)$
#let powerset(x) = $scr(P)(#x)$
#let argmax = $op("arg max", limits: #true)$
#let argmin = $op("arg min", limits: #true)$

#let intersection = $inter$
#let intersect = $intersection$

#let models = $scripts(models)$
#let modelsnot = $cancel(models, length: #90%)$
#let widehat(body) = text(font: "Latin Modern Math", $hat(body)$)

// Tools
#let prism = smallcaps[Prism]
#let uppaal = smallcaps[Uppaal]
#let uppaalsmc = smallcaps[Uppaal SMC]
#let uppaalstratego = smallcaps[Uppaal Stratego]
#let stratego = uppaalstratego
#let uppaalcoshy = smallcaps[Uppaal Coshy]
#let caap = smallcaps[Caap]
#let coshy = uppaalcoshy

// Numerals
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

// UPPAAL
#let keyword(str) = {show raw: set text(fill: keywordColour); raw(str)}
#let type(str) = {show raw: set text(fill: typeColour); raw(str)}

#let location(str) = {show raw: set text(fill: locColour); raw(str)}
#let invariant(str) = {show raw: set text(fill: invColour); raw(str)}
#let rate(str) = {show raw: set text(fill: rateColour); raw(str)}
#let select(str) = {show raw: set text(fill: selectColour); raw(str)}
#let guard(str) = {show raw: set text(fill: guardColour); raw(str)}
#let sync(str) = {show raw: set text(fill: syncColour); raw(str)}
#let update(str) = {show raw: set text(fill: updateColour); raw(str)}
#let weight(str) = {show raw: set text(fill: weightColour); raw(str)}
#let transition(str) = {show raw: set text(fill: transColour); raw(str)}

// "Double or Nothing" example
#let flip = smallcaps(text("flip", font: "Gentium Book Plus"))
#let stop = smallcaps(text("stop", font: "Gentium Book Plus"))


// "Smoker" example
#let lung = "🫁"
#let lungexplode = lung + annotate(bottom + right, text("💥", size: 0.9em), dx: 0pt, dy: 0pt,)
#let smoke = smallcaps(text("smoke", font: "Gentium Book Plus"))

// BB example

#let hit = "hit"
#let nohit = "nohit"


// Paper E
#let Unif = $"Unif"$
// Please note that it is the responsibility of the PhD student to ensure compliance with the formatting and minimum requirements.

// In order for AAU Open to be able to publish the PhD thesis, it  must comply with a number of minimum requirements regarding format. These minimum requirements must be met before the thesis is submitted. There are a number of templates that you are free to use - they are not mandatory.
// Recommended formatting

//     Page format: 170 mm x 240 mm. (This applies to all pages including articles that are to be printed along with the thesis itself)
//     Margins (top, bottom, right, left): not less than 1,5 cm.
//     Page number and possible header: Placed centrally top and bottom.
//     Font type: Use only standard fonts (e.g. Arial, Verdana, Times New Roman, Minion Pro, Baskerville, Garamond etc.).
//     Font size 12 pt/1 line spacing (Word) or 12 pt/14 pt (InDesign)
//     Quotations: Italics 

// Please notice that new chapters must start on a right-hand page. This can be secured in Word by using the "Breaks" functionality and choosing "Odd page". See guide for two page view

#import "@preview/lemmify:0.1.8": *
#import "Colours.typ" : *
#import "@preview/lovelace:0.3.1": *
#import "@preview/hydra:0.6.3": hydra

#let box-style(c, background: none) = {
  if background == none {background = c.lighten(96%)}
    (
    fill: background,
    stroke: (left: 0.3em + c),
    inset: 0.6em,
    outset: -0.15em,
    width: 100%,
  )
}

#let apply_style(doc) = {
  
  let skip-linebreak(_, it) = {
    show linebreak: none
    it.body
  }
  let add-period(_, it) = {
    if it.numbering == none {return it.body }
    numbering(it.numbering, ..counter(heading).at(it.location()))
    [. ]
    it.body
  }

  set page(
    width: 170mm,
    height: 240mm,
    margin: 25mm,
    header: context {
      if calc.odd(here().page()) {
        align(center, emph(hydra(1, skip-starting: false, display: skip-linebreak)))
      } else {
        align(center, emph(hydra(2, skip-starting: false, display: add-period)))
      }
    }
  )

  // Text & paragraphs
  set text(
    // font: "Merriweather",
    // font: "Roboto Slab",
    // font: "Noto Sans Georgian",
    // font: "EB Garamond 08", 
    font: "Gentium Book Plus",
    size: 10pt)


  // Re-size emoji because at their default height they bump up the line-height wherever they appear.
  show regex("\p{Emoji_Presentation}") : it => {
    text(size: 0.8em, it, font: "Noto Emoji")
  }

  show regex("☺|☹") : it => {
    text(it, size: 0.8em)
  }

  set footnote(numbering: "1")

  set bibliography(group: none) // Put each bibliography in its own group, resetting numbering. 

  set par(leading: 0.54em, justify: true)  // Fiddled with it till it matched the other pdf.

  show raw: set text(font: "Fira Code", fill: cmyk(78%, 32%, 0%, 49%))

  // Figures & Tables
  show figure: set block(spacing: 2em)

  set table(stroke: (x, y) => (
      left: if x == 0 or y > 0 { 0.5pt } else { 0pt },
      right: 0.5pt,
      top: if y <= 1 { 0.5pt } else { 0pt },
      bottom: 0.5pt,
    ),
  )

  set table.hline(stroke: 0.5pt)

  // Contributions
  show figure.where(kind: "contribution"): it => block(
  ..box-style(aaublå),
  width: 100%,
  align(left)[
    #text(weight: "bold")[#it.supplement #it.counter.display(it.numbering)]
    #h(.4em)
    #it.body
  ],
)


  // Headings
  show heading.where(level: 4): set heading(numbering: none)
  show heading.where(level: 5): set heading(numbering: none)
  show heading.where(level: 6): set heading(numbering: none)
  let myNumbering(..numbers) = {
    let len = numbers.pos().len()
    if (len == 1) {
      return [Paper #numbering("A", ..numbers): ]
    } 
    if (len <= 3) {
      return numbering("1.1", ..numbers.pos().slice(1))
    }
    return ""
  }
  set heading(numbering: myNumbering)
  show heading.where(level: 1): it => {
    set align(center)
    set text(size: 18pt)
    counter(figure.where(kind: image)).update(0)
    counter(figure.where(kind: table)).update(0)
    counter(figure.where(kind: "algorithm")).update(0)
    counter(math.equation).update(0)
    it
    v(1.5cm)
  }
  show heading.where(level: 2): it => {
    set text(size: 14pt)
    it
    v(0.5em)
  }
  show heading.where(level: 3): it => {
    set text(size: 12pt)
    it
  }
  show heading.where(level: 4): it => {
    set text(size: 10pt)
    it
  }
  show heading.where(level: 5): it => {
    set text(size: 10pt, weight: "regular", style: "italic")
    it.body
  }

  // Table of Contents
  show outline.entry: it => {
    show linebreak: none
    it
  }

  // Equations
  set math.equation(numbering: "(1)")

  // Lemmify theorems
  let (
    theorem, lemma, corollary,
    remark, proposition, example,
    proof, rules: thm-rules
  ) = default-theorems("thm-group", lang: "en", thm-numbering: thm-numbering-linear, max-reset-level: 1)

  show: thm-rules
  
  show thm-selector("thm-group", subgroup: "example"): it => block( it,  ..box-style(oakleaf), breakable: true,)

  show thm-selector("thm-group", subgroup: "remark"): it => block( it, ..box-style(wine), breakable: true,)
  
  show thm-selector("thm-group", subgroup: "definition"): it => {
    v(-1em) // I don't know how to do this properly :< 
    block(it, ..box-style(aaulysblå), breakable: true)
  }
  
  show thm-selector("thm-group", subgroup: "theorem"): it => {
    v(-1em)
    block(it, ..box-style(leather), breakable: true)
  }
  
  show thm-selector("thm-group", subgroup: "lemma"): it => {
    v(-1em)
    block(it, ..box-style(leather), breakable: true)
  }
  
  show thm-selector("thm-group", subgroup: "proof"): it => {
    v(-1em)
    block(it, ..box-style(leather), breakable: true)
  }


  // Gotta end with this doc or it all breaks
  doc
}

#show: apply_style

= This is the Styles document

#lorem(400)
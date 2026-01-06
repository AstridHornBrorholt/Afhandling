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



#let apply_style(doc) = {
  
  set page(
    width: 170mm,
    height: 240mm,
    margin: 25mm,
    numbering: "1",
  )

  // Text & paragraphs
  set text(
    font: "Noto Sans Georgian",
    // font: "EB Garamond 08", 
    size: 10pt)

  set par(leading: 0.54em, justify: true)  // Fiddled with it till it matched the other pdf.

  // Figures & Tables
  show figure: set block(spacing: 2em)

  set table(stroke: (x, y) => (
    left: if x == 0 or y > 0 { 0.5pt } else { 0pt },
    right: 0.5pt,
    top: if y <= 1 { 0.5pt } else { 0pt },
    bottom: 0.5pt,
  ))

  set table.hline(stroke: 0.5pt)


  // Headings
  let myNumbering(..numbers) = {
    let len = numbers.pos().len()
    if (len == 1) {
      return align(center)[Paper #numbering("A", ..numbers) #h(-0em) \ ]
    } 
    if (len <= 3) {
      return numbering("1.1", ..numbers.pos().slice(1))
    }
    return ""
  }
  set heading(numbering: myNumbering)
  show heading.where(level: 1): it => {
    set align(center)
    set heading(supplement: [Paper])
    set text(size: 18pt)
    // set align(center)
    it
    v(1.5cm)
  }
  show heading.where(level: 2): it => {
    set text(size: 14pt)
    it
    v(0.5em)
  }
  show heading.where(level: 3): it => {
    set text(size: 11pt)
    it
  }
  show heading.where(level: 4): it => {
    set text(size: 10pt)
    it
  }
  // Lemmify theorems
  
  let (
    theorem, lemma, corollary,
    remark, proposition, example,
    proof, rules: thm-rules
  ) = default-theorems("thm-group", lang: "en", thm-numbering: thm-numbering-linear)

  show: thm-rules
  
  show thm-selector("thm-group", subgroup: "example"): it => box(
    it,
    stroke: 0.5pt,
    inset: 1em
  )


  // Gotta end with this doc or it all breaks
  doc
}

#show: apply_style

= This is the Styles document

#lorem(400)
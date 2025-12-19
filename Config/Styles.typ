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


#let apply_style(doc) = {
  set page(
    width: 170mm,
    height: 240mm,
    margin: 25mm,
    numbering: "1",
  )
  set text(
    font: "Noto Serif",
    // font: "EB Garamond 08", 
    size: 10pt)

  set par(leading: 0.54em, justify: true)  // Fiddled with it till it matched the other pdf.

  set heading(numbering: "1.1.1")
  show heading.where(level: 1): it => {
    set heading(supplement: [Chapter])
    set text(size: 18pt)
    // set align(center)
    it
    v(1.5cm)
  }
  show heading.where(level: 2): it => {
    set text(size: 18pt)
    it
  }
  show heading.where(level: 3): it => {
    set text(size: 11pt)
    it
  }
  show heading.where(level: 4): it => {
    set text(size: 10pt)
    it
  }
  doc
}

#show: apply_style

= This is the Styles document

#lorem(400)
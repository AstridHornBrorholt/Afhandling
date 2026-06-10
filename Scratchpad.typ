#import "Config/Styles.typ" : apply_style
#import "Config/Macros.typ" : *

#show: apply_style
#set page(numbering: "I")

_I use this file to compile parts of the document, mostly just so that scrolling to the end of the document goes to somewhere meaningful. For even bigger documents it's also a good way to ensure sub-second compile times, but that's not a concern here._

#outline()
#pagebreak()

#include "MyNotes.typ"
#pagebreak()

#counter(page).update(1)
#set page(numbering: "1")

#include "Mainmatter/Introduction.typ"

#[  // HACK: Dummy forward-references to allow the introduction to compile even though contains labels pointing to the papers.
  #set heading(numbering: n => "①")
  = DUMMY <post-shielding-optimization>
]
#import "Config/Styles.typ" : apply_style
#import "Config/Macros.typ" : *

#show: apply_style
#set page(numbering: "I")

_I use this file to compile parts of the document, mostly just so that scrolling to the end of the document goes to somewhere meaningful. For even bigger documents it's also a good way to ensure sub-second compile times, but that's not a concern here._

Typst version: *#sys.version*

#outline(title: "Table of Contents", depth: 3)
#pagebreak()

#include "MyNotes.typ"
#pagebreak()

#counter(heading).update(1)
#counter(page).update(1)
#set page(numbering: "1")

#include "Mainmatter/Introduction.typ"

#[  // HACK: Dummy forward-references to allow the introduction to compile even though contains labels pointing to the papers.
  #set heading(numbering: "①")
  #counter(heading).update(0)
  = DUMMY paper:A <paper:A>
  == DUMMY post-shielding-optimization <post-shielding-optimization>
  = DUMMY paper:B <paper:B>
  = DUMMY paper:C <paper:C>
  = DUMMY paper:D <paper:D>
  = DUMMY paper:E <paper:E>
]
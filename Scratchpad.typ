#import "Config/Styles.typ" : apply_style
#import "Config/Macros.typ" : *

#show: apply_style


I use this file to compile parts of the document, mostly just so that scrolling to the end of the document goes to somewhere meaningful. For even bigger documents it's also a good way to ensure sub-second compile times, but that's not a concern here.

#include "MyNotes.typ"

#include "Mainmatter/Introduction.typ"

#[  // HACK: Dummy forward-references to allow the introduction to compile even though contains labels pointing to the papers.
  #set heading(numbering: n => "DUMMY ①")
  = DUMMY <post-shielding-optimization>
]
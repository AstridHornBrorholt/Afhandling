#import "Colors.typ" : *


#let infobox(content, title: none, width: 100%) = {
  set align(left)
  stack(dir: ttb,
    box({set text(fill: white); title}, stroke: 1pt + black, inset: 1em, fill: wetasphalt, width: width),
    box(content, stroke: 1pt + black, inset: 1em, fill: clouds, width: width),
  )
}

#let fallback = {set text(fill: white); $nabla$}
#let shield = $fallback #h(-0.65em) #image("../Graphics/shield.svg", height: 0.6em)$

#shield
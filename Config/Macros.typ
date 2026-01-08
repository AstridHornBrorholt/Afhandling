// https://flatuicolors.com/palette/defo

#let turquoise = cmyk(86%, 00%, 17%, 26%)
#let emerald = cmyk(77%, 00%, 45%, 20%)
#let peterriver = cmyk(76%, 31%, 00%, 14%)
#let amethyst = cmyk(15%, 51%, 00%, 29%)
#let wetasphalt = cmyk(45%, 22%, 00%, 63%)

#let greensea = cmyk(86%, 00%, 17%, 37%)
#let nephritis = cmyk(78%, 00%, 45%, 32%)
#let belizehole = cmyk(78%, 31%, 00%, 27%)
#let wisteria = cmyk(18%, 61%, 00%, 32%)
#let midnightblue = cmyk(45%, 22%, 00%, 69%)

#let sunflower = cmyk(00%, 19%, 94%, 05%)
#let carrot = cmyk(00%, 45%, 85%, 10%)
#let alizarin = cmyk(00%, 67%, 74%, 09%)
#let clouds = cmyk(02%, 00%, 00%, 05%)
#let concrete = cmyk(10%, 01%, 00%, 35%)

#let orange = cmyk(00%, 36%, 93%, 05%)
#let pumpkin = cmyk(00%, 60%, 100%, 17%)
#let pomegranate = cmyk(00%, 70%, 78%, 25%)
#let silver = cmyk(05%, 02%, 00%, 22%)
#let asbestos = cmyk(10%, 01%, 00%, 45%)


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
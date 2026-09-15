#import "../Config/Styles.typ": apply_style
#show: apply_style

#set document(
    title: "Scalable Shielded Reinforcement Learning for Cyber-physical Systems", 
    author: "Astrid Horn Brorholt",
)

#context[#align(center)[
  #set par(justify: false)

  #box(width: 100%, stroke: (top: 2pt, bottom: 1pt), height: 4pt) // Divider

  #text(size: 28pt, weight: "bold")[
    #document.title
  ]
  
  #box(width: 100%, stroke: (top: 1pt, bottom: 2pt), height: 4pt) // Divider

  #v(1fr)

  PhD thesis #datetime.today().display("[year]")

  #text(size:14pt)[
    Astrid Horn Brorholt
  ]

  #v(1fr)

  #image("../Graphics/aau-logo.png", width: 30%)
]]


#import "@preview/cetz:0.4.2"
#import "../../Config/Colors.typ" : *

#set text(size: 8pt)
#cetz.canvas({
  import cetz.draw: *
    

  content((0,0),  v(7pt) + image("../Shield.svg", height: 25pt), name: "Shield", alt: "∇")
  content((rel: (0, 0.6)),  [Shield])

  content((2.25, 0),  text("🤖", size:  25pt) + v(7pt), name: "Agent")
  content((rel: (0, 0.6)), [Agent])

  content((4.5, 0),  text("🌏", size:  25pt) + v(7pt), name: "System")
  content((rel: (0, 0.6)),  [System])
  
    line((rel:(0.1, 0), to: "Shield.east"), "Agent",  stroke: (paint: emerald, thickness: 3pt), mark: (end:  (symbol: ">")))
  content((rel: (-1.1, -0.4), to: "Agent.center"),  [Allwed \ actions])
    line((rel:(0.1, 0), to: "Agent.east"), "System",  stroke: (paint: emerald, thickness: 3pt), mark: (end:  (symbol: ">")))
  content((rel: ( 1.1, -0.4), to: "Agent.center"),  [Safe \ action])

  line("System", 
    (rel: (0, -1.7), to: "System"), 
    (rel: (0, -1.7), to: "Shield"),  
    "Shield", 
    stroke: (paint: wetasphalt, thickness: 3pt),
    mark: (end: (symbol: ">"))
  )
  content((rel: (0.85, -1.3)),  [Observation \ #v(1em)])

  line((rel: (0, -1.7), to: "Agent"),
    "Agent",
    stroke: (paint: wetasphalt, thickness: 3pt),
    mark: (end: (symbol: ">"))
  )
  content((rel: (0.85, -1.3)),  [Observation, \ Reward])
})
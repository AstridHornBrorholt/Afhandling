#import "@preview/cetz:0.4.2"
#import "../../Config/Colours.typ" : *

#set text(size: 8pt)
#cetz.canvas({
  import cetz.draw: *
    

  content((0,0),  v(7pt) + image("../Shield.svg", height: 25pt), name: "Shield", alt: "∇")
  content((rel: (0, 0.6)),  [Shield])

  content((2.25, 0),  text("🤖", size:  25pt) + v(7pt), name: "Agent")
  content((rel: (0, 0.6)), [Agent])

  content((4.5, 0),  text("🌏", size:  25pt, fill: silver) + place(text("?", size:  25pt), center + horizon, dy: -0.2em) + v(7pt), name: "System")
  content((rel: (0, 0.73)),  [Unknown \ System])

  content((3.2, 1.8),  text("📊", size:  25pt) + v(3pt), name: "Estimator")
  content((rel: (0, 0.6)),  [Estimator])
  
    line((rel:(0.1, 0), to: "Shield.east"), "Agent",  stroke: (paint: emerald, thickness: 3pt), mark: (end:  (symbol: ">")))
  content((rel: (-1.1, -0.4), to: "Agent.center"),  [Allowed \ actions])
    line((rel:(0.1, 0), to: "Agent.east"), "System",  stroke: (paint: emerald, thickness: 3pt), mark: (end:  (symbol: ">")))
  content((rel: ( 1.1, -0.4), to: "Agent.center"),  [Safe \ action])
    line((rel:(0.1, 0), to: "Agent.east"), (rel:(0.5, 0), to: "Agent.east"), "Estimator",  stroke: (paint: emerald, thickness: 3pt), mark: (end:  (symbol: ">")))
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


  line((rel: (0, -1.7), to: "System"), 
    (rel: (1.3, -1.7), to: "System"),  
    (rel: (2.6, 0), to: "Estimator"),  
    "Estimator", 
    stroke: (paint: wetasphalt, thickness: 3pt),
    mark: (end: (symbol: ">"))
  )
  content((rel: (1.6, 0.2)),  [Observation \ #v(1em)])

  line("Estimator", 
    (rel: (-3.2, 0), to: "Estimator"), 
    (rel: (0, 0.2), to: "Shield.north"), 
    stroke: (paint: wetasphalt, thickness: 3pt),
    mark: (end: (symbol: ">"))
  )
  content((rel: (-1.6, 0.2), to: "Estimator"),  [Update \ #v(1em)])
})
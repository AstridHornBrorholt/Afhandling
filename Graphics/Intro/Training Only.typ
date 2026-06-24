#import "@preview/cetz:0.4.2"
#import "../../Config/Colours.typ" : *

#cetz.canvas({
  import cetz.draw: *
  
  content((1, 0),  image("Student.png", height: 30pt), name: "Student", alt: "🤖")
  content((1, 0),  v(10pt) + image("../Shield Covering.svg", height: 45pt, alt: "∇"), name: "Shield1")
  content((1, 0.8), [Training])

  content((3, 0),  image("Worker.png", height: 30pt), name: "Worker", alt: "🤖")
  // content((3, 0),  v(10pt) + image("../Shield Covering.svg", height: 45pt, alt: "∇"), name: "Shield2")
  content((3, 0.8), [Operation])
  
  line("Student", "Worker", mark: (end: ">"))
})
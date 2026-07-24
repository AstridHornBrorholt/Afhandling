#import "Config/Macros.typ" : *

== Terminology

I would do well to define these terms in the text and use them consistently.

/ System: The actual system in use.
/ Model: A model of the system used for shielding, verification and probably also training.
  / MDP: You know.
  / HMDP: Or whatever. 
/ Shield: A component that enforces safety onto the model.
/ Policy: A decision making algorithm thingy that is meant to act upon the system to achieve some outcome.
/ Agent: A kind of non-static Policy, reinforcement learning implied. 
/ Trace: Created from a policy and a model. 
/ Real-world outcome: Created from a policy acting upon a system.

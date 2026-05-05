#import "Config/Macros.typ" : *

== Terminology

I would do well to define these terms in the text and use them consistently.

/ System: The actual system in use.
/ Model: A model of the system used for shielding, verification and probably also training.
  / MDP: You know.
  / HMDP: Or whatever. 
/ Shield: A component that enforces safety onto the model.
/ Controller: A decision making algorithm thingy that is meant to act upon the system to achieve some outcome.
/ Agent: A kind of controller, reinforcement learning implied. 
/ Trace: Created from a controller and a model. 
/ Real-world outcome: Created from a controller acting upon a system.

==  The Post-shielding Question

So in the article, it's really a mess. In the implementation I do both post-shielding and pre-shielding, depending on the model.
Mercifully, this is not written in the text of the article, just buried in the code.
And in the introduction, we conflate post-shielding with post-hoc shielding.

Maybe this should be the story in the thesis: Paper A compared post-shielding + post-hoc shielding, with pre-shielding + end-to-end shielding.
It is therefore unclear what made the difference, but we speculate it's the post-hoc vs end-to-end shielding which has the most impact on the learning outcome. 
Yes, that would do nicely. 

Maybe we can re-do the bouncing ball experiment for a full parameter sweep.

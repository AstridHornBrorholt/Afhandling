#import "Config/Macros.typ" : *
== Notes

=== Terminology

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


=== Hybrid Systems

So what do I want to say about hybrid systems anyway?
I could give a full formalism, that's probably expected.
I can do warmup with linear systems, or other continuous systems. Like, that part is very easy. 
I can even use the BB example to show how easy it is to solve for the ball's position while falling.
And how not easy it is when it's not falling. I've got all these nice figures that aren't published anywhere. And I bet I even have the equation somewhere.
I don't even think I give the exists-forall property in the hybrid-systems paper so that would be cool to include. And argue that it's not so easy to solve when we get the hybrid guard.

And then yea after linear systems I add the hybrid guard. The ball it bounce, as it were.
And I say such systems are intricate.

And idk, it might make sense to have the BB in the RL section and say that a shield for this is hard to obtain, and do a forward-reference.
Or maybe the BB can just stay entirely in the Hybrid section. The RL section is long enough but then it wouldn't take so much space. I start by doing that.

Ok so. Bababoie.
 - BB RL example.
 - Not a finite MDP.
 - Can still do Q-learning by discretizing, works good. #footnote[Maybe I can even postulate that it nears the optimal policy as the discretization becomes more fine-grained. The RW paper argues something along those lines.]
 - Hybrid systems section: The BB is a hybrid system.
 - Linear dynamics while it's falling.
   - Control of linear systems has been cracked wide open.
 - 
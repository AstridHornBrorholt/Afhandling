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

==  Supervisor meeting

✔️ I need to present the two sets of terms as two dimensions that can be combined freely.

✔️ I *need* to specify that for end-to-end shielding, it has to be either pre- or post-shielding all the way. Mixing them makes little to no sense.

✔️ I will change "post-hoc" shielding to "operation only."

✔️ In the post-shielded MDP definition, I fail to update the reward function. Probably needs to make fehu deterministic. 

✔️ Extend to dynamic shielding.

✔️ Figure 6c is highly confusing. It should not be called end-to-end, but instead Training Only shielding.

✔️ Ordering of figure 6 should match text flow.

✔️ I give pronunciation to the fehu character.

✔️ I send the Contract-based MA shielding paper
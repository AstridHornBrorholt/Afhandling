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

==  Multi-agent Shielding

What do I even write about this?
I can say something about the size of the state-space as more agents are added. This is easy enough.
But what can I do besides this? 
There is no standard formalism for multi-agent systems, as far as I can tell, and I shouldn't just be re-capping Paper D.

I can do a literature review like the one I'm working on now of course, but not much besides that.

Oh right and of course there is the local vs global information stuff.
It's almost always partially observable environments.

Several papers have some concept of a local set of observations and a local set of projections.
There's some restriction to local safety properties, where not everything is feasible to enforce locally.

The papers mostly also discuss technical limitations on communication between agents.
They limit communication to nearby agents, or to no communication at all.

There is some undecidability result relating to decentralized enforcement of a  safety property. From Raju et al 2021,  "Without global information on the state, guaranteeing safety is, in general, undecidable [6]."
Where [6] is a PhD thesis: S. Shewe " Synthesis of Distributed Systems." Through the concept of of information forks (where agents can't deduce the global state) some undecidability result or other is arrived at.
The paper focuses instead on "local" safety properties that can be enforced "within a communication group," a term the paper coins.

Melcer et al. 2022 has a similar concept of local safety, but call the safety property _cartesian._

I should really read up on constrained cost optimization. This stuff looks like what actually works in practice. 
In Gu et al. 2023, (Safe MARL for multi-agent robot control) they define some nice theoretical guarantees for multi-agent constrained policy optimization.

Similarly, Qin et al 2021 describe a way to estimate barrier certificates using neural networks, and use it to run a drone swarm of up to 1024 drones at once.
This is not absolute safety but has safety rates above 95%.

Then lastly there is this ElSayed-Aly et al. 2021 paper which does factored shielding and compares it to centralized shielding.
It's the one who snapped up the nice title "Safe MARL via shielding."
The factored shields could do 4 agents, which the centralized shield could not.
This was all tested on medium-sized grid worlds. Hrm, sounds like they did not have a very big computer.
#import "../Config/Macros.typ" : *

#[
  #set heading(numbering: none, outlined: false)
  = Abstract

]

Advanced digital controllers can efficiently manage many kinds of physical processes, such as  self-driving cars, water systems, industrial hydraulics and electrical power grids.
Safety in these cyber-physical systems are often crucial, since mistakes can lead to costly damage of equipment, or even bodily harm. 
As such, it is important that the correctness of the policies controlling these systems can be verified.
However, many of the most advanced and efficient policies are highly complex.
They are represented as e.g. neural networks, for which verifying safe behaviour is known to be intricately hard. 
In particular, reinforcement learning has been shown to find policies which perform well, in cases where direct search for an optimal policy is computationally infeasible.

Shielding is a promising method for ensuring correctness without the need to verify the safety of policies (or of reinforcement learning agents) directly.
Shields limit the possible behaviour to a set of actions that are safe for the given system state.
In this way it acts as a guardrail that keeps the agent away from unsafe situations.
Shields are often synthesized from an abstract representation of the system, one whose behaviour only covers the aspects which are relevant to safety.
With these abstractions it is possible to describe the set of safe behaviour, even if the system as a whole is too complex to directly compute a safe an optimal policy. 

Current research describes shield synthesis methods for a variety of settings, but their applicability for cyber-physical systems has so far been limited.
Cyber-physical systems pose unique challenges since they may exhibit hybrid behaviour (a combination of discrete switches and continuous dynamics), have unknown components, and may have several agents interacting.

The contributions of this thesis aim to address these challenges.
A method for scalably synthesizing hybrid shields is presented, and made available as an extension of the modelling tool #uppaal.
Moreover, an approach to scalable shielding in multi-agent settings is presented, which decomposes a global (complex)  safety property into local (tractable) shields.
A method is also given for learning the behaviour of unknown systems, while an adaptive shield ensures safe behaviour based on existing knowledge.

These methods can be combined to achieve verifiably safe behaviour in cyber-physical systems.
With the use of a shield, reinforcement learning can be safely trained to find an optimized and verifiably correct policy.
#import "../Config/Macros.typ" : *
#import "@preview/cetz:0.4.2"
#import "@preview/subpar:0.2.2"

#[
  #set heading(numbering: none)
  = Introduction 
]

#cetz.canvas({
  import cetz.draw: *
  
  content((1, 0),  text("🤖", size:  50pt) + v(25pt), name: "Agent")
  content((10, 0),  text("🌏", size:  50pt) + v(25pt), name: "System")
  content((5,0),  image("../Graphics/Shield.svg", height: 60pt) + v(-10pt), name: "Shield")
  line("Agent.east", "Shield.center", stroke: (paint: alizarin, thickness: 5pt))
  on-layer(-1, {
    line("Agent.east", "Shield.east", stroke: (paint: alizarin, thickness: 5pt))
    line("Shield.east", "System.west",  stroke: (paint: emerald, thickness: 5pt), mark: (end:  (symbol: ">")))
  })
})

Digital control of physical components enables time-saving automation and efficient use of available resources.
This can range from a simple on/off switch to a complex neural network managing multiple processes. 
It is not uncommon for several digital components to be deployed in concert to serve complementary purposes. 
Such cyber-physical systems #citationneeded[lift something from wikipedia] are becoming more ubiquiotous and more advanced.

With applications such as autonomous vehicles, water management systems, industrial hydraulics, or power controllers, great care must be taken to ensure the safety of people, equipment, and resources that are diretly or indirectly affected by the system. 

This can be achieved through the field of formal methods, which has a wide variety of approaches that can provide proof that a given system restricts itself ot a safe subset of behaviours. #citationneeded[handbook of model checking (?)]
This presumes an accurate model of the (cyber-physical) system under verification and techniques are most often subject to "state-space explosion," where the complexity of verification is highly sensitive to the size of the model.

#todo[Gotta mention "multi-objective" and the trade-off between safety and optimality.]

Neural networks are notable for having achieved impressive performance in a wide variety of tasks #citationneeded[alphago, atari games, chatgpt why not].
This performance is achieved by controllers that use a high number of neurons, making direct formal verification infeasible.

Even when a controller cannot be verified directly, other approaches can be used to verify the safety of the system as a whole. 
In #citationneeded[On time], it was shown how a safety propertty can be enforced through a maximally permissive, non-deterministic strategy.
While acting within the constraints of this strategy, reinforcement learning was utilized to optimize for a second objective, achieveing a near-optimal strategy within the safety constraints.

The term *shield* was coined in #citationneeded[Bloem et al.] to describe a component which would work in concert with a (mostly safe) controller, and intervene to prevent unsafe behaviour.
Thus, the behaviour of the shield and controller together is verifiably safe, as long as the shield is safe.
Contrary to runtime monitors #citationneeded[], which enforce a property by halting the system if the property is not satisfied, the shield will intervene by altering the actions of the controller without knowing future input/output. 
The authors proposed gurantees of minimal interference, and a property of $k$-stabilization, which states that the shield will at most intervene $k$ times before control is handed back to the controller.

#todo[This was for finite MDPs]

This concept was extended to a framework of *shielded reinforcement learning* in #citationneeded[Alshiekh et al.].
Here, a shield monitors and possibly corrects the actions of a learning agent, which enables safe exploration. 
This enables the safe use of complex learning agents that can achieve cost optimal behaviour. 
Approaches such as deep Q-learning or proximal policy optimazation can be safely used in this framework, even though these methods cannot feasibly be verified directly.
The paper also points out that a shield can be synthesized from an *abstract model* of the system, one which only models behaviour relevant to the safety property being enforced.
Such an abstraction could be significantly simpler than the full system, allowing shielded reinforcement learning to scale to systems where other methods for safe and optimal control are infeasible.

Since this first article covering shielded reinforcement learning in finite MDPs, other shielding methods building upon the same framework have been described in the literature #citationneeded[Every shielded RL article I have on hand].

#todo[Some figure showing the shielded reinforcement learning loop, or other.]

#todo[An example around here somewhere would be helpful.]
#todo[Define maximally permissive]

== Reinforcement Learning

I do need a pretty thorough section on reinforcement learning.
I also need to explain the idea of a separate learning phase and an operational phase. This is not a thing in normal RL I don't think but it's important for our definition of post-hoc shielding.


== Applying the Shield

The methods of corrective action taken by the shield can vary depending on the model and the application. 
The terms pre- and post-shielding have been used in the literature to describe a shield's relationship with the controller, but with two distinct sets of meaning:

 + In one part of the literature, pre- and post-shielding refer to _how_ the shield ensures only safe actions are enacted upon the enviornment #citationneeded[Most articles on the subject, actually].
 + Alternatively the terms can refer to _when_ a shield is applied, in the process of obtaining a controller @jakobs_thesis @BrorholtJLLS23.

In the following, we shall use the terms pre- and post-shielding to mean the former, while we dub the latter meaning resp. end-to-end shielding and post-hoc shielding.

===== Pre-shielding
This term to the shield restricting the behaviour the controller, by providing a set of actions that are permitted for the given state.
The controller must be set up in such a way as to only pick an action if it is included in the set it receives from the shield. 

===== Post-shielding
Contrary to pre-shielding, this configuration is transparent to the controller.
In post-shielding the controller outputs an action to the shield, rather than sending it directly to the environment. 
The shield then evaluates the action, checking if it is in the set of permissible actions.
If the action is permitted, it is sent to the environment unaltered. 
Otherwise, the action is replaced with an alternative, permissible action. 



#subpar.grid(columns: 2,
  figure(
    cetz.canvas({
      import cetz.draw: *
      
      content((1, 0),  image("../Graphics/Intro/Student.png", height: 40pt), name: "Student")
      content((1, 0),  v(10pt) + image("../Graphics/Shield Covering.svg", height: 55pt), name: "Shield1")
      content((1, 0.8), [Training])

      content((3, 0),  image("../Graphics/Intro/Worker.png", height: 40pt), name: "Worker")
      content((3, 0),  v(10pt) + image("../Graphics/Shield Covering.svg", height: 55pt), name: "Shield2")
      content((3, 0.8), [Operation])
      
      line("Student", "Worker", mark: (end: ">"))
    }),
  caption: [End-to-end shielding]
  ),
  figure(
      cetz.canvas({
      import cetz.draw: *
      
      content((1, 0),  image("../Graphics/Intro/Student.png", height: 40pt), name: "Student")
      content((1, 0.8), [Training])

      content((3, 0),  image("../Graphics/Intro/Worker.png", height: 40pt), name: "Worker")
      content((3, 0),  v(10pt) + image("../Graphics/Shield Covering.svg", height: 55pt), name: "Shield2")
      content((3, 0.8), [Operation])
      
      line("Student", "Worker", mark: (end: ">"))
    }),
    caption:[Post-hoc shielding]
  ),
  caption: [The shield may or may not be in place during training.],
  label: <when_shielding>
)

===== End-to-end Shielding
In the context of reinforcement learning, end-to-end shielding refers to having the shield in place during _both_ the learning  _and_ operational phases.
This is necessary if the agent is interacting with a real-life system where safety violations during training are to be avoided.
End-to-end shielding was seen in #cl("DBLP:conf/aaai/AlshiekhBEKNT18") to lead to faster convergence, as the shield acts as a teacher guiding the agent away from undesireable behaviours. 

More generally, end-to-end shielding describes the process of integrating the shield in the design process of the controller,  omitting unsafe actions from consideration.

===== Post-hoc Shielding
Alternatively, the shield can be applied only in the operational phase, allowing the agent to explore unsafe actions during learning.
This can lead to slower convergence, since the agent spends time exploring unsafe states and (ideally) learning to avoid them. 
It is concievable that the shield does not alter the behaviour of the agent.
This can happen if the shield is maximally permissive while the agent has learned to behave safely. 
However, in other cases the shield may interfere with the policy learned by the agent, which violates the key assumption of RL that the environment remains static #citationneeded[].

Outside the context of RL, the term describes applying the shield as a guardrail of a controller that has been designed without the shield as reference.
Thus, an existing controller can be upgraded to give formal safety guarntees by applying a post-hoc shield in cases where altering the controller itself would be costly. 

#figure(table(columns: 2,
  table.header([Method of correction], [Time of correction]),
  [Pre-shielding], [End-to-end shielding],
  [Post-shielding], [Post-hoc shielding]),
  caption: [A term from each column can be combined to describe how the shield works in tandem with the controller.],
)

==== Convergence Guarantees

Convergence guarantees for reinforcement learning methods usually require the environment under learning to satisfy the Markov property #citationneeded[Q-learning, DQL, PPO]. I.e the state must be fully observable, and the probability distributions within the model do not change. 

It was shown in #citationneeded[Alshiekh et al.] that such guarantees extend to a shielded environment, as long as the shield's behaviour follows an unchanging probability distribution, and the shield does not have hidden state. 

Most reinforcment learning methods such as #citationneeded[ppo?] have support for models where only a subset of actions are available in each state.
As such, it is straightforward to apply the shield by removing unsafe options from each state in the model.

Alternatively, it was shown in  #citationneeded[imsorrydave] that the number of interventions of a shield was reduced for deep Q-learning by slightly changing the value update scheme: When a shield changes an action $a$ in state $s$ to $a'$, the reward $r$ was applied to the learning agent as $(s, a', r)$ while a penalty $p$ was applied to the suggested action, $(s, a, p)$.
Other variations may break convergence guarntees, such as applying only the update $(s, a', r)$.

==== Finite- and infinite-horizon shielding

In many domains, the controller will continue to function indefinitely, and safety in an unbounded horizon is desireable. 
Ideally, the shield should be able to ensure that as long as the shield is applied, the system is safe forever, such as with the shielding methods described in #citationneeded[all of them].

In some cases, it can make sense to only give guarantees $k$ steps into the future.
These finite horizon shields are often referred to as $k$-step lookahead shields #citationneeded[].
This may be desireable for models where infinite-horizon safety stratgies do not exist, or are infeasible to compute. 

==== Probabilistic shielding

When there is no fully safe strategy due to uncertainty inherent in the model or in the actual system, probabilistic guarantees can be given.
One such guarantee could be a $k$-step lookahead shield which guarantees a maximum risk of safety violation to occur within those $k$ steps.
An obvious weakness of this guarantee is that there is always the possiblity, that at $k+1$  it is the case that failure is certian, and indeed already inevitable at step $k$.
The shield would not be able to avoid such issues but I speuclate that these become less common as $k$ increases.

==== Obtaining a Model

Many formal verification tools assume that an accurate model of the system is available. 
This model could be provided by a domain expert, but in other cases it might not be available.
When no models are available, some things like erm automata learning or uncertian MDPs might be useful. #citationneeded[]

==== Multi-agent shielding

In many cyber-physical sytems, several components are working together to achieve distinct goals in the entire system. 
These kinds of multi-agent sytems where different controllers are acting in tandem are called multi-agent system. 
Since formal verification methods such as shields are highly affected by issues of scalability, multi-agent approahes are useful.
There is no silver bullet.

==== Tools

#citationneeded[uppaal] #citationneeded[storm]  #citationneeded[tempest]

== Research Objectives and Contributions

My focus was on whatever the S4OS grant says. I did 4 papers.

=== Shielded Reinforcemnt Learning for Hybrid Systems

=== Efficient Sheild Synthesis via State-space Transformation

=== Compositional Shielding and Reinforcement Learning for Multi-agent Systems

=== #smallcaps[UPPAAL COSHY]: Automatic Synthesis of Compact Shields for Hybrid Systems
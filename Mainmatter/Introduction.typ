#import "../Config/Macros.typ" : *
#import "@preview/cetz:0.4.2"
#import "@preview/subpar:0.2.2"

#todo[Almost every section should have a "Related Work" or "State of the Art" subsection.]

#[
  #set heading(numbering: none)
  = Introduction
]

Digital control of physical components enables time-saving automation and efficient use of available resources.
This can range from a simple if/then switch to a complex neural network managing multiple interconnected processes.
It is not uncommon for several digital components to be deployed in concert to serve complementary purposes.
Such cyber-physical systems @lee2006cyber @lee2008cyber are becoming more ubiquitous and more advanced.

With applications such as autonomous vehicles, water management systems, industrial hydraulics, and power controllers, great care must be taken to ensure the safety of people, equipment, and resources that are directly or indirectly affected by the system.

This can be achieved through the field of formal methods, which has a wide variety of approaches that can provide proof that a given system restricts itself ot a safe subset of behaviours. #citationneeded[handbook of model checking (?)]
This presumes an accurate model of the (cyber-physical) system under verification and techniques are most often subject to "state-space explosion," where the complexity of verification is highly sensitive to the size of the model.

Neural networks are notable for having achieved impressive performance in a wide variety of tasks #citationneeded[alphago, atari games, muzero, chatgpt].
This performance is achieved by controllers that use a high number of neurons, making direct formal verification infeasible.

#todo[Mention the term multi-objective optimization and the trade-off between safety and efficiency.]

== Reinforcement Learning

Reinforcement learning @kaelbling1996reinforcement @arulkumaran2017deep is a major class of machine learning techniques, separate from supervised and unsupervised learning @alloghani2020systematic.
In supervised learning, models learn from labelled data, to predict the labels of unseen data.
Unsupervised (or self-supervised) learning similarly trains the model on a set amount of unlabelled data, to discover relevant patterns and approximations.
In contrast, reinforcement learning _agents_ are actively interacting with a system, directing exploration and receiving observation data and reward, as the system responds to actions taken by the agent.

The interaction between an agent and a system is illustrated in @fig:RL as an unending loop.
The agent observes its current state, and makes a decision on which action to take, based on its current policy and exploration strategy (e.g. $epsilon$-greedy).
Taking the action yields a reward that the agent can use to update its policy, and an observation of the updated state which it will use to pick the next action.

#figure(include("../Graphics/Intro/Unshielded.typ"), caption: [The reinforcement learning loop.] )<fig:RL>

The reinforcement learning problem can be stated in many different ways, depending on the nature of the problem, but is perhaps most commonly defined in terms of a Markov decision process (MDP) #cl("DBLP:journals/siamrev/Feinberg96").
MDPs describe stochastic systems, where the outcomes of actions only depend on the current (observable) state of the system, and not on which actions or states were seen previously.
An MDP can be described by a tuple $(S, s_0 Act, P, R)$ where

 - $S$ is a set of states,
 - $s_0 in S$ is an initial state,
 - $Act$ is a set of actions,
 - $P : S times Act times S -> [0; 1]$ with  $forall s in S, a in Act : sum_(s' in S) P(s, a, s') = 1$ gives the probability of reaching state $s'$ from state $s$ as a result of  taking the action $a$, 
 - and $R : S times Act -> RR$ gives the reward $R(s, a)$ for taking action $a$ in state $s$.

#todo[$S$ can be finite or infinite. Countably infinite will be covered later.]
#todo[Mention there can be even richer models.]

A _policy,_  is any method (such as a reinforcement learning agent) for choosing the next action from a given state. 


Policies can either be 
 - _probabilistic_ $S times Act -> [0; 1]$, giving a probability distribution over actions, 
 - _deterministic_ $S -> Act$, uniquely selecting one specific action for each state, 
 - or _nondeterministic_ $S -> powerset(Act)$, giving a subset $A in Act$ of possible actions. 

Given an e.g. nondeterministic policy $sigma : S -> powerset(Act)$, a trace $xi$ of an MDP is an interleaved series of states and actions $xi = s_0 a_0 s_1 a_1 s_2 a_2 ...$ such that $a_i in sigma(s_i)$ and $P(s_i, a_i, s_(i+1))$. 
Traces can be both finite or infinite. 
Given a set $phi subset.eq S$ of safe states, we say a trace $xi$ is safe (with regards to $phi$) if for every $s_i$ in $xi$, $s_i in phi$.

#todo[Reward; optimization problem.]


#todo[Q-learning as example. (Exploration policies, convergence, discretization,)]

It can sometimes be useful to view machine learning as consisting of two different phases: Initial _training,_ and subsequent _operation_ as part of a real-life system.
In the common view of reinforcement learning, the agent is continually exploring, learning, and improving, even when in operation.
However, this is not always the case in practice.
Legal requirements may warrant a costly re-certification every time changes are made to a policy, prohibiting the agent from adapting its behaviour during operation.
Technical limitations during operations may also preclude learning, such as reductions applied to the model, in order to deploy it to an embedded platform.

#todo[Q-learning example: Frozen Lake, and Bouncing Ball.]

== Shielding

#todo[Introduce safety as a set of states, as opposed to liveness]

#todo[RL alone doesn't converge to safe policies.]

Even when a policy cannot be verified directly,
#todo[because it's infeasible to  do so]
other approaches can be used to verify the safety of the system as a whole.
#todo[why is this easier?]

#todo[This goes in related work; go directly to formal definition of shielding.]

In @DavidJLLLST14 it was shown how a safety property can be enforced through a maximally permissive, safe, non-deterministic strategy.
While acting within the constraints of this strategy, reinforcement learning was utilized to optimize for a second objective, achieving a near-optimal strategy within the safety constraints.

The term *shield* was coined in @BloemKKW15 to describe a component which would work in concert with a (mostly safe) policy, and intervene to prevent unsafe behaviour.
Thus, the behaviour of the shield and policy together is verifiably safe, as long as the shield is safe.
Contrary to runtime monitors #citationneeded[], which enforce a property by retroactively altering or halting a trace, the shield will intervene by altering the actions of the policy.
The authors proposed guarantees of minimal interference, and of $k$-stabilization, which states that the shield will at most intervene $k$ times before control is handed back to the policy.

This concept was extended to a framework of *shielded reinforcement learning* in @AlshiekhBEKNT18.
Here, a shield monitors and possibly corrects the actions of a learning agent, which enables safe exploration.
This enables the safe use of complex learning agents that can achieve cost optimal behaviour.
Approaches such as deep Q-learning or proximal policy optimization can be safely used in this framework, even though these methods cannot feasibly be verified directly.
The paper also points out that a shield can be synthesized from an *abstract model* of the system, one which only models behaviour relevant to the safety property being enforced.
Such an abstraction could be significantly simpler than the full system, allowing shielded reinforcement learning to scale to systems where other methods for safe and optimal control are infeasible.

Since this first article covering shielded reinforcement learning in finite MDPs, other shielding methods building upon the same framework have been described in the literature #citationneeded[Every shielded RL article I have on hand].

A shield can be viewed as a nondeterministic strategy $shield : S -> powerset(Act)$ for a safety property $phi$ on an MDP $mdp$ such that any trace $xi$ that is an outcome of $shield$ is safe with regards to $phi$.
A shield is said to be  _maximally permissive_ $shield^*$ (or minimally interfering) @BloemKKW15 @AlshiekhBEKNT18 @PaperA. This $shield^*$ is the unique shield where for all shields $shield$ that are safe wrt. $mdp$ and $phi$, it holds that $a in shield (a) => a in shield^*(a)$ @BernetJW02.


#todo[Time to shield the example.]

==== Finite- and infinite-horizon shielding

In many domains, the controller will continue to operate indefinitely, which warrants safety guarantees to match.
Ideally, the shield should be able to ensure that as long as the shield is applied, the system is safe forever, such as with the shielding methods described in #citationneeded[all of them].

In some cases, it can make sense to only give guarantees $k$ steps into the future.
These finite horizon shields are often referred to as $k$-step lookahead shields #citationneeded[].
This may be desirable for models where infinite-horizon safety strategies do not exist, or are infeasible to compute.

==== Probabilistic shielding

When uncertainty is inherent to a system, it might not be possible for any strategy to guarantee safety for all traces starting in the initial state.
Although such _absolute guarantees_ are not available, it might still be possible to give guarantees relating to staying safe with a specific probability.
One such guarantee could be a $k$-step lookahead shield which guarantees a maximum risk of safety violation to occur within those $k$ steps.
This leaves the possibility, that the state at step $k+1$ is unsafe for all actions that could be taken at $k$.

#todo[Expand this section with types of probabilistic guarantees.]

==== Obtaining a Model

Many formal verification tools assume that an accurate model of the system is available.
This model could be provided by a domain expert, but in other cases it might not be available.
When no models are available, some things like erm automata learning or uncertain MDPs might be useful. #citationneeded[] #cl("DBLP:conf/isola/TapplerPKMBL22")

#todo[Expand this section.]

=== Applying the Shield

The methods of corrective action taken by the shield can vary depending on the model and the application.
The terms pre- and post-shielding have been used in the literature to describe a shield's relationship with the policy, but with two distinct sets of meaning:

 + In one part of the literature, pre- and post-shielding refer to *how* the shield ensures only safe actions reach environment #cl("DBLP:journals/corr/abs-1708-08611") #cl("DBLP:journals/cacm/KonighoferBJJP25") @MedicalShielding #cl("DBLP:conf/isola/TapplerPKMBL22").
 + Alternatively the terms can refer to *when* a shield is applied, in the process of obtaining a policy @jakobs_thesis @PaperA.

In the following, we shall use the terms pre- and post-shielding to mean the former, while we dub the latter meaning resp. end-to-end shielding and post-hoc shielding.


#subpar.grid(columns: 2,
  figure(include("../Graphics/Intro/Pre-shielding.typ"),
  caption: [Pre-shielding]
  ),
  figure(include("../Graphics/Intro/Post-shielding.typ"),
    caption: [Post-shielding]
  ),
  caption: [The shield can enforce safety in multiple ways],
  label: <when_shielding>
)

#todo[Q-learning here also.]

===== Pre-shielding
This term refers to the shield restricting the behaviour of the the policy, by providing a set of actions $A subset.eq Act$ that are permitted for the given state.
The policy must be set up in such a way as to only pick an action $a$ if it is included in the set $A$ it receives from the shield.

===== Post-shielding
Contrary to pre-shielding, this configuration is transparent to the policy.
In post-shielding the policy outputs an action $a$ to the shield, rather than sending it directly to the environment.
The shield then evaluates the action $a$, checking if it is in the set of permissible actions $a in A$s.
If the action is permitted, $a$ is sent to the environment unaltered.
Otherwise, the action $a$ is replaced with an alternative, permissible action $a' in A$.

#subpar.grid(columns: 2,
  figure(include("../Graphics/Intro/End-to-end Shielding.typ"),
  caption: [End-to-end shielding]
  ),
  figure(include("../Graphics/Intro/Post-hoc Shielding.typ"),
    caption:[Post-hoc shielding]
  ),
  caption: [The shield may or may not be in place during training.],
  label: <when_shielding>
)

===== End-to-end Shielding
In the context of reinforcement learning, when the shield is in place during _both_ the learning  _and_ operational phases, this is called end-to-end shielding.
This is necessary if the agent is interacting with a real-life system where safety violations during training are to be avoided.
End-to-end shielding was seen in @AlshiekhBEKNT18 to lead to faster convergence, as the shield acts as a teacher guiding the agent away from undesirable behaviours.

More generally, end-to-end shielding describes the process of integrating the shield in the design process of the controller,  omitting unsafe actions from consideration.

===== Post-hoc Shielding
Alternatively, the shield can be applied only in the operational phase, allowing the agent to explore unsafe actions during learning.
This can lead to slower convergence, since the agent spends time exploring unsafe states and (ideally) learning to avoid them.
It is conceivable that the shield does not alter the behaviour of the agent.
This can happen if the shield is maximally permissive while the agent has learned to behave safely.
However, in other cases the shield may interfere with the policy learned by the agent, which violates the key assumption of RL that the environment remains static #citationneeded[].

Outside the context of RL, the term describes applying the shield as a guardrail of a controller that has been designed without the shield as reference.
Thus, an existing controller can be upgraded to give formal safety guarantees by applying a post-hoc shield in cases where altering the controller itself would be costly.

#figure(table(columns: 2,
  table.header([Method of correction], [Time of correction]),
  [Pre-shielding], [End-to-end shielding],
  [Post-shielding], [Post-hoc shielding]),
  caption: [A term from each column can be combined to describe how the shield works in tandem with the controller.],
)

#infobox(title: "Terminology in Paper A")[
  Note that what was referred to in Paper A @PaperA as post-shielding, we refer to here as post-hoc shielding.
  Conversely, what was referred to as pre-shielding was described in this section as end-to-end shielding.

  Using the terminology of this section, the paper examines the difference between end-to-end- and post-hoc shielding.
  The paper utilizes post-shields, and examines different action selection strategies when the shield intervenes.
]

=== Effects on Convergence in RL

Convergence guarantees for reinforcement learning methods usually require the environment under learning to satisfy the Markov property #citationneeded[Q-learning, DQL, PPO]. I.e the state must be fully observable, and the probability distributions within the model do not change.

In reinforcement learning methods such as Q-learning @QLearning, actions can be removed from consideration in states by omitting them in the Bellman equation update, or by  initializing their Q-value as negative infinity.
A similar approach works for gradient methods @PPO @arulkumaran2017deep #cl("DBLP:journals/corr/abs-2006-14171").
As such, it is straightforward to apply a pre-shield by restricting unsafe actions as provided by the shield.

As argued in @AlshiekhBEKNT18, a post-shield $shield$ applied to an environment $mdp$ can be viewed as a new environment $mdp^shield$.
Therefore, convergence guarantees are preserved for the combined $mdp^shield$ as long as the shield satisfies the same assumptions as the environment (i.e. Markov properties).

Some care must be taking when performing value updates using a post-shield.
Say that in state $s$,  the shield alters an unsafe action $a$ to the safe alternative $a'$, receiving reward $r$.
The straightforward approach would be to treat the shield as part of the environment, and performing value update using the triple $(s, a, r)$.
It was shown in  #cl("DBLP:conf/ijcnn/SeurinPP20") through a series of deep Q-learning experiments, that the number of interventions of a shield was reduced changing the value update scheme:
The reward $r$ was applied to the learning agent as $(s, a', r)$ while a penalty $p$ was applied to the suggested action, $(s, a, p)$.
Other approaches may be unsound, such as applying only the update $(s, a', r)$.

Pre-shielding will likely converge faster than post-shielding in general. If a model has a state $s$, with one safe action $a_1$ and unsafe actions $a_2, a_3$, a post-shielded agent will have to explore actions $a_1, a_2$ and $a_3$ in order to learn the expected reward attainable in $s$. However, a post-shielded agent will only have to learn the expected reward of $a_1$, since the other actions are masked.
Thus, it will likely gain a more precise estimate of the expected value of $s$ from the same amount of visits to the state.

==== Multi-agent shielding

In many cyber-physical systems, several components are working together to achieve distinct goals in the entire system.
Since formal verification methods are highly affected by issues of scalability, multi-agent approaches are useful.
There is no silver bullet.

#todo[Expand this section.]

== Multi-agent Shielding

== Hybrid MDPS 

=== Shielding of Hybrid Systems

=== Tools for Shielding
#citationneeded[uppaal] #citationneeded[tempest]

=== Multi-agent Shielding
...

== Research Statement and Goals
...

=== Summary of Papers
...

#[
  #set heading(numbering: none)
  ==== Paper A: Shielded Reinforcement Learning for Hybrid systems
  ...
  ==== Paper B: Efficient Shield Synthesis via State-space Transformation
  ...
  ==== Paper C: Compositional Shielding and Reinforcement Learning for Multi-agent Systems
  ...
  ==== Paper D: #smallcaps[Uppaal Coshy] - Automatic Synthesis of Compact Shields for Hybrid Systems
  ...
]

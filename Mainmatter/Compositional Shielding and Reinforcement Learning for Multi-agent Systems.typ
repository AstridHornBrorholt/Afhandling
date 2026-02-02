#import "@preview/subpar:0.2.2"
#import "@preview/lemmify:0.1.8": *
#import "@preview/lovelace:0.3.0": *
#import "../Config/Macros.typ" : *
#let (
  theorem, lemma, corollary,
  remark, proposition, example,
  proof, definition, rules: thm-rules
) = default-theorems("thm-group", lang: "en", thm-numbering: thm-numbering-linear)

= Compositional Shielding and Reinforcement Learning for Multi-agent Systems

#grid(columns: (1fr, 1fr), row-gutter: 2em,
  [Asger Horn Brorholt \
  _Department of Computer Science \ Aalborg University, Aalborg, Denmark_],

  [Kim Guldstrand Larsen \
  _Department of Computer Science \ Aalborg University, Aalborg, Denmark_],

  [Christian~Schilling \
  _Department of Computer Science \ Aalborg University, Aalborg, Denmark_])

#v(1fr)

#heading(level: 2, numbering: none)[Abstract]
Deep reinforcement learning has emerged as a powerful tool for obtaining high-performance policies. However, the safety of these policies has been a long-standing issue. One promising paradigm to guarantee safety is a _shield_, which "shields" a policy from making unsafe actions. However, computing a shield scales exponentially in the number of state variables. This is a particular concern in multi-agent systems with many agents.
In this work, we propose a novel approach for multi-agent shielding. We address scalability by computing individual shields for each agent. The challenge is that typical safety specifications are global properties, but the shields of individual agents only ensure local properties. Our key to overcome this challenge is to apply assume-guarantee reasoning. Specifically, we present a sound proof rule that decomposes a (global, complex) safety specification into (local, simple) obligations for the shields of the individual agents.
Moreover, we show that applying the shields during reinforcement learning significantly improves the quality of the policies obtained for a given training budget. 
We demonstrate the effectiveness and scalability of our multi-agent shielding framework in two case studies, reducing the computation time from hours to seconds and achieving fast learning convergence.

#pagebreak(weak: true)



== Introduction
<introduction>
Reinforcement learning
(RL) #cite(label("DBLP:books/wi/Puterman94")) #cite(label("DBLP:books/lib/SuttonB98")), and
in particular deep RL, has demonstrated success in automatically
learning high-performance policies for complex
systems #cite(label("DBLP:journals/nature/MnihKSRVBGRFOPB15")) #cite(label("DBLP:journals/nature/BellemareCCGMMP20")).
However, learned policies lack guarantees, which prevents applications
in safety-critical domains.

An attractive algorithmic paradigm to provably safe RL is
#emph[shielding] @AlshiekhBEKNT18. In this
paradigm, one constructs a #emph[shield], which is a nondeterministic
policy that only allows safe actions. The shield acts as a guardrail for
the RL agent to enforce safety both during learning (of a concrete
policy) and operation. This way, one obtains a #emph[safe-by-design
shielded policy with high performance].

#emph[Shield synthesis] automatically computes a shield from a safety
specification and a model of the system, but scales exponentially in the
number of state variables. This is a particular concern in multi-agent
(MA) systems, which typically consist of many variables. Shielding of MA
systems will be our focus in this work.

Existing approaches to MA shielding address scalability by computing
individual shields for each agent. Yet, these shields are either not
truly safe or not truly independent; rather, they require online
communication among all agents, which is often unrealistic.

In this paper, we present the first MA shielding approach that is truly
compositional, does not require online communication, and provides
absolute safety guarantees. Concretely, we assume that agents observe a
subset of all system variables (i.e., operate in a projection of the
global state space). We show how to tractably synthesize individual
shields in low-dimensional projections. The challenge we need to
overcome is that a straightforward generalization of the classical
shield synthesis to the MA setting for truly independent shields often
fails. The reason is that the projection removes the potential to
coordinate between the agents, but often some form of coordination is
required.

To address the need for coordination, we get inspiration from
#emph[compositional reasoning], which is a powerful approach, allowing
to scale up the analysis of distributed systems. The underlying
principle is to construct a correctness proof of multi-component systems
by smaller, "local" proofs for each individual component. In particular,
#emph[assume-guarantee reasoning] for concurrent programs was
popularized in seminal
works #cite(label("OwickiG76")) #cite(label("Lamport77")) #cite(label("Pnueli84")) #cite(label("Stark85")) #cite(label("DBLP:journals/fteda/BenvenisteCNPRR18")).
By writing $chevron.l A chevron.r C chevron.l G chevron.r$ for "assuming $A$,
component $C$ will guarantee $G$," the standard (acyclic)
assume-guarantee rule for finite state machines with handshake
synchronization looks as
follows #cite(label("DBLP:reference/mc/GiannakopoulouNP18")):

$ frac(
  chevron.l top chevron.r C_1 chevron.l G_1 chevron.r comma chevron.l G_1 chevron.r C_2 chevron.l G_2 chevron.r comma dots.h comma chevron.l G_(n minus 2) chevron.r C_(n minus 1) chevron.l G_(n minus 1) chevron.r comma chevron.l G_(n minus 1) chevron.r C_n chevron.l phi.alt chevron.r,
  chevron.l top chevron.r C_1 bar.v.double C_2 bar.v.double dots.h.c bar.v.double C_n chevron.l phi.alt chevron.r, 
) $

By this chain of assume-guarantee pairs, it is clear that, together, the
components ensure safety property $phi.alt$.

In this work, we adapt the above rule to multi-agent shielding. Instead
of one shield for the whole system, we synthesize an individual shield
for each agent, which together we call a #emph[distributed shield].
Thus, we arrive at $n$ shield synthesis problems (corresponding to the
rule’s premise), but each of which is efficient. In our case studies,
this reduces the synthesis time from hours to seconds. The
#emph[guarantees $G_i$ allow the individual shields to coordinate] on
responsibilities at synthesis time. Yet, distributed shields do not
require communication when deployed. Altogether, this allows us to
#emph[synthesize safe shields] in a compositional and scalable way.

The crucial challenge is that, in the classical setting, the
components $C_i$ are fixed. In our synthesis setting, the
components $C_i$ are our agents, which are #emph[not] fixed at the time
of the shield synthesis. In this work, we assume that the
guarantees $G_i$ are given, which allows us to derive corresponding
individual agent shields via standard shield synthesis.

=== Motivating Example
<sect:platoon>
A multi-agent car platoon with adaptive cruise controls consists of $n$
cars, numbered from back to front #cite(label("DBLP:conf/birthday/LarsenMT15"))
(@fig:platoon). The cars 1 to $n minus 1$ are each
controlled by an agent, while (front) car $n$ is driven by the
environment. The state variables are the car velocities $v_i$ and
distances $d_i$ between cars $i$ and $i plus 1$. For $i lt n$, car $i$
follows car $i plus 1$, observing the variables
$lr((v_i comma v_(i plus 1) comma d_i))$. With a decision period of
1 second, cars act by choosing an acceleration from
$brace.l minus 2 comma 0 comma 2 brace.r$ \[m/s$""^2$\]. Velocities are
capped between $lr([minus 10 semi 20])$ m/s.

#figure([#image("../Graphics/AAMAS25/cars.pdf", width: 0.85*100%)],
  caption: [
    Car platoon example for $n eq 10$ cars.
  ]
)
<fig:platoon>

When two cars have distance 0, they enter an uncontrollable "damaged"
state where both cars get to a standstill. The global safety property is
to maintain a safe but bounded distance between all cars, i.e., the set
of safe states is
$phi.alt eq brace.l s divides and.big_i 0 lt d_i lt 200 brace.r$.

As a first attempt, we design the agents’ individual safety properties
to only maintain a safe distance to the car in front, i.e.,
$phi.alt_i eq brace.l s divides 0 lt d_i lt 200 brace.r$ for all $i$.
However, safe agent shields for cars $i gt 1$ do not exist for this
property: car $i$ cannot prevent a crash with car $i minus 1$ (behind),
and in the "damaged" (halting) state car $i$ cannot guarantee to avoid
crashing with car $i plus 1$. Note that making the distance
$d_(i minus 1)$ observable for car $i$ does not help.

To overcome this seemingly impossible situation, we will allow car $i$
to #emph[assume] that the (unobservable) car $i minus 1$
#emph[guarantees] to never crash into car $i$. This guarantee will be
provided by the shield of car $i minus 1$ and eliminates the critical
behaviour preventing a local shield for car $i$. In that way, we
iteratively obtain local shields for all agents. Note that this
coincides with human driver reasoning.

Beside synthesis of a distributed shield, we also study learning
policies for shielded agents. In general, multi-agent reinforcement
learning (MARL) #cite(label("DBLP:journals/corr/ZhangYB19")) is complex due to
high-dimensional state and action spaces, which impede convergence to
optimal policies.

Here, we identify a class of systems where learning the agents in a
#emph[cascading] way is both effective and efficient. Concretely, if we
assign an index to each agent, and each agent only depends on agents
with lower index, we can learn policies in a sequential order. This
leads to a low-dimensional space for the learning algorithm, which leads
to fast convergence. While in general suboptimal, we show that this
approach still leads to Pareto-optimal results.

In summary, this paper makes the following main contributions:

- We propose #emph[distributed shielding], the first MA shielding
  approach with absolute safety guarantees and scalability, yet without
  online communication. To this end, our approach integrates shield
  synthesis and assume-guarantee reasoning.

- We propose (shielded) #emph[cascading learning], a scalable MARL
  approach for systems with acyclic dependency structure, which further
  benefits from assume-guarantee reasoning.

- We evaluate our approaches in two case studies. First, we demonstrate
  that distributed shielding is scalable and, thanks to the integration
  of assume-guarantee reasoning, applicable. Second, we demonstrate that
  shielded cascading learning is efficient and achieves state-of-the-art
  performance.

=== Related Work
<related-work>
==== Shielding.
<shielding.>
As mentioned, shielding is a technique that computes a #emph[shield],
which prevents an agent from taking unsafe actions. Thus, any policy
under a shield is safe, which makes it attractive for safety both during
learning and after deployment. Shields are typically based on
game-theoretic results, where they are called #emph[winning
strategies] #cite(label("DBLP:reference/mc/BloemCJ18")). Early applications of
shields in learning were proposed for timed
systems #cite(label("DBLP:conf/atva/DavidJLLLST14")) and discrete
systems @AlshiekhBEKNT18. The idea has since been
extended to probabilistic
systems #cite(label("DBLP:conf/concur/0001KJSB20")) #cite(label("DBLP:conf/ijcai/YangMRR23")),
partial observability #cite(label("DBLP:conf/aaai/Carr0JT23")), and
continuous-time
dynamics #cite(label("PaperA")) #cite(label("PaperB")).
For more background we refer to
surveys #cite(label("DBLP:conf/birthday/KonighoferBEP22")) #cite(label("DBLP:journals/tmlr/KrasowskiTM0WA23")).
In this work, we focus on discrete but multi-agent systems, which we now
review in detail.

==== Multi-agent shielding.
<multi-agent-shielding.>
An early work on multi-agent enforcement considered a very restricted
setting with deterministic environments where the specification is
already given in terms of valid actions and not in terms of
states #cite(label("DBLP:conf/amcc/BharadwajBDKT19")). Thus, the shield does
not reason about the dynamics and simply overrides forbidden actions.

Model-predictive shielding assumes a backup policy together with a set
of recoverable states from which this policy can guarantee safety. Such
a backup policy may for instance be implemented by a shield, and is
combined with another (typically learned) policy. First, a step with the
second policy is simulated and, when the target state is recoverable,
this step is executed; otherwise, the fallback policy is executed.
Crucially, this assumes that the environment is deterministic. Zhang et
al. proposed a multi-agent version #cite(label("DBLP:journals/corr/ZhangB19")),
where the key insight is that only some agents need to use the backup
policy. For scalability, the authors propose a greedy algorithm to
identify a sufficiently small subset of agents. However, the "shield" is
centralized, which makes this approach not scalable.

Another work computes a safe policy online #cite(label("RajuBDT21")), which may
be slow. Agents in close proximity create a communication group, and
they communicate their planned trajectories for the next $k$ steps. Each
agent has an agreed-on priority in which they have to resolve safety
violations, but if that is not possible, agents may disturb
higher-priority agents. The approach requires strong assumptions like
deterministic system dynamics and immediate communication.

One work suggests to directly reinforcement-learn policies by simply
encouraging safety #cite(label("DBLP:conf/iclr/QinZCCF21")). Here, the loss
function encodes a safety proof called #emph[barrier certificate]. But,
as with any reward engineering, this approach does not guarantee safety
in any way.

Another way to scale up shielding for multi-agent systems is a so-called
#emph[factored shield], which safeguards only a subset of the state
space, independent of the number of
agents #cite(label("DBLP:conf/atal/Elsayed-AlyBAET21")). When an agent moves,
it joins or leaves a shield at border states. However, this approach
relies on very few agents ever interacting with each other, as
otherwise, there is no significant scalability gain.

Factored shields were extended to #emph[dynamic
shields] #cite(label("DBLP:conf/atal/XiaoLD23")). The idea is that, in order to
reduce the communication overhead, an agent’s shield should "merge"
dynamically with the shields of other agents in the proximity. Since the
shields are computed with a $k$-step lookahead only, safety is not
guaranteed invariantly.

==== Multi-agent verification.
<multi-agent-verification.>
#emph[Rational verification] proposes to study specifications only from
initial states in Nash equilibria, i.e., assuming that all agents act
completely rationally #cite(label("DBLP:journals/apin/AbateGHHKNPSW21")). While
that assumption may be useful for rational/optimal agents, we typically
have learned agents in mind, which do not always act optimally.

The tool #emph[Verse] lets users specify multi-agent scenarios in a
Python dialect and provides black-box (simulations) and white-box
(formal proofs; our setting) analysis for time-bounded
specifications #cite(label("DBLP:conf/cav/LiZBSM23")).

Assume-guarantee reasoning has been applied to multi-agent systems
in #cite(label("DBLP:conf/amcc/PartoviL14")) and
in #cite(label("DBLP:conf/prima/MikulskiJK22")), but not yet to (multi-agent)
shielding.

==== Outline.
<outline.>
In the next section, we define basic notation. In
@sect:shielding, we introduce distributed shielding
based on projections and extend it with assume-guarantee reasoning. In
@sect:learning, we develop cascading learning,
tailored to systems with acyclic dependencies. In
@sect:evaluation, we evaluate our approaches in two
case studies. In @sect:conclusion, we conclude and
discuss future work.

== Preliminaries
<sect:preliminaries>

=== Transition Systems (MDPs & LTSs)
<transition-systems-mdps-ltss>
We start with some basic definitions of transition systems.

#definition(name:"Labeled transition system")[A #emph[labeled
  transition system] (LTS) is a triple
  $cal(T) eq lr((italic(S) comma italic(A c t) comma italic(T)))$ where
  $italic(S)$ is the finite state space, $italic(A c t)$ is the action
  space, and
  $italic(T) subset.eq italic(S) times italic(A c t) times italic(S)$ is
  the transition relation with no dead ends, i.e., for all
  $s in italic(S)$ there exists some $a in italic(A c t)$ and
  $s prime in italic(S)$ such that
  $lr((s comma a comma s prime)) in italic(T)$.
]

#definition(name: "Markov decision process")[A #emph[Markov decision
  process] (MDP) is a triple
  $cal(M) eq lr((italic(S) comma italic(A c t) comma P))$ where
  $italic(S)$ is the finite state space, $italic(A c t)$ is the action
  space, and
  $P colon italic(S) times italic(A c t) times italic(S) arrow.r lr([0 comma 1])$
  is the probabilistic transition relation satisfying
  $sum_(s prime in italic(S)) P lr((s comma a comma s prime)) in brace.l 0 comma 1 brace.r$
  for all $s in italic(S)$ and $a in italic(A c t)$, and for at least one
  action, the sum is 1.
]

We will view an LTS as an abstraction of an MDP where probabilities are
replaced by possibilities.

#definition(name: "Induced LTS")[Given an MDP
  $cal(M) eq lr((italic(S) comma italic(A c t) comma P))$, the
  #emph[induced LTS] is
  $cal(T)_(cal(M)) eq lr((italic(S) comma italic(A c t) comma italic(T)))$
  with $lr((s comma a comma s prime)) in italic(T)$ iff
  $P lr((s comma a comma s prime)) gt 0$.
]

#definition(name: "Run")[Assume an LTS
  $cal(T) eq lr((italic(S) comma italic(A c t) comma italic(T)))$ and a
  finite alternating sequence of states and actions
  $rho eq s_0 a_0 s_1 a_1 dots.h$; then, $rho$ is a #emph[run] of $cal(T)$
  if $lr((s_i comma a_i comma s_(i plus 1))) in italic(T)$ for all
  $i gt.eq 0$. Similarly, for an MDP
  $cal(M) eq lr((italic(S) comma italic(A c t) comma P))$, $rho$ is a
  #emph[run] of $cal(M)$ if
  $P lr((s_i comma a_i comma s_(i plus 1))) gt 0$ for all $i gt.eq 0$.
]

We distinguish between strategies and policies in this work. A strategy
prescribes a nondeterministic choice of actions in each LTS state.
Similarly, a policy prescribes a probabilistic choice of actions in each
MDP state. Before defining them formally, we need a notion of
restricting the actions to sensible choices.

#definition(name: "Enabled actions")[Given an LTS,
  $cal(E) lr((s)) eq brace.l a in italic(A c t) divides exists s prime colon lr((s comma a comma s prime)) in italic(T) brace.r$
  denotes the #emph[enabled actions] in state $s$. Similarly, given an
  MDP,
  $cal(E) lr((s)) eq brace.l a in italic(A c t) divides exists s prime colon P lr((s comma a comma s prime)) gt 0 brace.r$.
]

#definition(name: "Strategy; policy")[Given an LTS, a
  (nondeterministic) #emph[strategy] is a function
  $sigma colon italic(S) arrow.r 2^(italic(A c t))$ such that
  $nothing eq.not sigma lr((s)) subset.eq cal(E) lr((s))$ for all
  $s in italic(S)$. Given an MDP, a (probabilistic) #emph[policy] is a
  function
  $pi colon italic(S) times italic(A c t) arrow.r lr([0 comma 1])$ such
  that $sum_(a in cal(E) lr((s))) pi lr((s comma a)) eq 1$ and
  $and.big_(a prime in italic(A c t) backslash cal(E) lr((s))) pi lr((s comma a prime)) eq 0$
  for all $s in italic(S)$.
]

Note that our strategies and policies are memoryless. This is justified
as we will only consider safety properties in this work, for which
memory is not required #cite(label("DBLP:reference/mc/BloemCJ18")). Strategies
and policies restrict the possible runs, and we call these runs the
outcomes.

#definition(name: "Outcome")[A run $rho eq s_0 a_0 s_1 a_1 dots.h$
  of an LTS is an #emph[outcome] of a strategy $sigma$ if
  $a_i in sigma lr((s_i))$ for all $i gt.eq 0$. Similarly, a run
  $rho eq s_0 a_0 s_1 a_1 dots.h$ of an MDP is an outcome of a policy $pi$
  if $pi lr((s_i comma a_i)) gt 0$ for all $i gt.eq 0$.
]

=== Safety and Shielding
<safety-and-shielding>
In this work, we are interested in safety properties, which are
characterized by a set of safe (resp. unsafe) states. The goal is to
stay in the safe (resp. avoid the unsafe) states. In this section, we
introduce corresponding notions, in particular (classical) shields and
how they can be applied.

#definition(name: "Safety property")[A #emph[safety property] is a
  set of states $phi.alt subset.eq italic(S)$.
]

#definition(name: "Safe run")[Given a safety property
  $phi.alt subset.eq italic(S)$, a run $s_0 a_0 s_1 a_1 dots.h$ is
  #emph[safe] if $s_i in phi.alt$ for all $i gt.eq 0$.
]

Given an LTS, a safety property $phi.alt subset.eq italic(S)$ partitions
the states into two sets: the #emph[winning states], from which a
strategy exists whose outcomes are all safe, and the complement. The
latter can be computed as the attractor set of the
complement $italic(S) backslash phi.alt$ #cite(label("DBLP:reference/mc/BloemCJ18")).
Since it is hopeless to ensure safe behavior from the complement states,
in the following we will only be interested in outcomes starting in
winning states, which we abstain from mentioning explicitly.

A shield is a (typically nondeterministic) strategy that ensures safety.
In game-theory terms, a shield is called a #emph[winning strategy].

#definition(name: "Shield")[Given an LTS
  $lr((italic(S) comma italic(A c t) comma italic(T)))$ and a safety
  property $phi.alt subset.eq italic(S)$, a #emph[shield]
  $shield lr([phi.alt])$ is a strategy whose outcomes starting in any
  winning state are all safe wrt. $phi.alt$.
]

We often omit $phi.alt$ and just write $shield$. Among all shields, it is
known that there is a "best" one that allows the most actions.

#definition(name: "Most permissive shield")[Given an LTS and a
safety property $phi.alt$, the #emph[most permissive shield]
$shield^ast.basic lr([phi.alt])$ is the shield that allows the largest
set of actions for each state $s in italic(S)$.
]

#lemma(name: cite(label("DBLP:reference/mc/BloemCJ18")))[
  $shield^ast.basic$ is unique and obtained as the union of all
  shields $shield$ for $phi.alt$:
  $shield^ast.basic lr((s)) eq brace.l a in italic(A c t) divides exists shield colon a in shield lr((s)) brace.r$.
]

The standard usage of a shield is to restrict the actions of a policy
for guaranteeing safety. In this work, we also compose it with another
strategy. For that, we introduce the notion of composition of strategies
(recall that a shield is also a strategy). We can, however, only compose
strategies that are compatible in the sense that they allow at least one
common action in each state (otherwise the result is not a strategy
according to our definition).

#definition(name: "Composition")[Two strategies $sigma_1$
  and $sigma_2$ over an LTS
  $lr((italic(S) comma italic(A c t) comma italic(T)))$ are
  #emph[compatible] if
  $sigma_1 lr((s)) inter sigma_2 lr((s)) eq.not nothing$ for all
  $s in italic(S)$.
]

Given compatible strategies $sigma$ and $sigma prime$, their composition
$sigma inter.sq sigma prime$ is the strategy
$lr((sigma inter.sq sigma prime)) lr((s)) eq sigma lr((s)) inter sigma prime lr((s))$.

We write $inter.sq_(i lt j) #h(0em) sigma_i$ to denote
$sigma_1 inter.sq dots.h inter.sq sigma_(j minus 1)$, and
$inter.sq_i thin sigma_i$ to denote
$sigma_1 inter.sq dots.h inter.sq sigma_n$ when $n$ is clear from the
context.

Given a strategy $sigma$ and a compatible shield $shield$, we also use
the alternative notation of the #emph[shielded
strategy] $shield lr((sigma)) eq sigma inter.sq shield$.

Given a set of states $phi.alt$, we are interested whether an LTS
ensures that we will stay in that set $phi.alt$, independent of the
strategy.

#definition()[Assume an LTS $cal(T)$ and a set of
  states $phi.alt$. We write $cal(T) tack.r.double phi.alt$ if for all
  strategies $sigma$, all corresponding outcomes $s_0 a_0 s_1 a_1 dots.h$
  satisfy $s_i in phi.alt$ for all $i gt.eq 0$.
]

We now use a different view on a shield and apply it to an LTS in order
to "filter out" those actions that are forbidden by the shield.

#definition(name: "Shielded LTS")[Given an LTS
  $cal(T) eq lr((italic(S) comma italic(A c t) comma italic(T)))$, a
  safety property $phi.alt$, and a shield $shield lr([phi.alt])$, the
  #emph[shielded LTS]
  $cal(T)_shield eq lr((italic(S) comma italic(A c t) comma italic(T)_shield))$
  with
  $italic(T)_shield eq brace.l lr((s comma a comma s prime)) in italic(T) divides a in shield lr((s)) brace.r$
  is restricted to transitions whose actions are allowed by the shield.
]

The next proposition asserts that a shielded LTS is safe.

#proposition[Given an LTS $cal(T)$, a safety
property $phi.alt$, and a corresponding shield $shield lr([phi.alt])$,
all outcomes of any strategy for $cal(T)_shield$ are safe.]

In other words, $cal(T)_shield tack.r.double phi.alt$. We analogously
define shielded MDPs.

#definition(name: "Shielded MDP")[Given an MDP
  $cal(M) eq lr((italic(S) comma italic(A c t) comma P))$, a safety
  property $phi.alt$, and a shield $shield$ for $cal(T)_(cal(M))$, the
  #emph[shielded MDP]
  $cal(M)_shield eq lr((italic(S) comma italic(A c t) comma P_shield))$ is
  restricted to transitions with actions allowed by $shield$:
  $P_shield lr((s comma a comma s prime)) eq P lr((s comma a comma s prime))$
  if $a in shield lr((s))$, and
  $P_shield lr((s comma a comma s prime)) eq 0$ otherwise.
]

#proposition[Assume an MDP $cal(M)$, a safety
property $phi.alt$, and a corresponding shield $shield lr([phi.alt])$
for $cal(T)_(cal(M))$. Then all outcomes of any policy for
$cal(M)_shield$ are safe.]

The last proposition explains how standard shielding is applied to learn
safe policies. Given an MDP $cal(M)$, we first compute a shield $shield$
over the induced LTS $cal(T)_(cal(M))$. Then we apply the shield to the
MDP $cal(M)$ to obtain $cal(M)_shield$ and filter unsafe actions. The
shield guarantees that the agent is safe both during and after learning.

From now on we mainly focus on computing shields from an LTS, as the
generalization to MDPs is straightforward.

=== Compositional Systems
<compositional-systems>
Now we turn to compositional systems (LTSs and MDPs) with multiple
agents. We restrict ourselves to $k$-dimensional state
spaces $italic(S)$, i.e., products of variables
$italic(S) eq times.big_i italic(S)_i$. We allow for sharing some of
these variables among the agents by projecting to observation subspaces.
The following is the standard definition of projecting out certain
variables while retaining others. We use the notation that, given an
$n$-vector $v eq lr((v_1 comma dots.h comma v_n))$, $v lr([i])$ denotes
the $i$-th element $v_i$.

#definition(name: "Projection")[A #emph[projection] is a mapping
  $italic(p r j) colon italic(S) arrow.r O$ that maps $k$-dimensional
  vectors $s in italic(S)$ to $j$-dimensional vectors $o in O$, where
  $j lt.eq k$. Formally, $italic(p r j)$ is associated with a sequence of
  $j$ indices $1 lt.eq i_1 lt dots.h lt i_j lt.eq k$ such that
  $italic(p r j) lr((s)) eq lr((s lr([i_1]) comma dots.h comma s lr([i_j])))$.
  Additionally, we define
  $italic(p r j) lr((phi.alt)) eq union.big_(s in phi.alt) brace.l italic(p r j) lr((s)) brace.r$.
]

#definition(name: "Extension")[Given projection
  $italic(p r j) colon italic(S) arrow.r O$, the set of states projected
  to $o$ is the #emph[extension]
  $arrow.t lr((o)) eq brace.l s in italic(S) divides italic(p r j) lr((s)) eq o brace.r$.
]

Later we will also use an alternative projection, which we call
#emph[restricted]. The motivation is that the standard projection above
sometimes retains too many states. The restricted projection instead
only keeps those states such that the extension of the projection
($arrow.t lr((dot.op))$) is contained in the original set. For instance,
for the state space $italic(S) eq brace.l 0 comma 1 brace.r^2$, the set
of states
$phi.alt eq brace.l lr((0 comma 0)) comma lr((0 comma 1)) comma lr((1 comma 0)) brace.r$,
and the one-dimensional projection $italic(p r j) lr((s)) eq s lr([1])$,
we have that $italic(p r j) lr((phi.alt)) eq brace.l 0 comma 1 brace.r$.
The restricted projection removes $1$ as
$lr((1 comma 1)) in.not phi.alt$.

#definition(name: "Restricted projection")[A #emph[restricted
  projection] is a mapping
  $overline(italic(p r j)) colon 2^(italic(S)) arrow.r 2^O$ that maps sets
  of $k$-dimensional vectors $s in italic(S)$ to sets of $j$-dimensional
  vectors $o in O$, where $j lt.eq k$. Formally, $overline(italic(p r j))$
  is associated with a sequence of $j$ indices
  $1 lt.eq i_1 lt dots.h lt i_j lt.eq k$. Let $italic(p r j)$ be the
  corresponding (standard) projection and $phi.alt subset.eq italic(S)$.
  Then
  $overline(italic(p r j)) lr((phi.alt)) eq brace.l o in O divides brace.l s in italic(S) divides italic(p r j) lr((s)) eq o brace.r subset.eq phi.alt brace.r$.
  Again, we define
  $overline(italic(p r j)) lr((phi.alt)) eq union.big_(s in phi.alt) brace.l overline(italic(p r j)) lr((s)) brace.r$.
]

We will apply $overline(italic(p r j))$ only to safety
properties $phi.alt$. The following alternative characterization may
help with the intuition:
$overline(italic(p r j)) lr((phi.alt)) eq overline(italic(p r j) lr((overline(phi.alt)))) eq O backslash italic(p r j) lr((italic(S) backslash phi.alt))$,
where $overline(phi.alt)$ denotes the
complement $italic(S) backslash phi.alt$ (resp. $O backslash phi.alt$)
of a set of states $phi.alt subset.eq italic(S)$ (resp. observations
$phi.alt subset.eq O$).

Crucially, $italic(p r j)$ and $overline(italic(p r j))$ coincide if
$arrow.t lr((italic(p r j) lr((phi.alt)))) eq phi.alt$, i.e., if the
projection of $phi.alt$ preserves correlations. We will later turn our
attention to agent safety properties, where this is commonly the case.

Now we can define a multi-agent LTS and MDP.

#definition(name: [$n$-agent LTS/MDP])[An #emph[$n$-agent LTS]
  $lr((italic(S) comma italic(A c t) comma italic(T)))$ or an
  #emph[$n$-agent MDP] $lr((italic(S) comma italic(A c t) comma P))$ have
  an $n$-dimensional action space
  $italic(A c t) eq italic(A c t)_1 times dots.h times italic(A c t)_n$
  and a family of $n$ projections $italic(p r j)_i$,
  $i eq 1 comma dots.h comma n$. Each #emph[agent] $i$ is associated with
  the projection $italic(p r j)_i colon italic(S) arrow.r O_i$ from
  $italic(S)$ to its #emph[observation space] $O_i$.
]

We note that the observation space introduces partial observability.
Obtaining optimal strategies/policies for partial observability is
difficult and generally requires infinite
memory #cite(label("DBLP:journals/jcss/ChatterjeeCT16")). Since this is
impractical, we restrict ourselves to memoryless strategies/policies.

We can apply the projection function $italic(p r j)$ to obtain a "local"
LTS, modeling partial observability.

#definition(name: "Projected LTS")[For an $n$-agent LTS
  $cal(T) eq lr((italic(S) comma italic(A c t) comma italic(T)))$ and an
  agent $i$ with projection function
  $italic(p r j)_i colon italic(S) arrow.r O_i$, the #emph[projected LTS
  to agent $i$] is
  $cal(T)^i eq lr((O_i comma italic(A c t)_i comma italic(T)_i))$ where
  $italic(A c t)_i eq brace.l a lr([i]) divides a in italic(A c t) brace.r$
  and
  $italic(T)_i eq brace.l lr((italic(p r j)_i lr((s)) comma a lr([i]) comma italic(p r j)_i lr((s)) prime)) divides lr((s comma a comma s prime)) in italic(T) brace.r$.
]

== Distributed Shield Synthesis
<sect:shielding>
We now turn to shielding in a multi-agent setting. The straightforward
approach is to consider the full-dimensional system and compute a global
shield. This has, however, two issues. First, a global shield assumes
communication among the agents, which we generally do not want to
assume. Second, and more importantly, shield computation scales
exponentially in the number of variables.

To address these issues, we instead compute #emph[local] shields, one
for each agent. A local shield still keeps its agent safe. But since we
only consider the agent’s observation space, the shield does not require
communication, and the computation is much cheaper.

=== Projection-Based Shield Synthesis
<projection-based-shield-synthesis>
Rather than enforcing the global safety property, local shields will
enforce agent-specific properties, which we characterize next.

#definition(name: [$n$-agent safety property])[Given an $n$-agent
  LTS or MDP with state space $italic(S)$, a safety property
  $phi.alt subset.eq italic(S)$ is an #emph[$n$-agent safety property] if
  $phi.alt eq inter.big_(i eq 1)^n phi.alt_i$ consists of #emph[agent
  safety properties] $phi.alt_i$ for each agent $i$.
]

Note that we can let $phi.alt_i eq phi.alt$ for all $i$, so this is not
a restriction. But typically we are interested in properties that can be
accurately assessed in the agents’ observation space (i.e.,
$italic(p r j)_i lr((phi.alt_i)) eq overline(italic(p r j))_i lr((phi.alt_i))$).

Next, we define a local shield of an agent, which, like the agent,
operates in the observation space.

#definition(name: "Local shield")[Given an $n$-agent LTS
  $cal(T) eq lr((italic(S) comma italic(A c t) comma italic(T)))$ with
  observation spaces $O_i$ and an $n$-agent safety property
  $phi.alt eq inter.big_(i eq 1)^n phi.alt_i subset.eq italic(S)$, let
  $shield_i colon O_i arrow.r 2^(italic(A c t)_i)$ be a shield
  for $cal(T)^i$ wrt. $overline(italic(p r j))_i lr((phi.alt_i))$, for
  some agent $i in brace.l 1 comma dots.h comma n brace.r$, i.e.,
  $cal(T)^i tack.r.double_(shield_i) overline(italic(p r j))_i lr((phi.alt_i))$.
  We call $shield_i$ a #emph[local shield] of agent $i$.
]

We define an operation to turn a $j$-dimensional (local) shield into a
$k$-dimensional (global) shield. This global shield allows all global
actions whose projections are allowed by the local shield.

#definition(name: "Extended shield")[Assume an $n$-agent LTS
  $cal(T) eq lr((italic(S) comma italic(A c t) comma italic(T)))$ with
  projections $italic(p r j)_i$, an $n$-agent safety property
  $phi.alt eq inter.big_(i eq 1)^n phi.alt_i subset.eq italic(S)$, and a
  corresponding local shield $shield_i$. The #emph[extended
  shield] $arrow.t lr((shield_i))$ is defined as
  $arrow.t lr((shield_i)) lr((s)) eq brace.l a in italic(A c t) divides a lr([i]) in shield_i lr((italic(p r j)_i lr((s)))) brace.r$.
]

The following definition is just syntactic sugar to ease reading.

#definition()[Assume an LTS $cal(T)$, a set of states
  $phi.alt$, and a shield $shield$ for $phi.alt$. We write
  $cal(T) tack.r.double_shield phi.alt$ as an alternative to
  $cal(T)_shield tack.r.double phi.alt$.
]<def:models_shield>

The following lemma says that it is sufficient to have a local shield
ensuring the #emph[restricted] projection
$overline(italic(p r j))_i lr((phi.alt_i))$ of an agent safety
property $phi.alt_i$ in order to guarantee safety of the extended
shield.

#lemma[Assume an $n$-agent LTS $cal(T)$, a safety
  property $phi.alt_i$, and a local shield $shield_i$ such that
  $cal(T)^i tack.r.double_(shield_i) overline(italic(p r j))_i lr((phi.alt_i))$.
  Then $cal(T) tack.r.double_(arrow.t lr((shield_i))) phi.alt_i$.
]<lem:proj>

#proof[The proof is by contraposition. Assume that there is an
  unsafe outcome $rho$ in $cal(T)$ (starting in a winning state) under the
  extended shield $arrow.t lr((shield_i))$, i.e., $rho$ contains a state
  $s in.not phi.alt$. Then the projected run
  $italic(p r j)_i lr((s_0)) thin a lr([i]) thin italic(p r j)_i lr((s_1)) dots.h$
  is an outcome of $cal(T)^i$ under local shield $shield_i$, and
  $italic(p r j)_i lr((s)) in.not overline(italic(p r j))_i lr((phi.alt))$
  by the definition of $overline(italic(p r j))$. This contradicts
  that $shield_i$ is a local shield.
]

The following example shows that the #emph[restricted] projection is
necessary. Consider the LTS $cal(T)$ where
$italic(S) eq brace.l 0 comma 1 brace.r^2$,
$italic(A c t) eq brace.l z comma p brace.r^2$, and
$italic(T) eq brace.l$
$lr((lr((0 comma 0)) comma lr((z comma z)) comma lr((0 comma 0)))) comma$
$lr((lr((0 comma 0)) comma lr((z comma p)) comma lr((0 comma 1)))) comma$
$lr((lr((0 comma 0)) comma lr((p comma z)) comma lr((1 comma 0)))) comma$
$lr((lr((0 comma 0)) comma lr((p comma p)) comma lr((1 comma 1))))$
$brace.r$. For $i eq 1 comma 2$ let
$phi.alt_i eq brace.l lr((0 comma 0)) comma lr((0 comma 1)) comma lr((1 comma 0)) brace.r$
and $italic(p r j)_i$ project to the $i$-th component $O_i$. Then
$italic(p r j)_i lr((phi.alt_i)) eq brace.l 0 comma 1 brace.r eq italic(p r j)_i lr((italic(S)))$,
i.e., all states in the projection are safe, and hence a local shield
may allow $shield_i lr((0)) eq brace.l z comma p brace.r$. But then the
unsafe state $lr((1 comma 1))$ would be reachable in $cal(T)$.

If $shield eq inter.sq_i thin arrow.t lr((shield_i))$ exists, we call it a
#emph[distributed shield]. This terminology is justified in the next
theorem, which says that we can synthesize $n$ local shields in the
projections and then combine these local shields to obtain a safe shield
for the global system.

#theorem(name: "Projection-based shield synthesis")[Assume an
  $n$-agent LTS
  $cal(T) eq lr((italic(S) comma italic(A c t) comma italic(T)))$ and an
  $n$-agent safety property
  $phi.alt eq inter.big_(i eq 1)^n phi.alt_i subset.eq italic(S)$.
  Moreover, assume local shields $shield_i$ for all
  $i eq 1 comma dots.h comma n$. If
  $shield eq inter.sq_i thin arrow.t lr((shield_i))$ exists, then $shield$ is
  a shield for $cal(T)$ wrt. $phi.alt$ (i.e.,
  $cal(T)_shield tack.r.double phi.alt$).
]<thm:shield_simple>

#proof[By definition, each local shield $shield_i$ ensures that
  the (#emph[restricted] projected) agent safety property $phi.alt_i$
  holds in $cal(T)^i$. Since $cal(T)^i$ is a projection of $cal(T)$, any
  distributed shield with $i$-th component $shield_i$ also preserves
  $phi.alt_i$ in $cal(T)$ (by @lem:proj). Hence,
  $shield eq inter.sq_i thin arrow.t lr((shield_i))$ ensures all agent safety
  properties $phi.alt_i$ and thus
  $phi.alt eq inter.big_(i eq 1)^n phi.alt_i$.
]

Unfortunately, the theorem is often not useful in practice because the
local shields may not exist. The projection generally removes the
possibility to coordinate with other agents. By #emph[coordination] we
do not mean (online) communication but simply (offline) agreement on
"who does what." Often, this coordination is necessary to achieve agent
safety. We address this lack of coordination in the next section.

=== Assume-Guarantee Shield Synthesis
<assume-guarantee-shield-synthesis>
Shielding an LTS removes some transitions. Thus, by repeatedly applying
multiple shields to the same LTS, we obtain a sequence of more and more
restricted LTSs.

#definition(name: "Restricted LTS")[Assume two LTSs
  $cal(T) eq lr((italic(S) comma italic(A c t) comma italic(T)))$,
  $cal(T) prime eq lr((italic(S) comma italic(A c t) comma italic(T) prime))$.
  We write $cal(T) prec.eq cal(T) prime$ if
  $italic(T) subset.eq italic(T) prime$.
]

#lemma[Let $cal(T) prec.eq cal(T) prime$ be two LTSs. Then
  $cal(T) prime tack.r.double phi.alt arrow.r.double.long cal(T) tack.r.double phi.alt$.
]<lem:preceq>
#proof[As $italic(T) prime$ contains all transitions of
  $italic(T)$, it has at least the same outcomes. If no outcome
  of $cal(T) prime$ leaves $phi.alt$, the same holds for $cal(T)$.
]

We now turn to the main contribution of this section. For a safety
property $phi.alt prime$, we assume an $n$-agent safety property
$phi.alt eq inter.big_(i eq 1)^n phi.alt_i$ is given such that
$phi.alt subset.eq phi.alt prime$ (i.e., $phi.alt$ is more restrictive).
We use these agent safety properties $phi.alt_i$ to filter out behavior
during shield synthesis. They may contain additional guarantees, which
are used to coordinate responsibilities between agents.

Crucially, in our work, the guarantees are given in a certain order. We
assume #emph[wlog] that the agent indices are ordered from 1 to $n$ such
that agent $i$ can only rely on the safety properties of all
agents $j lt i$. Thus, agent $i$ guarantees $phi.alt_i$ by assuming
$inter.big_(j lt i) phi.alt_j$. This is important to avoid problems with
(generally unsound) circular reasoning. In particular, agent $1$ cannot
rely on anything, and $phi.alt_n$ is not relied on.

The theorem then states that if each agent guarantees its safety
property $phi.alt_i$, and only relies on guarantees $phi.alt_j$ such
that $j lt i$. The result is a (safe) distributed shield. The described
condition is formally expressed as
$lr((cal(T)_(shield^ast.basic lr([inter.big_(j lt i) phi.alt_j]))))^i tack.r.double_(shield_i) overline(italic(p r j))_i lr((phi.alt_i))$,
where we use the most permissive shield $shield^ast.basic$ for unicity.

#theorem(name: [Assume-guarantee shield synthesis])[Assume an
  $n$-agent LTS
  $cal(T) eq lr((italic(S) comma italic(A c t) comma italic(T)))$ with
  projections $italic(p r j)_i$ and an $n$-agent safety property
  $phi.alt eq inter.big_i phi.alt_i$. Moreover, assume (local) shields
  $shield_i$ for all $i$ such that
  $lr((cal(T)_(shield^ast.basic lr([inter.big_(j lt i) phi.alt_j]))))^i tack.r.double_(shield_i) overline(italic(p r j))_i lr((phi.alt_i))$.
  Then, if $shield eq inter.sq_i thin arrow.t lr((shield_i))$ exists, it is a
  shield for $cal(T)$ wrt. $phi.alt$ (i.e.,
  $cal(T)_shield tack.r.double phi.alt$).
]<thm:shield_agr>

#proof[Assume $cal(T)$, $phi.alt$, and local shields $shield_i$ as
  in the assumptions. Observe that for $i eq 1$,
  $inter.big_(j lt i) phi.alt_i eq italic(S)$, and that
  $cal(T)_(shield^ast.basic lr([italic(S)])) eq cal(T)$. Then:
  
  $  
    & and.big_i lr((cal(T)_(shield^* lr([inter.big_(j < i) phi.alt_j]))))^i tack.r.double_(shield_i) overline(italic(p r j))_i lr((phi.alt_i))\

    ==>^#ref(<lem:proj>, supplement: [Lem.]) 
       & and.big_i cal(T)_(shield^* lr([inter.big_(j < i) phi.alt_j])) tack.r.double_(arrow.t lr((shield_i))) phi.alt_i 

    ==>^(lr((ast.basic))) and.big_i cal(T)_(inter.sq_(j < i) arrow.t lr((shield_j))) tack.r.double_(arrow.t lr((shield_i))) phi.alt_i\
    
    ==>^#ref(<def:models_shield>, supplement: [Def. ]) 
      & and.big_i cal(T) tack.r.double_(inter.sq_(j <= i) arrow.t lr((shield_j))) phi.alt_i 

    ==> cal(T) tack.r.double_(inter.sq_i thin arrow.t lr((shield_i))) phi.alt 
    ==>^#ref(<def:models_shield>, supplement: [Def. ]) 
      cal(T)_shield tack.r.double phi.alt 

  $

  Step $lr((ast.basic))$ holds because the composition
  $inter.sq_(j lt.eq i) arrow.t lr((shield_j))$ of the local shields up to
  index $i$ satisfy $phi.alt_i$ under the previous guarantees $phi.alt_j$,
  $j lt i$. Thus,
  $cal(T)_(inter.sq_(j lt i) arrow.t lr((shield_j))) prec.eq cal(T)_(shield^* lr([inter.big_(j lt i) phi.alt_j]))$,
  and the conclusion follows by applying @lem:preceq.
]

Finding the local safety properties $phi.alt_i$ is an art, and we leave
algorithmic synthesis of these properties to future work. But we will
show in our case studies that natural choices often exist, sometimes
directly obtained from the (global) safety property.

== Cascading Learning
<sect:learning>
In the previous section, we have seen how to efficiently compute a
distributed shield based on assume-guarantee reasoning. In this section,
we turn to the question how and under which condition we can efficiently
learn multi-agent policies in a similar manner.

We start by defining the multi-agent learning objective.

#definition(name: [$n$-agent cost function])[Given an $n$-agent MDP
  $cal(M) eq lr((italic(S) comma italic(A c t) comma P))$ with
  projections $italic(p r j)_i colon italic(S) arrow.r O_i$, an
  #emph[$n$-agent cost function] $c eq lr((c_1 comma dots.h comma c_n))$
  consists of (local) cost functions
  $c_i colon O_i times italic(A c t)_i arrow.r bb(R)$. The total immediate
  cost $c colon italic(S) times italic(A c t) arrow.r bb(R)$ is
  $c lr((s comma a)) eq sum_(i eq 1)^n c_i lr((italic(p r j)_i lr((s)) comma a lr([i])))$
  for $s in italic(S)$ and $a in italic(A c t)$.
]

An agent policy is obtained by projection, analogous to a local shield.
Next, we define the notion of instantiating an $n$-agent MDP with a
policy, yielding an $lr((n minus 1))$-agent MDP.

#definition(name: "Instantiating an agent")[Given an $n$-agent MDP
  $cal(M) eq lr((italic(S) comma italic(A c t) comma P))$ and agent policy
  $pi colon O_i times italic(A c t)_i arrow.r lr([0 comma 1])$, the
  #emph[instantiated MDP] is
  $cal(M)_pi eq lr((italic(S) comma italic(A c t) prime comma P prime))$,
  where
  $italic(A c t) prime eq italic(A c t)_1 times dots.h times italic(A c t)_(i minus 1) times italic(A c t)_(i plus 1) times dots.h times italic(A c t)_n$
  and, for all $s comma s prime in italic(S)$ and
  $a prime in italic(A c t) prime$,
  $P prime lr((s, a', s')) eq sum_(a_i) #h(-0.1em) pi lr((italic(p r j)_i lr((s)), a_i)) dot.op P lr((s, lr((a' lr([1]), dots.h, a' lr([i minus 1]), a_i, a' lr([i]), dots.h, a' lr([n minus 1]))), s'))$.
]

We will need the concept of a projected, local run of an agent.

#definition(name: "Local run")[Given a run
  $rho eq s_0 a_0 s_1 a_1 dots.h$ over an $n$-agent MDP
  $lr((italic(S) comma italic(A c t) comma P))$, the projection to
  agent $i$ is the #emph[local run]
  $italic(p r j)_i lr((rho)) eq italic(p r j)_i lr((s_0)) thin a_0 lr([i]) thin italic(p r j)_i lr((s_1)) thin a_1 lr([i]) dots.h$
]

Given a
policy $pi colon italic(S) times italic(A c t) arrow.r lr([0 comma 1])$,
the probability of a finite local run $italic(p r j)_i lr((rho))$ being
an outcome of $pi$ is the sum of the probabilities of outcomes of $pi$
whose projection to $i$ is $italic(p r j)_i lr((rho))$.

The probability of a run $rho$ of length $ell$ being an outcome of
policy $pi$ is
$italic(P r) lr((rho divides pi)) eq product_(i eq 0) pi lr((s_i comma a_i)) dot.op P lr((s_i comma a_i comma s_(i plus 1)))$.
We say that agent $i$ depends on agent $j$ if agent $j$’s action choice
influences the probability for agent $i$ to observe a (local) run.

#definition(name: "Dependency")[Given an $n$-agent MDP
  $lr((italic(S) comma italic(A c t) comma P))$, agent $i$ #emph[depends]
  on agent $j$ if there exists a local run $italic(p r j)_i lr((rho))$ of
  length $ell$ and $n$-agent policies $pi comma pi prime$ that differ only
  in the $j$-th agent policy, i.e.,
  $pi eq lr((pi_1 comma dots.h comma pi_n))$ and
  $pi prime eq lr((pi_1 comma dots.h comma pi_(j minus 1) comma pi_j prime comma pi_(j plus 1) comma dots.h comma pi_n))$,
  such that the probability of observing $italic(p r j)_i lr((rho))$
  under $pi$ and $pi prime$ differ:
  $ sum_(rho prime colon italic(p r j)_i lr((rho prime)) eq italic(p r j)_i lr((rho))) italic(P r) lr((rho prime divides pi)) eq.not sum_(rho prime colon italic(p r j)_i lr((rho prime)) eq italic(p r j)_i lr((rho))) italic(P r) lr((rho prime divides pi prime)) $
  where we sum over all runs $rho prime$ of length $ell$ with the same
  projection.
]

In practice, we can typically perform an equivalent syntactic check.
Next, we show how to arrange dependencies in a graph.

#definition(name: "Dependency graph")[The #emph[dependency graph]
  of an $n$-agent MDP is a directed graph $lr((V comma E))$ where
  $V eq brace.l 1 comma dots.h comma n brace.r$ and
  $E eq brace.l lr((i comma j)) divides i upright(" depends on ") j brace.r$.
]

As the main contribution of this section,
@algo:learn shows an efficient
multi-agent learning framework, which we call #emph[cascading learning].
In order to apply the algorithm, we require an acyclic dependency graph
(otherwise, an error is thrown in
@line:error). Then, we train the agents in
the order suggested by the dependencies, which, as we will see, leads to
an attractive property.

#figure(kind: "algorithm", supplement: [Algorithm], 
  pseudocode-list(numbered-title: [Cascading shielded learning of $n$-agent policies])[
    - *Input:* Shielded $n$-agent MDP $cal(M)_shield$,  $n$-agent cost function $c = (c_1, dots, c_n)$
    - *Output:* $n$-agent policy $(pi_1, dots, pi_n)$
    + Build dependency graph $G$ of $cal(M)_shield$;
    + Let $cal(M)' := cal(M)_shield$;
    + *while* (true)
      + *if* there is no node in $G$ with no outgoing edges
        + #line-label(<line:error>) error("Cyclic dependencies are incompatible."); 
      + Let $i$ be a node in $G$ with no outgoing edges;
      + #line-label(<line:learn>) Train agent policy~$pi_i$ on the MDP $"sandbox"(cal(M)', i)$ wrt. cost function $c_i$; 
      + Update $G$ by removing node $i$ and all incoming edges;
      + *if* $G$ is empty
        + *return* $(pi_1, dots, pi_n)$
      + Update $cal(M)' := cal(M)'_{pi_i}$ #h(1fr) $triangle.r.small$ I.e., instantiated shielded MDP
  ]
)<algo:learn>


To draw the connection to the distributed shield, the crucial insight is
that we can again use it for assume-guarantee reasoning to prevent
behaviors that may otherwise create a dependency.

The procedure $italic(s a n d b o x) lr((cal(M) comma i))$ in
@line:learn takes an $n$-agent MDP $cal(M)$
and an agent index $i in brace.l 1 comma dots.h comma n brace.r$. The
purpose is to instantiate every agent except agent $i$. Since agent $i$
does not depend on these agents, we arbitrary choose a uniform policy
for the instantiation.

Next, we show an important property of
@algo:learn: it trains policies
in-distribution.

#definition(name: "In-distribution")[Given two $1$-agent MDPs
  $cal(M) eq lr((italic(S) comma italic(A c t) comma P))$ and
  $cal(M) prime eq lr((italic(S) comma italic(A c t) comma P prime))$, an
  agent policy $pi$ is #emph[in-distribution] if the probability of any
  local run in $cal(M)$ is the same as in $cal(M) prime$.
]

Now we show that the distribution of observations an agent policy $pi_i$
makes during training in @algo:learn
is identical with the distribution of observations made
in $cal(M)^ast.basic$, the instantiation with #emph[all other] agent
policies computed by @algo:learn.

#theorem[Let $cal(M)$ be an $n$-agent MDP with acyclic
  dependency graph. For every agent $i$, the following holds. Let
  $cal(M)^ast.basic$ be the $1$-agent MDP obtained by iteratively
  instantiating the original MDP $cal(M)$ with policies $pi_j$ for all
  $j eq.not i$. The agent policy $pi_i$ trained with
  @algo:learn is in-distribution
  wrt. $italic(s a n d b o x) lr((cal(M) prime comma i))$ (from
  @line:learn) and $cal(M)^ast.basic$.
]

#proof[Fix a policy $pi_i$. If $pi_i$ is the last trained policy,
  the statement clearly holds. Otherwise, let $pi_j eq.not pi_i$ be a
  policy that has not been trained at the time when $pi_i$ is trained. The
  algorithm asserts that $pi_i$ has no dependency on $pi_j$. Thus,
  training $pi_i$ yields the same policy no matter how $pi_j$ behaves.
]

Note that, despite trained in-distribution, the policies are not
globally optimal. This is because each policy acts egoistically and
optimizes its local cost, which may yield suboptimal global cost.

What we can show is that the agent policies
$lr((pi_1 comma dots.h comma pi_n))$ are #emph[Pareto
optimal] #cite(label("marl-book")), i.e., they cannot all be strictly improved
without raising the cost of at least one agent. That is, there is no
policy $pi_i$ that can be replaced by another policy $pi_i prime$
without strictly increasing the expected local cost of at least one
agent. Indeed:

#theorem[If the learning method in
  @line:learn of
  @algo:learn converged to the (local)
  optima, and these optima are unique, then the resulting policies are
  Pareto optimal.
]

#proof[The proof is by induction. Assume #emph[wlog] that the
  policies are trained in the order 1 to $n$. By assumption, $pi_1$ is
  locally optimal and unique. Hence, replacing $pi_1$ by another policy
  would strictly increase its total cost. Now assume we have shown the
  claim for the first $i minus 1$ agents.
  @algo:learn trained policy $pi_i$
  wrt. the instantiation with the
  policies $pi_1 comma dots.h comma pi_(i minus 1)$, and by assumption,
  $pi_i$ is also locally optimal and unique. Thus, again, we cannot
  replace $pi_i$.
]

== Evaluation
<sect:evaluation>
We consider two environments with discretized state spaces.
#footnote[Available online at
#link("https://github.com/AsgerHB/N-player-shield").] All experiments
were repeated 10 times; solid lines in plots represent the mean cost of
these 10 repetitions, while ribbons mark the minimum and maximum costs.
Costs are evaluated as the mean of $1 comma 000$ episodes. We use the
learning method implemented in #smallcaps[Uppaal
Stratego] #cite(label("DBLP:conf/atva/JaegerJLLST19")) because the
implementation has a native interface for shields. This method learns a
policy by partition refinement of the state space. With this learning
method, only few episodes are needed for convergence. We also compare to
the (deep) MARL approach MAPPO #cite(label("DBLP:conf/nips/YuVVGWBW22")) later.

=== Car Platoon with Adaptive Cruise Controls
<car-platoon-with-adaptive-cruise-controls>
Recall the car platoon model from
@sect:platoon. The front car follows a random
distribution depending on $v_n$ (described in #cite(label("PaperC_arxiv")), appendix).

The individual cost of an agent is the sum of the observed distances to
the car immediately in front of it, during a 100-second episode (i.e.,
keeping a smaller distance to the car in front is better).

The decision period causes delayed reaction time, and so the minimum
safe distance to the car in front depends on the velocity of both cars.
An agent must learn to drive up to this distance, and then maintain it
by predicting the acceleration of the car in front.

For this model, all agents share analogous observations $O_i$ and safety
properties $phi.alt_i$. Hence, instead of computing $n minus 1$ local
shields individually, it is sufficient to compute only one local shield
and reuse it across all agents (by simply adapting the variables).

==== Relative scalability of centralized and distributed shielding
<relative-scalability-of-centralized-and-distributed-shielding>
We compare the synthesis of distributed and (non-distributed) classical
shields. We call the latter #emph[centralized] shields, as they reason
about the global state. Hence, they may permit more behavior and
potentially lead to better policies, as the agents can coordinate to
take jointly safe actions. Beside this (often unrealistic) coordination
assumption, a centralized shield suffers from scalability issues. While
the size of a single agent’s observation space is modest, the global
state space is often too large for computing a shield.

We interrupted the synthesis of a centralized shield with $n eq 3$ cars
(i.e., 2 agents) and a full state space after 12 hours, at which point
the computation showed less than 3% progress. In order to obtain a
centralized shield, we reduced the maximum safe distance from 200 to
just 50, shrinking the state space significantly. Synthesizing a
centralized shield took 78 minutes for this property, compared to just 3
seconds for a corresponding distributed shield.

Because of the exponential complexity to synthesize a centralized
shield, we will only consider distributed shields in the following.
Synthesizing a shield for a single agent covering the full safety
property ($0 lt d_i lt 200$) took 6.5 seconds, which we will apply to a
platoon of 10 cars, well out of reach of a centralized shield.

==== Comparing centralized, cascading and MAPPO learning
<comparing-centralized-cascading-and-mappo-learning>
#figure([#image("../Graphics/AAMAS25/CC 400x150.svg", width: 100%)],
  caption: [
    Graph of learning outcomes. Comparison of different learning methods
    on the 10-car platoon. The centralized and the MAPPO policy were
    trained for the total episodes indicated, while these episodes were
    split evenly between each agent in the cascading case.
  ]
)
<fig:cclearning>

Given a distributed shield, we consider the learning outcomes for a
platoon of 10 cars (9 agents), using the learning method of
#smallcaps[Uppaal Stratego]. We train both a shielded #emph[centralized]
policy, which picks a joint action for all cars, and individual shielded
policies using cascading learning
(@algo:learn). As expected from
shielded policies, no safety violations were observed while evaluating
them.

In the results shown in @fig:cclearning, the
centralized policy does not improve with more training. While it could
theoretically outperform distributed policies through communication, the
high dimensionality of the state and action space likely prevents that.
It only marginally improves over the random baseline, which has an
average cost of $71 thin 871$. On the other hand, cascading learning
quickly converges to a much better cost as low as $26 thin 435$.

To examine how cascading learning under a distributed shield compares to
traditional MARL techniques, we implemented the platoon environment in
the benchmark suite BenchMARL #cite(label("DBLP:journals/corr/abs-2312-01472"))
and trained an unshielded policy with
MAPPO #cite(label("DBLP:conf/nips/YuVVGWBW22")), a state-of-the-art MARL
algorithm based on PPO #cite(label("DBLP:journals/corr/SchulmanWDRK17")), using
default hyperparameters. To encourage safe behavior, we added a penalty
of $1 thin 600$ to the cost function for every step upon reaching an
unsafe state. (This value was obtained by starting from $100$ and
doubling it until safety started degrading again.) Recall that shielded
agents are safe.

We include the training outcomes for MAPPO in
@fig:cclearning. Due primarily to the penalty of
safety violations, the agents often have a cost greater than
$100 thin 000$, even at the end of training. However, the best MAPPO
policy achieved a cost of just $16 thin 854$, better than the cascading
learning method. We inspected that policy and found that the cars drive
very closely, accepting the risk of a crash. Overall, there is a large
variance of the MAPPO policies in different runs, whereas cascading
learning converges to very similar policies, and does so much faster.
This is likely because of the smaller space in which the policies are
learned, due to the distributed shield. Thus, cascading learning is more
effective.

#figure([#image("../Graphics/AAMAS25/MAPPO CC Fraction Safe 350x100.svg", width: 0.8*100%)],
  caption: [
    Percentage of safe runs with the MAPPO policy in the 10-car platoon.
    Blue bars show the mean of 10 repetitions, while black intervals
    give min and max values.
  ]
)
<fig:ccmappopercentagesafe>

Since the MAPPO policy is not safe by construction,
@fig:ccmappopercentagesafe shows the percentage of
safe episodes, out of $1 thin 000$ episodes. The agents tend to be
safer with more training, but there is no inherent guarantee of safety,
and a significant amount of violations remain.

=== Chemical Production Plant
<chemical-production-plant>
In the second case study, we demonstrate that distributed shielding
applies to complex dependencies where agents influence multiple other
agents asymmetrically. We consider a network of inter-connected chemical
production units, each with an internal storage.

#figure(image("../Graphics/AAMAS25/cp_layout.svg"),
  caption: [Layout of plant network.]
)<fig:cp_layout>

@fig:cp_layout shows the graph
structure of the network. Numbered nodes (1 to 10) denote controlled
production units, while letter-labeled nodes (A, B) denote uncontrolled
consumers with periodically varying demand. Arrows from source to target
nodes denote potential flow at no incurred cost. Arrows without a source
node denote potential flow from external providers, at a cost that
individually and periodically varies. Consumption patterns and examples
of the cost patterns are shown in the appendix of #cite(label("PaperC_arxiv")). The flow rate in all
arrows follows a uniform random distribution in the range
$lr([2.15 semi 3.15])$ $ell$/s.

Each agent $i$ is associated with a production unit (1 to 10), with
internal storage volume $v_i$. Beside a global periodic timer, each
agent can only observe its own volume. At each decision period of 0.5
seconds, an agent can open or close each of the three input flows (i.e.,
there are $lr(|italic(A c t)_i|) eq 9$ actions per agent and hence
$lr(|italic(A c t)|) eq 9^10$ global actions), but cannot prevent flow
from outgoing connections.

The individual cost of an agent is incurred by buying from external
providers. Agents must learn to take free material from other units,
except for agents 1 to 3, which instead must learn to buy from their
external providers periodically when the cost is low.

Units must not exceed their storage capacity, and units 9 to 10 must
also not run empty to ensure the consumers’ demand is met. That is, the
safety property is
$phi.alt eq brace.l s divides and.big_i v_i lt 50 and 0 lt v_9 and 0 lt v_10 brace.r$.

==== Shielding.
<shielding.-1>
The property $0 lt v_9$ cannot be enforced by a local shield for
agent $9$ without additional assumptions that the other agents do not
run out. This is because the (single) external provider is not enough to
meet the potential (dual) demand of consumer $A$. This yields the local
safety properties
$phi.alt_i eq brace.l s divides 0 lt v_i lt 50 brace.r$. Here, agents 1
to 3 do not make assumptions, while agents 4 and 5 depend on agents 1
to 3 not running out, etc. For this model, we do not use the same shield
for all agents, since they differ in the number of outgoing flows
(either 1 or 2). Still, it is sufficient to compute two types of
shields, one for each variant, and adapt them to analogous agents.
Computing a centralized shield would again be infeasible, while
computing the distributed shield took less than 1 second.

==== Comparing centralized and cascading learning
<comparing-centralized-and-cascading-learning>
#figure([#image("../Graphics/AAMAS25/CP 400x150.svg", width: 100%)],
  caption: [
    Comparison of different learning methods on the chemical production
    plant. The centralized policy was trained for the total episodes
    indicated, while these episodes were split evenly between each agent
    in the cascading case.
  ]
)
<fig:cplearning>

Thanks to the guarantees given by the distributed shields, agents 9
to 10 are only affected by the behavior of the consumers, agents 6 to 8
only depend on agents 9 to 10, etc. Thus, the agent training order is
10, 9, 8 …

We compare the results of shielded cascading learning, shielded
centralized learning, MAPPO, and shielded random agents in
@fig:cplearning. Centralized learning achieved a cost
of $292$. The lowest cost overall, $172$, was achieved by cascading
learning. We compare this to the (unshielded) MAPPO agents, whose lowest
cost was $291$. More background information is given in #cite(label("PaperC_arxiv")).

== Conclusion
<sect:conclusion>
In this paper, we presented distributed shielding as a scalable MA
approach, which we made practically applicable by integrating
assume-guarantee reasoning. We also presented cascading shielded
learning, which, when applicable, is a scalable MARL approach. We
demonstrated that distributed shield synthesis is highly scalable and
that coming up with useful guarantees is reasonably simple.

While we focused on demonstrating the feasibility in this work by
providing the guarantees manually, a natural future direction is to
learn them. As discussed, this is much simpler in the classical
setting #cite(label("DBLP:reference/mc/GiannakopoulouNP18")) because the
agents/components are fixed. We believe that in our setting where both
the guarantees and the agents are not given, a trial-and-error approach
(e.g., a genetic algorithm) is a fruitful direction to explore. Another
relevant future direction is to generalize our approach to continuous
systems #cite(label("PaperA")).

This research was partly supported by the Independent Research Fund
Denmark under reference number 10.46540/3120-00041B, DIREC - Digital
Research Centre Denmark under reference number 9142-0001B, and the
Villum Investigator Grant S4OS under reference number 37819.

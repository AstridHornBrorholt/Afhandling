#import "@preview/lovelace:0.3.1": *
#import "@preview/subpar:0.2.2"
#import "../Config/Macros.typ" : *


// DEBUG: Just print labels so a missing label doesn't error
// #show ref: it => {
//   it.target
// }

= Adaptive Probabilistic Shielding by Learning MDPs for \ Safe Reinforcement Learning <paper:E>

#grid(columns: (1fr, 1fr), row-gutter: 2em, column-gutter: 2em,
  [Astrid~Horn~Brorholt \ #set text(size: 0.8em)
  _Depatrment of Computer Science \ Aalborg University, Aalborg, Denmark_],

  [Maris~F.~L.~Galesloot\ #set text(size: 0.8em)
  _Institute for Computing and Information Sciences \ Radboud University, Nijmegen, Netherlands_],

  [Nils~Jansen\ #set text(size: 0.8em)
  _Institute for Computing and Information Sciences \  Radboud University, Nijmegen, Netherlands\ \
  Faculty of Computer Science \ Ruhr University, Bochum, Germany_],

  [Kim~Guldstrand~Larsen\ #set text(size: 0.8em)
  _Depatrment of Computer Science \ Aalborg University, Aalborg, Denmark_],

  [Christian~Schilling\ #set text(size: 0.8em)
  _Depatrment of Computer Science \ Aalborg University, Aalborg, Denmark_]
)

#v(1fr)

Probabilistic shielding is a technique for safe reinforcement learning (RL). 
Typically, a static observer---called the shield---constrains the learning agent's actions to those for which acting safely remains feasible.
Traditionally, the shield is computed from the transition probabilities of the underlying Markov decision process (MDP).
Thus, this technique is not applicable when the MDP model is not given a priori, which, unfortunately, is the case in typical RL applications. 
In this paper, we study the problem of computing a shield in the setting where the transition graph of the MDP is known, but the transition probabilities are unknown. 
Our approach integrates probabilistic shielding with online model learning: as the RL agent explores the environment, we estimate the transition probabilities.
From this estimate, we compute a shield. 
While the shield may be conservative initially, it adapts as the model estimate becomes more precise. 
Thus, the shield improves in tandem with the RL agent. 
This paradigm of #emph[adaptive probabilistic shielding] raises a number of challenges, such as when to recompute the shield and how to balance between exploration and safety during learning. 
We empirically evaluate multiple variants of this paradigm across several environments. 

// Keywords: #emph[Safe reinforcement learning, Shielding, Model learning, Interval Markov decision process.]

#pagebreak(weak: true)

== Introduction
<introduction>
Markov decision processes (MDPs)  #cl("Puterman94") are the standard
models to capture #emph[decision-making under uncertainty] in artificial
intelligence (AI)  #cl("Kochenderfer15"). Factors such as unknown or
unpredictable environments, contextual changes at runtime, or incomplete
data are commonly referred to as #emph[uncertainty]. Specifically, MDPs
capture settings where agents, in each #emph[state] of their
environment, choose to execute #emph[actions] upon which the environment
#emph[probabilistically transitions] to a new state. Upon that
transition, the agent receives a #emph[reward].

Common objectives for MDPs are to (1) maximize the expected cumulative
reward and (2) adhere to safety constraints specified as temporal logic
constraints  #cl("Pnueli77"). In the past, the first objective was
mostly considered by the AI community, and the latter objective by the
formal verification community. Specifically, reinforcement learning (RL)
is a major AI technique for decision-making under
uncertainty  #cl("DBLP:books/lib/SuttonB2018"). For an unknown MDP, an
RL agent aims to maximize the expected reward by collecting data through
exploration of the environment across multiple episodes. A major
limitation in RL is that during exploration, the agent will necessarily
execute potentially devastatingly unsafe actions. In contrast,
probabilistic model checking (PMC) is a formal verification technique
that computes the probability of satisfying a safety constraint in an
MDP  #cl("BK08"). The key limitation of PMC is that the MDP must be
fully specified.

===== Shielded RL.
<shielded-rl.>
In response to these key limitations, a tremendous body of work has
brought together RL and formal methods in the area of safe
RL  #cl("DBLP:journals/jmlr/GarciaF15"), in particular within shielded
RL  #cl("AlshiekhBEKNT18", "DBLP:conf/atva/DavidJLLLST14").
Specifically, in #emph[probabilistic pre-shielding], PMC is used to
compute a shield that blocks potentially unsafe actions at
runtime  #cl("DBLP:journals/cacm/KonighoferBJJP25", "DBLP:conf/concur/0001KJSB20", "DBLP:conf/cav/HeckMACJ26").
Such #emph[runtime verification approach] renders RL (more) safe during
exploration, yet inherits PMC’s strong assumption that the
(safety-relevant) environment model, that is, the MDP, must be fully
specified. One may be tempted to approach this problem by first
gathering sufficient training data from RL, then using that data to
learn a full MDP model of the environment, and finally computing a
shield from that model. However, safety during the data collection is
not considered, making such an approach hardly applicable in real-world
scenarios.

===== Problem setting.
<problem-setting.>
In this paper, we overcome the aforementioned key real-world limitation
of shielded RL and propose a practical and adaptive approach. To that
end, we impose mild assumptions about the environment in which the RL
agent operates. First, we assume that simulation access to the true
environment MDP is available from the initial state, which is a common
assumption in RL. Second, we assume that the topology, that is, the
underlying graph of the MDP, is known, which is much more realistic than
knowing the exact transition probabilities.

===== Our approach: Safe RL via Adaptive Probabilistic Shielding.
<our-approach-safe-rl-via-adaptive-probabilistic-shielding.>
@fig:flowchart shows an overview of our approach. As usual,
the RL agent executes an action in the (unknown) MDP, yielding a reward
and causing the environment to transition to a new state. A key
component of our approach is a #emph[model estimator], based on
approaches from  #cl("DBLP:conf/nips/SuilenS0022"). While the agent
interacts with the environment, it collects data on the observed states
and actions. From this data, the model estimator then constructs a
#emph[learned] MDP model of the environment. We use the state-of-the-art
PMC tool PRISM  #cl("PRISM") to compute a shield based on this learned
MDP  #cl("DBLP:journals/corr/abs-2605-10293"). At any point
during this process, the shield can be updated #emph[adaptively], and
additional data can be collected under the updated shield.

#figure([#image("../Graphics/RV26/Adaptive-shielding-loop.drawio.pdf")],
  caption: [
    A high-level overview of our adaptive probabilistic shielding
    approach.
  ]
)
<fig:flowchart>

===== Interval MDPs and shields.
<interval-mdps-and-shields.>
An essential part of our approach is to implement and compare estimators
that yield different types of MDP models from moderate amounts of data
collected as a byproduct of the RL process itself. In particular,
following  #cl("DBLP:conf/nips/SuilenS0022", "DBLP:journals/corr/abs-2605-10293"),
we create so-called interval MDPs
(iMDPs)  #cl("DBLP:journals/ior/NilimG05", "DBLP:conf/birthday/SuilenBB0025").
Intuitively, iMDPs capture data uncertainty robustly by defining upper
and lower bounds on transition probabilities, based on, for instance,
confidence intervals around point estimates of those probabilities.
Then, PMC can provide upper and lower bounds on the safety probabilities
for iMDPs. In  #cl("DBLP:journals/corr/abs-2605-10293"),
the worst-case estimates of the bounds are used to compute a
#emph[robust], conservative shield. Consider the case where a particular
action imposes a lower bound of $10 percent$ and an upper bound of
$30 percent$ on the probability of reaching a safety-critical unsafe
state. The application at hand may allow reaching such a state with a
maximum probability of $20 percent$. A shield with a #emph[robust]
uncertainty interpretation would block that action.

===== Safety vs. exploration.
<safety-vs.-exploration.>
The key strength of our adaptive shielding approach is that gathering
more data yields more accurate model estimates, which reduce the size of
the probability intervals and allow for less conservative shields. The
challenge, however, is that a too-conservative shield may, in the
extreme, impede any exploration of the environment and thereby prevent
the agent from gathering the necessary data to refine the shield and
learn a good policy. One solution to this problem is to use an
#emph[optimistic] interpretation of uncertainty, as is common in robust
RL and referred to as optimism in the face of
uncertainty  #cl("DBLP:journals/make/MoosHASCP22"). In the example
above, the (optimistic) shield would then use the lower probability
bound of $10 percent$ and allow the critical action. Another approach is
to use common RL exploration techniques to address the
exploration-exploitation dilemma  #cl("DBLP:books/lib/SuttonB2018").

===== Contributions and research questions.
<contributions-and-research-questions.>
The main contribution of this paper is a novel, adaptive shielding
algorithm that accounts for the uncertainty in estimating an MDP from
data. We provide a thorough experimental evaluation structured around
several concrete research questions. First, we evaluate if an adaptive
shielding approach is beneficial to (1) obtain a safe and reward-optimal
policy after training and (2) remain safe during training. Then, we
investigate whether the choice of model estimator affects the
performance of the shield and how far the quality of the MDP estimate
improves over time with respect to the (conservativeness) of the shield.
Finally, we take into account various practical considerations, such as
the number of model updates in relation to the number of RL episodes.
The paper is structured as follows. In the remainder of the
introduction, we discuss related work. In @sec:prelims, we
provide necessary background, followed by the definitions of shields for
(interval) MDPs and model estimation in
@sec:shielding-and-estimation.
@sec:adaptive-shields describes our adaptive probabilistic
shielding algorithm. Finally, we present our research questions and
experimental analysis in @sec:evaluation.

=== Related work
<related-work>
===== Probabilistic shielding.
<probabilistic-shielding.>
Classic shields provide unconditional safety guarantees, but this is
often too
conservative  #cl("DBLP:conf/cav/HeckMACJ26", "DBLP:journals/cacm/KonighoferBJJP25").
Shielding has been extended to many classes of
models  #cl("DBLP:conf/atal/Elsayed-AlyBAET21", "PaperA", "DBLP:journals/corr/abs-2509-12085", "DBLP:conf/l4dc/KimCRLPBSF25", "AlshiekhBEKNT18", "DBLP:conf/amcc/ReedL25", "DBLP:journals/corr/abs-2510-03481", "PaperC").
We consider probabilistic shields that permit a level of risk of
reaching unsafe
states  #cl("DBLP:conf/aaai/CourtBG25", "DBLP:conf/concur/0001KJSB20", "DBLP:conf/cav/HeckMACJ26", "DBLP:journals/cacm/KonighoferBJJP25").
In this paper, we focus on practical shields that guarantee the
#emph[admissibility] of probabilistic safety
guarantees  #cl("DBLP:conf/concur/0001KJSB20", "DBLP:conf/amcc/PrangerKTD0B21", "DBLP:journals/corr/abs-2605-10293", "DBLP:journals/cacm/KonighoferBJJP25").
Specifically, our shielding method is based
on  #cl("DBLP:journals/corr/abs-2605-10293").

===== Adaptive shielding.
<adaptive-shielding.>
Several works have considered shields that change over time. Pranger et
al. adaptively construct a finite-state environment abstraction from
past observations to maintain a
shield  #cl("DBLP:conf/amcc/PrangerKTD0B21"). Similarly, Tappler et
al. present an iterative approach using automata
learning  #cl("DBLP:conf/isola/TapplerPKMBL22"). In other work, the
shield adapts to changes in the environment, assuming white-box access
to the (parametric)
dynamics  #cl("senthilvelan_similarity-based_2023", "DBLP:journals/pacmpl/FengZPL25").
Goodall et al. estimate probabilistic safety by simulating future
trajectories in a learned latent
model  #cl("DBLP:conf/ecai/GoodallB23"). Bethell et al. learn a shield
using an auto-encoder and adjust the safety threshold in a subsequent RL
phase  #cl("DBLP:conf/ecai/BethellGCI25").

===== Shielding based on model estimates.
<shielding-based-on-model-estimates.>
Galesloot et al. estimate iMDPs for shielding in #emph[offline]
RL  #cl("DBLP:journals/corr/abs-2605-10293"). Suilen et
al. obtain iMDP estimates via optimistic exploration and then
analytically compute a robust
policy  #cl("DBLP:conf/nips/SuilenS0022"). Another recent work collects
environment data offline and then computes a robust shield for shielded
RL, with the main contribution being a new algorithm to compute the
shield  #cl("court2026robustshieldingsafereinforcement").

===== Delimitation.
<delimitation.>
The main differences of our problem setting are as follows. We assume a
static environment with a known, finite state space and transition
structure, but with unknown transition probabilities. We further assume
black-box access instead of a settable simulator, which is why we
specifically care about safety during the whole process, including data
collection and exploration. Our method differs from previous work in
that we integrate model estimation and updates of both the shield and
the policy into a single integrated #emph[online] RL procedure with
adaptive probabilistic shields.

== Preliminaries
<sec:prelims>
===== Probability distributions.
<probability-distributions.>
Given a set $X$, a probability
distribution $p colon X arrow.r lr([0 comma 1])$ satisfies
$sum_(x in X) p lr((x)) eq 1$. Let $Delta lr((X))$ denote the set of
probability distributions over $X$ and
let $upright(U n i f)_X in Delta lr((X))$ denote the uniform
distribution over $X$.

===== Intervals.
<intervals.>
A closed interval $lr([a comma b]) subset.eq bb(R)$ for $a lt.eq b$
describes the set
$brace.l x in bb(R) divides a lt.eq x lt.eq b brace.r$. An open interval
$lr((a comma b))$ describes
$brace.l x in bb(R) divides a lt x lt b brace.r$. Half-open intervals
are defined analogously. Let
$bb(I) eq brace.l lr([a comma b]) divides 0 lt a lt.eq b lt.eq 1 brace.r$
denote the set of uncertain nonzero probabilities.

===== Markov decision processes.
<markov-decision-processes.>
A #emph[Markov decision process] (MDP) is a
tuple $M eq lr((S comma A comma s_0 comma T))$ where $S$ is the finite
set of states, $A$ is the finite set of actions, $s_0 in S$ is the
initial state, and $T colon S times A times S arrow.r lr([0 comma 1])$
is the probabilistic transition function satisfying
$sum_(s prime in S) T lr((s comma a comma s prime)) eq 1$ for all $s$
and $a$. A #emph[run] is an alternating
sequence $s_0 a_0 s_1 a_1 dots.h$ of states and actions such
that $T lr((s_i comma a_i comma s_(i plus 1))) gt 0$ for all $i$.

We consider two types of policies. A #emph[deterministic
policy] $pi colon S arrow.r A$ maps each state to an action. A
#emph[nondeterministic policy] $pi_N colon S arrow.r sans(2)^A$ maps
each state to a set of actions. A run $s_0 a_0 s_1 a_1 dots.h$ is an
#emph[outcome] of a deterministic policy $pi$ (resp. nondeterministic
policy $pi_N$) if $a_i eq pi lr((s_i))$ (resp. $a_i in pi_N lr((s_i))$)
for all $i$.

An #emph[unknown] MDP (uMDP) is a
tuple $M_U eq lr((S comma A comma s_0 comma T_U))$ where $S$, $A$,
and $s_0$ are defined as for MDPs
and $T_U colon S times A arrow.r sans(2)^S$ is a nondeterministic
transition function (i.e., uMDPs are ordinary transition systems). Each
MDP induces an unknown MDP by removing impossible transitions and
dropping the probabilities; formally:
$T_U lr((s comma a)) eq brace.l s prime in S divides T lr((s comma a comma s prime)) gt 0 brace.r$.
An #emph[interval] MDP
(iMDP)  #cl("DBLP:conf/lics/JonssonL91", "DBLP:journals/ior/NilimG05", "DBLP:journals/jcss/StrehlL08", "DBLP:conf/isola/Jaeger0BLJ20", "DBLP:conf/nips/SuilenS0022", "DBLP:conf/birthday/SuilenBB0025")
is a tuple $M_I eq lr((S comma A comma s_0 comma T_I))$ where again $S$,
$A$, and $s_0$ are defined as for MDPs
and $T_I colon S times A times S arrow.r bb(I) union brace.l 0 brace.r$
is an #emph[interval transition function]. Consider an MDP
$M eq lr((S comma A comma s_0 comma T))$ and an iMDP
$M_I eq lr((S comma A comma s_0 comma T_I))$ over $S$ and $A$. We say
that $T_I$ #emph[abstracts] $T$, written $T in T_I$, if $T$ is a
probabilistic transition function and each interval in $T_I$ contains
the corresponding probability in $T$; formally:
$forall s in S med forall a in A colon sum_(s prime in S) T lr((s comma a comma s prime)) eq 1 and forall s prime in S colon T lr((s comma a comma s prime)) in T_I lr((s comma a comma s prime))$.
Analogously, we say that $M_I$ abstracts $M$, written $M in M_I$. Note
that, because intervals in $bb(I)$ must not include $0$, if $T in T_I$
and $T prime in T_I$, then the same transitions in $T$ and $T prime$
have a non-zero probability; formally:
$forall T comma T prime in T_I med forall s comma s prime in S med forall a in A colon T lr((s comma a comma s prime)) gt 0 arrow.r.double.long T prime lr((s comma a comma s prime)) gt 0$.

===== Reinforcement learning.
<reinforcement-learning.>
We assume that the reader is familiar with reinforcement learning
(RL)  #cl("DBLP:books/lib/SuttonB2018") and only recall some basic
commonalities. Let $R colon S times A times S arrow.r bb(R)$ be the
reward function and $gamma in bracket.l 0 comma 1 paren.r$ a discount
factor. Given a deterministic policy $pi$, the #emph[expected cumulative
discounted reward] from the initial state $s_0$ is
$V^pi lr((s_0)) eq bb(E)_s^pi lr([sum_(t eq 0)^oo gamma^t R lr((s_t comma a_t comma s_(t plus 1)))]) comma$
where at each step $t in bb(N)$, the action is $a_t eq pi lr((s_t))$ and
the expectation is taken over the probabilistic state transitions
governed by the transition function $T$. In RL, an agent explores an
environment (which is assumed to be an MDP) with the aim to learn a
policy that maximizes the expected cumulative discounted reward from the
exploration experience. This "training" takes place in episodes of
multiple steps each. RL requires only black-box sampling access to the
environment MDP from an initial state. Two major paradigms are
#emph[model-free] and #emph[model-based]
RL  #cl("DBLP:books/lib/SuttonB2018"). The latter learns an
approximation of the MDP as the agent explores. On the one hand, the
algorithm proposed in this paper learns such an approximation to
construct the shield, and is therefore model-based. On the other hand,
the algorithm also includes an RL component, for which our prototype
implementation uses Q-learning (which is model-free). We note that most
other RL algorithms (model-free or model-based) could also be used in
place of Q-learning.

During training, we use an #emph[$epsilon$-greedy
exploration/exploitation] strategy  #cl("DBLP:books/lib/SuttonB2018"):
at each step, the agent chooses a random action with
probability $epsilon$ ("exploration") and follows the (partially)
learned policy with probability $1 minus epsilon$ ("exploitation").

===== Safety and shielding.
<safety-and-shielding.>
We consider safety properties $phi subset.eq S$ given as a set of safe
states. A run $s_0 a_0 s_1 a_1 dots.h$ is #emph[safe] if $s_i in phi$
for all $i$.

Given a deterministic policy $pi colon S arrow.r A$, a #emph[shield] is
any nondeterministic policy $shield colon S arrow.r sans(2)^A$ over the
same states and actions. The #emph[shielded policy] $pi_shield$ is a
deterministic policy that acts similarly to $pi$ but only chooses
actions allowed by the shield, i.e.,
$forall s in S med forall a in A colon pi_shield lr((s)) eq a arrow.r.double.long a in shield lr((s))$.
Additionally, the shield only alters actions when necessary:
$forall s in S colon pi lr((s)) in shield lr((s)) arrow.r.double.long pi_shield lr((s)) eq pi lr((s))$.
The action chosen by $pi_shield lr((s))$ when
$pi lr((s)) in.not shield lr((s))$ depends on the implementation of the
RL agent. In our implementation, we use
Q-learning  #cl("QLearning"), for which it is
straightforward to read out the best admissible action
in $shield lr((s))$.

== Probabilistic Shielding Using an Estimator
<sec:shielding-and-estimation>
In this paper, we construct shields based on the method described
in  #cl("DBLP:journals/corr/abs-2605-10293"), which was
originally developed for the #emph[offline] RL problem where a fixed
dataset is given. Our approach differs in that we continuously adapt the
shield based on newly generated data, and we must consider exploration
to collect new data within and beyond the shield’s allowed actions. As
we will see later, such a setting is particularly challenging and yields
trade-offs between safety and exploration.

=== Probabilistic shielding approaches for (interval) MDPs
<sec:shields>
Next, we recall how to obtain a shield $shield$ for an (interval) MDP $M$
and a safety specification $phi$. We assume a horizon $h in bb(N)$ and
parameters $theta comma kappa in lr([0 comma 1])$, which we explain
below. Before the formalization, we first describe the high-level idea.
Intuitively, the shield ensures the existence of a series of $h$ actions
from the current state $s$ such that the chance of a safety violation
along these steps is below $theta$. For tractability, the shield is
memoryless and thus ignores accumulated past risk before reaching the
current state $s$. Since the restriction is probabilistic and
memoryless, there may still be a chance of reaching a state where this
guarantee does not
hold  #cl("DBLP:journals/corr/abs-2605-10293", "DBLP:journals/cacm/KonighoferBJJP25", "DBLP:conf/cav/HeckMACJ26").
Whenever no sufficiently safe action is available, the shield only
allows actions that are $kappa$-close to the safest available action.

Now we formalize this idea. Let $phi bar.v h$ be the set of all
#emph[$h$-safe runs] $s_0 a_0 s_1 a_1 dots.h$ with safe $h$-prefix,
i.e., $s_i in phi$ for $i lt.eq h$.
Let $bb(P)_pi^(M comma phi bar.v h) lr((s))$ be the probability of an
MDP $M$ producing an $h$-safe run by following policy $pi$ starting in
state $s$. We denote the related safety optimization problem by
$bb(P)_max^(M comma phi bar.v h) lr((s)) eq max_pi bb(P)_pi^(M comma phi bar.v h) lr((s))$.
Moreover, let the probability of producing a run in $phi bar.v h$ after
taking action $a$ in state $s$ be
$bb(P)_max^(M comma phi bar.v h) lr((s comma a)) eq sum_(s prime in S) T lr((s comma a comma s prime)) bb(P)_max^(M comma phi bar.v h minus 1) lr((s prime))$.

Normally, the shield allows all actions guaranteeing a safe $h$-step run
with probability at least $1 minus theta$; formally:
$shield_theta lr((s)) eq brace.l a in A divides bb(P)_max^(M comma phi bar.v h) lr((s comma a)) gt.eq 1 minus theta brace.r$.
However, a shielded policy may still reach a state $s$ where this shield
definition would not allow any action (i.e.,
$shield_theta lr((s)) eq nothing$). In that case, the shield instead
allows all actions that are $kappa$-close to the safest available
action; formally:
$shield_kappa lr((s)) eq brace.l a in A divides bb(P)_max^(M comma phi bar.v h) lr((s comma a)) gt.eq max_(a prime) bb(P)_max^(M comma phi bar.v h) lr((s comma a prime)) minus kappa brace.r$.
Our shield combines these two cases:
$ shield lr((s)) eq cases(delim: "{", shield_theta lr((s)) & upright(i f) med shield_theta lr((s)) eq.not nothing, shield_kappa lr((s)) & upright(o t h e r w i s e dot.basic)) $<eq:shield>

Following  #cl("DBLP:journals/corr/abs-2605-10293"), we
extend shields to iMDPs by defining the probability of producing a run
for iMDPs as follows. Let
$bb(P)_(max "opt")^(M_I comma phi bar.v h) lr((s)) eq max_pi "opt"_(M in M_I) bb(P)_pi^(M comma phi bar.v h) lr((s))$
be the probability of producing a run under the model $M in M_I$
corresponding to the optimization direction
$"opt" in brace.l min comma max brace.r$. Moreover, let the iMDP version
of the probability producing a run in $phi bar.v h$ after taking
action $a$ in state $s$ be
$ bb(P)_(max "opt")^(M_I comma phi bar.v h) lr((s comma a)) & eq "opt"_(T^dagger in T_I) thin sum_(s prime in S) T^dagger lr((s comma a comma s prime)) bb(P)_(max "opt")^(M_I comma phi bar.v h minus 1) lr((s prime)) dot.basic $<eq:imdpshield>
We use the probabilistic model checker PRISM  #cl("PRISM") to
efficiently compute such probabilities on iMDPs. Statistically speaking,
a worst-case assumption ($"opt" eq min$) makes the shield #emph[robust]
against estimation errors.
Following  #cl("DBLP:journals/corr/abs-2605-10293"), we
define a (pessimistic) #emph[robust shield] for an iMDP $M_I$ similarly
to @eq:shield using
$bb(P)_(max min)^(M_I comma phi bar.v h) lr((s comma a))$. Instead of
assuming the worst-case MDP $M$ from an estimate $M_I$, one can also
assume the best case $lr(("opt" eq max))$, specified as
$bb(P)_(max max)^(M_I comma phi bar.v h) lr((s))$. We call this
alternative an #emph[optimistic shield]. We say that the #emph[attitude]
of a shield is either robust or optimistic, depending on how it was
constructed from an iMDP.

=== Estimators from data for unknown MDPs
<sec:introduce:estimators>
We recall three existing estimators, based on those that appeared in
 #cl("DBLP:conf/nips/SuilenS0022"). While exploring the black-box MDP,
we count how many times a transition triple
$lr((s comma a comma s prime))$ has been observed. For that, we use a
transition database $D colon S times A times S arrow.r bb(N)$. Let
$D lr((s comma a)) eq sum_(s prime) D lr((s comma a comma s prime))$ be
the #emph[total count] for a state-action pair $lr((s comma a))$.

An #emph[estimator] is a function $E lr((M_U comma D))$ that maps a
uMDP $M_U$ and a transition database $D$ to either an estimated
MDP $hat(M)$ or iMDP $hat(M)_I$, depending on the estimator. Below, we
describe three estimators that learn (i.e., estimate the transition
function of) MDPs or iMDPs, with or without guarantees: #emph[MAP]
($E_(upright("MAP"))$), #emph[PAC] ($E_(upright("PAC"))$), and
#emph[LUI] ($E_(upright("LUI"))$). These approaches estimate the
transition function locally for each $lr((s comma a))$-pair using
knowledge of the graph in the form of a given uMDP $M_U$, where
$T_U lr((s comma a))$ denotes the set of successor states.

===== MAP.
<map.>
The first approach finds a #emph[point estimate] $hat(T)$ of the MDP’s
transition function $T$ based on the data $D$.
Following  #cl("DBLP:conf/nips/SuilenS0022"), we define point estimates
as maximum a-posteriori (MAP) estimation with respect to a symmetric
prior weight assigned to each successor state, which we denote as a
single $w in bb(N)$. Then
$ hat(T) lr((s comma a comma s prime)) eq frac(w plus D lr((s comma a comma s prime)) minus 1, lr((sum_(t in T_U lr((s comma a))) w plus D lr((s comma a comma t)))) minus lr(|T_U lr((s comma a))|)) $
defines the MAP point estimate. It can be viewed as a maximum-likelihood
probability with some additive smoothing from $w$. The MAP estimator
$E_(upright("MAP"))$ maps $lr((M_U comma D))$ to an estimated MDP
$hat(M)$ with point estimates $hat(T)$.

===== PAC.
<pac.>
The point estimates of the MAP estimator do not account for the
uncertainty arising from estimating probabilities from data. Point
estimates can be turned into #emph[probably approximately correct] (PAC)
intervals via Hoeffding’s inequality  #cl("Hoeffding"), such that the
estimated iMDP contains the true MDP with high probability
$1 minus delta$, for
$delta in lr([0 comma 1])$  #cl("DBLP:conf/cav/AshokKW19", "DBLP:conf/nips/SuilenS0022", "DBLP:journals/corr/abs-2605-10293").
As such, by the union bound, we distribute $delta$ over all transitions
as $delta_T eq frac(delta, sum_(s comma a) k lr((s comma a)))$, where
$k lr((s comma a))$ denotes the number of successor states
$k lr((s comma a)) eq lr(|T_U lr((s comma a))|)$ if
$lr(|T_U lr((s comma a))|) gt 1$ and $k lr((s comma a)) eq 0$ otherwise.
Then,
$eta_(s comma a) eq frac(log lr([2 / delta_T]), 2 dot.op D lr((s comma a)))$
denotes the range of the PAC interval around the point estimate for
$lr((s comma a))$. Using each $eta_(s comma a)$, we construct the
intervals
$ hat(T)_I lr((s comma a comma s prime)) eq lr([max lr((xi comma hat(T) lr((s comma a comma s prime)) minus eta_(s comma a))) comma min lr((1 comma hat(T) lr((s comma a comma s prime)) plus eta_(s comma a)))]) $<eq:pac>
where $xi in lr((0 comma 1))$ is a small constant that ensures intervals
for transitions with nonzero probability (as given by the unknown MDP
$M_U$) map to $lr([xi comma 1])$. The PAC estimator $E_(upright("PAC"))$
maps $lr((M_U comma D))$ to an iMDP $hat(M)_I$ with intervals $hat(T)_I$
from @eq:pac.

#emph[LUI.] The third approach that we consider is the #emph[linearly
updating intervals] (LUI) estimator
from  #cl("DBLP:conf/nips/SuilenS0022"), which in turn is based
on  #cl("imprecisionconflicts2009"). While it does not retain PAC
guarantees, it iteratively learns probabilities by updating intervals.
We assign each unknown transition a prior interval
$tilde(T)_I lr((s comma a comma s_i prime)) eq lr([underline(T)_i comma overline(T)_i])$
and prior strength $lr([underline(n)_i comma overline(n)_i])$. The
strength influences the prior’s effect on the updated intervals. At any
point, we find new intervals given the database $D$ by distinguishing
cases based on whether the current intervals agree with the new data.
For any $lr((s comma a))$ and $s prime_j$, let
$F_j eq frac(D lr((s comma a comma s prime_j)), D lr((s comma a)))$
denote the relative occurrence of transition
$lr((s comma a comma s prime_j))$ in the database $D$. Then, the updates
are:

$ underline(T)_i arrow.l {frac(overline(n)_i underline(T)_i plus D lr((s comma a comma s prime_i)), overline(n)_i plus D lr((s comma a))) quad upright("if ") F_j gt.eq underline(T)_j upright(" for all ") s_j prime comma\
frac(underline(n)_i underline(T)_i plus D lr((s comma a comma s prime_i)), underline(n)_i plus D lr((s comma a))) quad upright("otherwise") dot.basic $
$ overline(T)_i arrow.l {frac(overline(n)_i overline(T)_i plus D lr((s comma a comma s prime_i)), overline(n)_i plus D lr((s comma a))) quad upright("if ") F_j lt.eq overline(T)_j upright(" for all ") s_j prime comma\
frac(underline(n)_i overline(T)_i plus D lr((s comma a comma s prime_i)), underline(n)_i plus D lr((s comma a))) quad upright("otherwise") dot.basic $<eq:lui>

The (strength) intervals are found from total counts
$lr([underline(n)_i plus D lr((s comma a)) comma overline(n)_i plus D lr((s comma a))])$.
Initial intervals are valid when
$0 lt underline(T)_i lt.eq overline(T)_j lt.eq 1$ and
$overline(n)_i gt.eq underline(n)_i gt.eq 1$. Similarly to
$E_(upright("PAC"))$, $E_(upright("LUI"))$ maps $lr((M_U comma D))$ to
an iMDP $tilde(M)_I$ with intervals $tilde(T)_I$ using
@eq:lui.

===== Guarantees and convergence.
<guarantees-and-convergence.>
While only $E_(upright("PAC"))$ provides statistical guarantees from
finite data  #cl("DBLP:conf/cav/AshokKW19"), all three estimators
converge to the true probabilities as the number of visits to each
transition tends to infinity  #cl("DBLP:conf/nips/SuilenS0022").

== Adaptive Probabilistic Shielding
<sec:adaptive-shields>
In this section, we develop the paradigm that we call #emph[adaptive
probabilistic shielding]. Before we present our algorithm, we motivate
the problem it addresses.

=== Problem Statement
<sec:problem>
We consider an RL application in a safety-critical real-world scenario.
In particular, we do not know the underlying MDP model (only the
underlying uMDP) and hence do not assume access to a settable simulator.
While safety violations may not be entirely avoidable, we place great
importance on them, as they may occur during real-world data collection
outside a simulator  #cl("DBLP:journals/ijrr/LacerdaFPH19"). Hence, our
goal is to obtain a policy $pi$ subject to three sub-goals: (i) achieve
a given admissibility threshold of the safety specification,
(ii) achieve a high expected reward, and (iii) achieve a low number of
safety violations during training.

To highlight the intricacy of our problem, we point out that goal (iii)
is in direct competition with the other two goals. This is because
higher safety during training requires more conservative exploration,
which may prevent the discovery of a better-performing policy (e.g., a
faster and/or safer route to a goal state). Since we do not assume prior
knowledge of the environment’s transition dynamics, one may have to take
more risks to learn them; thus, an action deemed less safe due to higher
uncertainty may only be determined to be safer after enough exploration.
While RL solves (ii), it does not achieve (i), and it may also perform
poorly regarding (iii), since it typically relies on (random)
exploration of the environment. To additionally achieve (i), we could
apply shielded RL; however, since we do not know the MDP, we would need
to learn an MDP or iMDP model, which would itself require exploration
for the data collection and thus again fail to achieve goal (iii).

=== Adaptive Probabilistic Shielding
<sec:ourapproach>
Our answer to this dilemma is to interweave all three procedures (policy
learning, shield construction, and model estimation) into a single
adaptive learning loop. Generally, we collect data from the RL agent’s
exploration of the environment. From time to time, we use that data to
update our model estimate, and from that improved estimate, we obtain a
refined shield that allows us to continue exploring the environment more
safely and/or less conservatively.

One may be tempted to think that this process will, given enough
episodes, converge to the ideal solution of learning the underlying MDP
and thus the best possible shield. However, this is not necessarily the
case, and indeed, we observed that such an approach can fail in
practice. The issue is that the conservative shield, from the beginning,
may simply prevent exploration of large parts of the state space, even
if the corresponding actions were to be perfectly safe under the true
MDP model. More specifically, the shield cannot distinguish between
actions that are already known to be risky (which it should indeed
block) and actions for which the model estimate is too coarse to make a
definite judgement. This is particularly pronounced for the more
pessimistic robust shields.

Our final step is to extend the $epsilon$-greedy exploration strategy to
explore beyond the shield’s boundaries. When the exploration strategy
decides to explore a random action in state $s$, we choose this action
from the full set of actions $A$, rather than just from $shield lr((s))$
allowed by the shield. We show the impact of this extension empirically
in the next section
in @sec:unshieldedexploration.

@alg:alg shows the pseudocode of our proposed
approach. Notably, we only use white-box access to the environment via
the uMDP $M_U$, while we only access the underlying MDP $M$ implicitly
via the black-box functions $T$ and $R$.

In our implementation, we use
Q-learning  #cl("QLearning") to find a policy $pi$.
For that, we initialize $pi$ as an empty Q-table and an empty
database $D$ of observed transition triples. In the first iteration of
the outer for-loop in @ln:outerloop,
$i eq 0$ satisfies the condition in
@ln:shieldrecomputationconditional,
which triggers the computation of the first model estimate $hat(M)$ and
shield $shield$. Since the transition database is still empty, this
estimate and shield are most conservative. The inner for-loop in
@ln:innerloop represents Q-learning for a
single episode with the extended $epsilon$-greedy exploration strategy
described above under $shield$. In particular, we either select a random
action ("explore") or select the current best action that is allowed by
the shield ("exploit"). The selected action is then executed in the
environment MDP $M$. Its output is recorded in the transition
database $D$ and used along with the immediate reward $r$ to update the
Q-table. Every $u$ episodes, we update the model estimate and shield.
After exceeding the training budget of $N$ episodes, we return the final
versions of the policy, the shield, and the model estimate.



#figure(kind: "algorithm", supplement: "Algorithm", pseudocode-list(numbered-title: [Safe RL via Adaptive Probabilistic Shielding])[
  - *Input:* black-box MDP $mdp = (S, A, s_0 , T )$,
    uMDP $mdp_U = (S, A, s_0 , T_U )$,
    reward function $R$,
    safety specification $φ$,
    estimator $E$,
    shield update delay u$ ∈ NN;$
    shield parameters $θ, κ ∈ [0, 1]$ and $h ∈ NN$,
    exploration rate $ε ∈ [0, 1]$,
    number of episodes $N ∈ NN$,
    maximum episode length $L ∈ NN$
  + $pi arrow.l$ Initialize RL policy
  + $D lr((s comma a comma s prime)) arrow.l 0 comma quad forall thin lr((s comma a comma s prime))$ #comment("Initialize transition database")
  + *For* $i$ *in* $0$ *to* $N-1$ inclusive *do* #line-label(<ln:outerloop>)
      + *If* $i ≡ 0 mod u$ *then* #line-label(<ln:shieldrecomputationconditional>)
      + $hat(M) arrow.l E lr((M_U comma D))$ #comment([See @sec:introduce:estimators])
      + $shield arrow.l$ Synthesize shield from $hat(M)$, $theta$, $kappa$, and $h$ for $phi$  #comment([See @sec:shields])
      + $s arrow.l s_0$
    + *For* $j$ *in* $0$ *to* $L - 1$ inclusive *do* #line-label(<ln:innerloop> )
      + Flip a weighted coin that has probability $epsilon$ of landing on heads.
      + *If* heads *then* $a tilde.op upright("Unif")_A$ #line-label(<ln:explore>) #comment[“Explore” – uniform choice among all actions]
      + *Else*  $a eq pi_shield lr((s))$ #line-label(<ln:exploit>) #comment[“Exploit” – agent chooses the best safe action#h(.05em)]
      + $s prime tilde.op T lr((s comma a))$  #comment[Take a step with action a in the environment#h(.3em)]
      + $pi arrow.l$ Update policy with transition $lr((s comma a comma s prime))$ and reward + $R lr((s comma a comma s prime))$
      + $D lr((s comma a comma s prime)) arrow.l D lr((s comma a comma s prime)) plus 1$
      + $s arrow.l s prime$
  + *Return* $(pi, shield, hat(M))$
])<alg:alg>

== Experimental Evaluation
<sec:evaluation>
In this section, we evaluate our proposed adaptive probabilistic
shielding approach from different angles. We aim to answer the following
research questions:

*@sec:safetyandreward* Can our approach learn a safe and optimal policy?\
*@sec:exploration* What is the effect on the environment exploration?\
*@sec:modeldistance* Does the model estimate improve over time?\
*@sec:kapparate* Do the model estimates become sufficiently precise?\
*@sec:estimators* What is the impact of the specific model estimator?\
*@sec:unshieldedexploration* Is unshielded exploration beneficial?\
*@sec:updatefrequency* How often should the shield be updated?\
*@sec:horizon* What is the impact of the shield lookahead ($h$)?

=== Implementation and Baseline Methods
<implementation-and-baseline-methods>
The implementation is available online  #cl("brorholt_2026_21874278").
We train the agent using standard
Q-learning  #cl("QLearning") with the hyperparameters
$alpha eq 0.1$ (learning rate), $gamma eq 0.9$ (discount factor), and
$epsilon eq 0.05$ (exploration probability). We use reward shaping to
penalize safety violations, with the penalty varying by environment.
Instead, we separately record the number of episodes that were unsafe.

By default, we use the LUI estimator $E_(upright("LUI"))$ with prior
strengths $lr([underline(n)_i comma overline(n)_i]) eq lr([5 comma 10])$
and a ("pessimistic") robust shield attitude with parameters
$theta eq 0.05$, $kappa eq 0.01$, and $h eq 100$, and update the
estimate and shield every $u eq 1000$ episodes. We underline these
defaults in the following figures and tables.

We compare to two baselines. The first baseline is a standard unshielded
RL agent trained with reward shaping; this baseline is expected to
perform poorly in terms of safety due to the lack of a shield. The
second baseline is a shielded RL agent that uses a probabilistic shield
computed with the same method but given the ground-truth MDP (which our
method cannot access); this "oracle" baseline acts as a benchmark and is
expected to outperform all other methods.

=== Description of Environments
<description-of-environments>
In total, we consider five different environments with mixed safety and
optimization objectives. The first environment is described in previous
literature while the remaining were developed as additional benchmarks
for our problem setting.

The #strong[aircraft]
environment  #cl("DBLP:conf/nips/SuilenS0022", "Kochenderfer15")
($lr(|S|) eq 1665$) represents a collision avoidance system of an
aircraft that must keep a minimum vertical distance to another plane
that passes horizontally. The other plane changes altitude at random,
and the agent’s aircraft may fail to follow the instructions with a
small probability.

The #strong[antlion] environment ($lr(|S|) eq 400$) requires the agent
(an ant) to circumnavigate a stationary predator in order to reach a
goal on the other side. Instead of moving in the intended direction, the
agent may slip toward the predator, with the probability increasing with
proximity to it. Reaching the goal yields a reward, while taking a step
has a cost that decreases with proximity to the goal.

The #strong[sinkholes] environment ($lr(|S|) eq 400$) features multiple
goals with varying rewards and multiple holes that must be avoided. If
the agent falls into a hole, it either escapes with a small probability
or returns to the starting state. As the agent moves, it may slip in a
random direction instead, with the probability varying by the state. The
cost of moving decreases with proximity to the goal.

The #strong[crossroads] environment ($lr(|S|) eq 202$) illustrates
deferred risk. In the initial state, the agent must choose between two
roads, which are then followed for $100$ steps. One route is safe, while
the other route is more rewarding but has a risk of slipping into an
unsafe state at each step.

The #strong[gravity] environment ($lr(|S|) eq 2000$) rewards the agent
for visiting a sequence of checkpoints near a gravity well without
crashing into the latter. Every step has a small cost, and there is a
probability that the agent is dragged towards the well, which increases
with proximity. Later checkpoints are riskier to visit, and the agent
can end the episode early by going to one of two exit points.


#figure(grid(columns: 4,
    [#h(2em)I], [#h(1.2em)II], [#h(2em)III], [#h(2em)IV],
    image("../Graphics/RV26/Aircraft_safety.png"),
    image("../Graphics/RV26/Aircraft_reward.png"),
    image("../Graphics/RV26/Aircraft_fallback_actions.png"),
    image("../Graphics/RV26/Aircraft_TV.png"),

    image("../Graphics/RV26/Antlion_safety.png"),
    image("../Graphics/RV26/Antlion_reward.png"),
    image("../Graphics/RV26/Antlion_fallback_actions.png"),
    image("../Graphics/RV26/Antlion_TV.png"),

    image("../Graphics/RV26/Sinkholes_safety.png"),
    image("../Graphics/RV26/Sinkholes_reward.png"),
    image("../Graphics/RV26/Sinkholes_fallback_actions.png"),
    image("../Graphics/RV26/Sinkholes_TV.png"),

    image("../Graphics/RV26/Crossroads_safety.png"),
    image("../Graphics/RV26/Crossroads_reward.png"),
    image("../Graphics/RV26/Crossroads_fallback_actions.png"),
    image("../Graphics/RV26/Crossroads_TV.png"),

    image("../Graphics/RV26/Gravity_safety.png"),
    image("../Graphics/RV26/Gravity_reward.png"),
    image("../Graphics/RV26/Gravity_fallback_actions.png"),
    image("../Graphics/RV26/Gravity_TV.png"),
  ),
  caption: [
    Mean outcome of 100 repetitions for different configurations. We
    plot the standard deviation as a ribbon around the lines. Vertical
    grid lines mark updates of the adaptive shield. Column I: Cumulative
    safety violations during training. Column II: Reward during
    training. Column III: Per-episode rate of using the
    fallback $shield_kappa$. Column IV: Average total variation between
    true model and model estimate during training.
  ]
)<fig:thefigure>

#figure(grid(columns: 6, align:  bottom,
    image("../Graphics/RV26/Antlion_Unshielded_Heatmap.png", height: 65pt),
    image("../Graphics/RV26/Antlion_Oracle_Heatmap.png", height: 65pt),
    image("../Graphics/RV26/Antlion_LUI_Heatmap.png", height: 65pt),
    image("../Graphics/RV26/Antlion_PAC_Heatmap.png", height: 65pt),
    image("../Graphics/RV26/Antlion_MAP_Heatmap.png", height: 65pt),
    image("../Graphics/RV26/Antlion_Heatmap_Legend.png", height: 60pt)
  ),
  caption: [
    Heat map showing how frequently a state is visited in the antlion
    environment. The initial state, predator, and goal are at the
    top, center, and bottom, respectively.
  ]
)
<fig:heatmap>


=== Experimental Results and Discussion of Research Questions
<experimental-results-and-discussion-of-research-questions>
Our experiments consists of $21$ hyperparameter configurations (e.g.,
the choice of the model estimator), and we repeated each run $100$
times.


#[
  #let myNumbering(..numbers) = {
    if (numbers.pos().len() != 4) { error() }
    return numbering("(RQ1)", ..numbers.pos().slice(3))
  }
#show heading.where(level: 4): set heading(numbering: myNumbering, supplement:  none)


====  Can our approach learn a safe and optimal policy? <sec:safetyandreward>
We are interested in both safety (@fig:thefigure column I)
and performance (@fig:thefigure column II) over time. (Note
that the penalty stemming from the reward shaping is not included in
these plots.) For most environments, the adaptive shield leads to about
the same number of safety violations as the oracle shield. The
unshielded baseline is generally less safe, especially in the crossroads
and gravity environments, despite a strong reward penalty. Still, the
negative outcomes were overshadowed by the more frequent positive
rewards in the Q-learning algorithm. We also note that the oracle
baseline can generally explore more freely than the adaptive method
because of its less conservative shield. Yet, in the aircraft
environment, the adaptive method actually achieves a slightly more
rewarding policy, profiting from slightly riskier behavior. This may
seem counterintuitive given the robust attitude of the shield, which is
generally more conservative than the oracle baseline. The reason we
still see this behavior is that, during the exploration, profitable
states are visited more often, making these seem safer as compared to
less explored states with wider interval estimates. Indeed, column III
reveals that the shield mostly falls back to the $shield_kappa$ variant
in this case.

Updates to the adaptive shield can be seen to temporarily affect
performance negatively in the antlion, sinkholes, and gravity
environments. At the $1000$ episode mark, the shield is updated for the
first time, leading to a drop in the reward performance. This drop is to
be expected: as seen in column III, the initial shield typically uses
the $shield_kappa$ variant because every action seems unsafe. The first
model update is most impactful and hence typically leads to a very
different shield, and hence the agent effectively experiences a
different environment. Over time, the reward performance recovers as the
policy adapts to the new shield.

Overall, the shields have a significant positive impact on safety and
explore the environment more safely. This safety may come at a cost when
risky behavior is profitable, but this is a desirable trade-off in many
applications.

====  What is the effect  on the environment exploration? <sec:exploration>
To assess how adaptive shields affect exploration,
@fig:heatmap visualizes the number of times a state has been
visited in the antlion environment during one algorithm execution over
$10 comma 000$ episodes, comparing the unshielded and oracle baselines
as well as adaptive shields with the estimators #emph[robust LUI]
(default), #emph[robust PAC], and #emph[MAP].

The LUI and PAC interval estimators both find the goal by following some
narrow paths during learning. Meanwhile, the MAP estimator almost never
leaves the area around the initial states. This is consistent with the
low average performance of the MAP estimator in
@tab:estimators and further investigated below in
@sec:estimators. The unshielded agent passes
close to the antlion but takes a more circuitous route, similar to what
the oracle shield allows. Both appear to explore more freely around the
paths they take, rather than staying on a narrow route permitted by the
adaptive shield. This highlights the need for exploring states outside
of what the shield allows, as also investigated in
@sec:unshieldedexploration below.

====  Does the model  estimate improve over time? <sec:modeldistance>
We plot mean #emph[total variation] (TV), i.e.,
$ frac(1, lr(|S|) lr(|A|)) sum_(s comma a) 1 / 2 sum_(s prime in S) lr(|T^dagger lr((s comma a comma s prime)) minus T^ast.basic lr((s comma a comma s prime))|) $
between the true MDP’s transition probabilities $T^ast.basic$ and the
probabilities $T^dagger$ returned by PMC used for the shield (e.g., for
robust/optimistic shields, as found from
@eq:imdpshield). We omit transitions with
probability 1, since their probability is known.

As the agent explores the environment, we obtain a more precise estimate
of the model. Exploration also comes with risk; thus, it is not
desirable to obtain a perfect estimate of all transitions – in
particular not those transitions that are rarely visited by the policy.
The mean TV after each model update is shown in column IV of
@fig:thefigure. The most significant change occurs in the
first update after $1000$ episodes, indicating that this is sufficient
to collect data for key transitions, which will be further explored
during the rest of the training. While the estimates for these
transitions keep improving, this has little impact on the (global)
metric.

====  Do the model estimates  become sufficiently precise? <sec:kapparate>
We examine how often the shield allows an action because it satisfies
the $theta$ threshold ($shield_theta$) respectively how often it has to
use the fallback ($shield_kappa$)
(cf. @eq:shield). Column III of
@fig:thefigure shows the fallback frequency. Until the first
model update ($1000$ episodes), the robust and MAP estimates primarily
use $shield_kappa$, whereas the optimistic estimates, which consider
almost all actions safe from the beginning, primarily use $shield_theta$.
The slowest improvement of the estimate is observed in the aircraft
environment. This is because, unlike the static obstacles in the other
environments, learning the behavior of the randomly moving opponent
requires more data. In all other environments, $shield_theta$ is used
most of the time after one or two model updates for all but the robust
PAC estimator, which sometimes fails to obtain a sufficiently precise
estimate (due to its higher data requirements).


#figure(placement: top,
  table(
    columns: 6,
    inset: (left: 4pt, right: 4pt),
    align: (col, row) => (center,center,center,center,center,center,).at(col),
    [Estimator], [Aircraft], [Antlion], [Sinkholes], [Crossroads], [Gravity],
    [#underline[Robust LUI]], [14.89~~8.3%], [5.27~~4.5%], [57.05~~3.6%], [5.12~~*0.0%*], [8.27~~3.9%],
    [Robust PAC], [*15.54*~~8.2%], [6.33~~*2.8%*], [46.59~~3.8%], [5.12~~*0.0%*], [-2.56~~*0.0%*],
    [MAP], [13.24~~*4.0%*], [-8.99~~8.0%], [49.16~~*3.0%*], [5.12~~*0.0%*], [-2.35~~*0.0%*],
    [Optimis. LUI], [14.17~~5.2%], [6.66~~6.0%], [67.78~~4.1%], [5.11~~*0.0%*], [21.40~~19.6%],
    [Optimis. PAC], [14.35~~6.8%], [6.36~~10.0%], [65.35~~3.8%], [5.12~~*0.0%*], [23.51~~47.8%],
    [Unshielded], [14.36~~7.3%], [6.62~~9.0%], [65.62~~3.7%], [*9.57*~~40.1%], [*30.35*~~99.2%],
    [Oracle], [13.98~~4.1%], [*6.78*~~5.6%], [*73.32*~~3.8%], [5.12~~*0.0%*], [19.86~~4.5%],
  ),
  caption: [Comparison for different model estimators. The numbers
  in each cell respectively denote the reward in the final evaluation
  (left) and the probability that the final policy produces an unsafe
  episode (right). The numbers are the mean outcomes of $100$ repetitions
  and bold entries mark the best result for each column.]
)<tab:estimators>

#figure(placement: top,
  table(
    columns: 6,
    align: (col, row) => (center,center,center,center,center,center,).at(col),
    [Exploration], [Aircraft], [Antlion], [Sinkholes], [Crossroads], [Gravity],
    [#underline[$Unif_A$]], [14.89~~*8.3%*], [*5.27*~~*4.5%*], [57.05~~*3.6%*], [*5.12*~~*0.0%*], [*8.27*~~3.9%],
    [$Unif_shield(s)$], [*15.04*~~9.8%], [1.93~~5.1%], [*57.29*~~3.7%], [5.00~~*0.0%*], [1.58~~*0.6%*],
  ),
  caption: [Comparison for the two exploration variants. Setup as in
  @tab:estimators.]
)<tab:exploration>

====  What is the impact of the specific model estimator? <sec:estimators>
We investigate how the different model estimators impact the results.
Specifically, we compare the iMDP estimators PAC and LUI, both with the
robust and the optimistic attitudes, and the MDP estimator MAP. We fix
the priors of MAP to $w eq 10$ and of LUI to
$lr([underline(n)_i comma overline(n)_i]) eq lr([5 comma 10])$, and the
parameters of PAC to $delta eq 0.1$ and $xi eq 10^(minus 8)$. Varying
priors as an additional dimension of experimental parameters is left for
future research.

In @tab:estimators, we show the evaluation of the final
policies. Each cell shows the reward, evaluated empirically as the mean
over $1000$ episodes, and the relative safety of this policy, computed
analytically using the PRISM model checker  #cl("PRISM").#footnote[We
did not use PRISM to compute the reward because it does not support a
mix of positive and negative rewards.]

Counterintuitively, robust estimators do not always lead to safer
policies, as seen in the aircraft environment. Since the agent initially
finds an imperfect route, which is considered relatively safe compared
to less-explored states, the shield later forces the agent to stay on
it, even if an unexplored yet safer alternative may exist. Instead, the
optimistic shield specifications allow the agent to explore more states
unless prior experience indicates that doing so is unsafe. The sinkholes
and gravity environments show the biggest variation in the results. This
is because the goals (checkpoints) in the sinkholes (gravity)
environment are far apart, and hence finding a good route strongly
depends on the exploration.

==== Is unshielded exploration beneficial? <sec:unshieldedexploration>
In @ln:explore of
@alg:alg, the $epsilon$-greedy exploration chooses
a random action from the set of all actions $upright(U n i f)_A$, thus
disregarding the shield. In @tab:exploration, we compare this
strategy to the alternative that only admissible actions are allowed in
state $s$ with $upright(U n i f)_(shield lr((s)))$. Generally, with the
latter variant, the agent eventually stops exploring new actions once
the shield has found at least one admissible route. For some
environments, this change has no significant effect on the reward
because the route that was identified first was sufficiently good, while
in the antlion and gravity environments, the restricted variant prevents
the agent from uncovering more promising routes.


#figure(placement: top,
  table(
    columns: 6,
    align: (col, row) => (center,center,center,center,center,center,).at(col),
    [$u$], [Aircraft], [Antlion], [Sinkholes], [Crossroads], [Gravity],
    [#hide[0#h(1pt)]250], [14.94~~12.9%], [-10.74~~9.7%], [78.71~~5.4%], [*5.12*~~*0.0%*], [-2.32~~*0.0%*],
    [#hide[0#h(1pt)]500], [*14.99*~~10.5%], [-10.46~~11.0%], [*84.78*~~4.1%], [*5.12*~~*0.0%*], [2.95~~1.9%],
    [#underline[1#h(1pt)000]], [14.89~~8.3%], [5.27~~4.5%], [57.05~~*3.6%*], [*5.12*~~*0.0%*], [8.27~~3.9%],
    [1#h(1pt)500], [14.81~~7.8%], [*6.17*~~*3.7%*], [54.40~~*3.6%*], [*5.12*~~*0.0%*], [11.02~~3.5%],
    [2#h(1pt)000], [14.72~~*7.0%*], [6.06~~4.0%], [57.93~~*3.6%*], [*5.12*~~*0.0%*], [*12.92*~~8.2%],
  ),
  caption: [Comparison for different update delays $u$. Setup as in @tab:estimators.]
)<tab:frequency>

#figure(placement: top,
  table(
    columns: 6,
    align: (col, row) => (center,center,center,center,center,center,).at(col),
    [$h$], [Aircraft], [Antlion], [Sinkholes], [Crossroads], [Gravity],
    [#hide[00]6], [14.50 ~~ *8.2%*], [*6.42* ~~ *3.1%*], [48.50 ~~ *3.3%*], [*9.57* ~~ 40.1%], [*24.61* ~~ 47.1%],
    [#hide[0]12], [14.78 ~~ *8.2%*], [5.90 ~~ 3.8%], [54.81 ~~ 3.4%], [*9.57* ~~ 40.1%], [23.16 ~~ 33.3%],
    [#hide[0]25], [*14.89* ~~ 8.3%], [5.71 ~~ 4.2%], [56.31 ~~ 3.7%], [*9.57* ~~ 40.1%], [22.16 ~~ 21.5%],
    [#hide[0]50], [*14.89* ~~ 8.3%], [4.67 ~~ 4.9%], [57.12 ~~ 3.4%], [*9.57* ~~ 40.1%], [19.36 ~~ 13.2%],
    [#hide[0]75], [*14.89* ~~ 8.3%], [4.39 ~~ 4.4%], [56.35 ~~ 3.7%], [*9.57* ~~ 40.1%], [13.55 ~~ 6.9%],
    [#underline[100]], [*14.89* ~~ 8.3%], [5.27 ~~ 4.4%], [57.05 ~~ 3.7%], [5.12 ~~ *0.0%*], [8.27 ~~ 4.0%],
    [125], [*14.89* ~~ 8.3%], [5.37 ~~ 4.0%], [57.09 ~~ 3.7%], [5.12 ~~ *0.0%*], [5.21 ~~ 2.7%],
    [150], [*14.89* ~~ 8.3%], [5.14 ~~ 3.6%], [57.07 ~~ 3.9%], [5.12 ~~ *0.0%*], [3.81 ~~ 2.5%],
    [175], [*14.89* ~~ 8.3%], [5.42 ~~ 3.6%], [*57.19* ~~ 3.7%], [5.12 ~~ *0.0%*], [2.90 ~~ 2.0%],
    [200], [*14.89* ~~ 8.3%], [5.33 ~~ *3.1%*], [57.18 ~~ 3.6%], [5.12 ~~ *0.0%*], [1.24 ~~ *1.5%*],
  ),
  caption: [Comparison for varying shield horizon ($h$ in
  $phi bar.v h$). Setup as in @tab:estimators.]
)<tab:horizon>

====  How often should the shield be updated? <sec:updatefrequency>
The model estimate and subsequent shield update are the most expensive
operations in our approach. We examine the effect of the update
delay $u$. @tab:frequency shows that the choice of $u$ can be
impactful, but no single choice is more preferable across the
environments.

====  What is the impact of the  shield lookahead ($h$)? <sec:horizon>
We examine the effect of varying the lookahead horizon $h$ of the
shield. @tab:horizon shows the results. Aircraft episodes end
after $20$ steps, making longer horizons redundant. The gravity
environment is less safe at lower lookahead. In the crossroads
environment, for $h lt.eq 75$, the agent prefers the more rewarding (but
less safe) route.

] // End set heading numbering

== Conclusion and Future Work
<conclusion-and-future-work>
In this paper, we have proposed the paradigm of #emph[adaptive
probabilistic shielding] for safe reinforcement learning. We assume only
access to a nondeterministic environment model (i.e., we do not know the
transition probabilities) and consequently do not have access to a
simulator. In settings where safety violations are costly, safe
exploration is a challenge. We tackle this challenge with a practical,
integrated procedure that simultaneously explores the environment,
updates a model estimate, maintains a probabilistic shield, and learns a
policy under that shield. Our focus has been on the empirical
evaluation, in which we investigated various research questions
regarding the success and impact of our design choices.

While our shield implementation is based on a recent approach for
interval MDPs  #cl("DBLP:journals/corr/abs-2605-10293"),
the procedure can be extended to support other shields. One direction is
to vary the safety thresholds of the shields computed during the course
of the algorithm, which we have kept to a user-defined constant in our
approach. For instance, we imagine first using an optimistic shield that
encourages exploration and then gradually raising the safety threshold
to obtain a safer shield in the end. As another direction, one can
incorporate more elements from model-based RL algorithms. For instance,
we may replace the uniformly random exploration step with a biased
choice toward under-explored states and actions.


==== Acknowledgments
This research was partly supported by the European Research Council
(ERC) Starting Grant 101077178 (DEUCE), the Villum Investigator Grant
S4OS under reference number 37819, and the Independent Research Fund
Denmark under reference number 10.46540/3120-00041B.


#[
  #set heading(numbering: none) 
  == References

  #bibliography("../Bibliography.bib",
    title: none,
  )
]
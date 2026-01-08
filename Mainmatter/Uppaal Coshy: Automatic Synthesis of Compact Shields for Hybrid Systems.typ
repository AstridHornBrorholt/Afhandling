#import "@preview/subpar:0.2.2"
#import "@preview/lemmify:0.1.8": *
#import "@preview/lovelace:0.3.0": *
#import "../Config/Macros.typ" : *
#let (
  theorem, lemma, corollary,
  remark, proposition, example,
  proof, definition, rules: thm-rules
) = default-theorems("thm-group", lang: "en", thm-numbering: thm-numbering-linear)

#let convertme(content) = { set text(fill: red); content}

= Uppaal Coshy: Automatic Synthesis of Compact Shields for Hybrid Systems

#grid(columns: (1fr, 1fr), row-gutter: 2em,
  [Asger Horn Brorholt \
  _Department of Computer Science \ Aalborg University, Aalborg, Denmark_],

  [Andreas Holck Høeg-Petersen \
  _Department of Computer Science \ Aalborg University, Aalborg, Denmark_],

  [Peter Gjøl Jensen \
  _Department of Computer Science \ Aalborg University, Aalborg, Denmark_],

  [Kim Guldstrand Larsen \
  _Department of Computer Science \ Aalborg University, Aalborg, Denmark_],

  [Marius Mikučionis \
  _Department of Computer Science \ Aalborg University, Aalborg, Denmark_],

  [Christian Schilling \
  _Department of Computer Science \ Aalborg University, Aalborg, Denmark_],

  [Andrzej Wąsowski \
  _Department of Computer Science \ IT University of Copenhagen, Copenhagen, Denmark_]
)

#v(1fr)

#heading(level: 2, numbering: none)[Abstract]
We present #smallcaps[Upppaal Coshy], a tool for automatic synthesis of a safety strategy---or _shield_---for Markov decision processes over continuous state spaces and complex hybrid dynamics. The general methodology is to partition the state space and then solve a two-player safety game #cite(label("DBLP:conf/vecos/BrorholtJLLS23")), which entails a number of algorithmically hard problems such as reachability for hybrid systems. The general philosophy of #smallcaps[Upppaal Coshy] is to approximate hard-to-obtain solutions using simulations. Our implementation is fully automatic and supports the expressive formalism of #smallcaps[Uppaal] models, which encompass stochastic hybrid automata.

The precision of our partition-based approach benefits from using finer grids, which however are not efficient to store. We include an algorithm called \caap to efficiently compute a compact representation of a shield in the form of a decision tree, which yields significant reductions.

#pagebreak(weak: true)


== Introduction
<introduction>
In prior work, we proposed an algorithm to synthesize #emph[shields]
(i.e., nondeterministic safety strategies) for Markov decision processes
with hybrid dynamics #cite(label("DBLP:conf/vecos/BrorholtJLLS23")). The
algorithm partitions the state space into finitely many cells and then
solves a two-player safety game, where it uses approximation through
simulation to efficiently tackle algorithmically hard problems. In this
tool paper, we present our implementation #smallcaps[Uppaal Coshy],
which is fully integrated in Uppaal, offering an automatic tool
#footnote[Available at
#link("https://uppaal.org/features/#coshy")[https://uppaal.org/features/\#coshy]]
that supports the expressive Uppaal modeling formalism, including
reinforcement learning under a shield.

Our algorithm represents a shield by storing the allowed actions for
each cell individually, which results in a large data structure. Since
many neighboring cells allow the same actions in practice, as a second
contribution, we propose a new algorithm called #smallcaps[Caap] to
compute a compact representation in the form of a decision tree. We
demonstrate that this algorithm leads to significant reductions as part
of the workflow in #smallcaps[Uppaal Coshy].

An extended version of this paper is available
online #cite(label("arxiv_version")).

=== Related Tools for Shield Synthesis and Compact Representation
<related-tools-for-shield-synthesis-and-compact-representation>
==== Shielding.
<shielding.>
Shields are obtained by solving games, for which there exist a wide
selection of tools for discrete state
spaces #cite(label("DBLP:conf/cav/ChatterjeeHJR10")) #cite(label("DBLP:conf/tacas/ChatterjeeHJS11")) #cite(label("DBLP:conf/cav/KwiatkowskaN0S20")).
Notably,
#link("https://tempest-synthesis.org/")[#smallcaps[Tempest]] #cite(label("DBLP:conf/atva/PrangerKPB21"))
synthesizes shields for discrete systems and facilitates learning
through integration with
#smallcaps[Prism] #cite(label("DBLP:conf/cav/KwiatkowskaNP11")).
#smallcaps[Uppaal Tiga] synthesizes shields for timed
games #cite(label("DBLP:conf/cav/BehrmannCDFLL07")).

In contrast, our tool applies to a richer class of models, including
stochastic hybrid systems with non-periodic control and calls to
external C libraries.

One benefit of our tool is the full integration with
Uppaal Stratego #cite(label("DBLP:conf/tacas/DavidJLMT15")) to directly use the
synthesized shield in reinforcement learning.

==== Decision trees.
<decision-trees.>
Encoding strategies as decision trees is a popular approach to achieving
compactness and
interpretability #cite(label("DuLH20")) #cite(label("Quinlan96")) #cite(label("BreimanFOS84")) #cite(label("DBLP:conf/hybrid/AshokJJKWZ20")) #cite(label("DBLP:conf/tacas/AshokJKWWY21")).
However, these works focus on creating approximate representations from
tabular data. For a fixed set of predicates, the smallest possible tree
can be obtained by enumeration
techniques #cite(label("DBLP:journals/jmlr/DemirovicLHCBLR22")) #cite(label("DemirovicSL25")).
In contrast, our method transforms a given decision tree into an
#emph[equivalent] decision tree. Our method is specifically designed to
efficiently cope with strategies of many axis-aligned decision
boundaries.

== Shield Synthesis for Hybrid Systems
<sect:shielding_algorithm>
In this section, we recall a general shield synthesis algorithm for
hybrid systems outlined in prior
work #cite(label("DBLP:conf/vecos/BrorholtJLLS23")). We start by recalling the
formalism for control systems.

=== Euclidean Markov Decision Processes
<euclidean-markov-decision-processes>
#definition[
  A $k$-dimensional #emph[Euclidean Markov decision process]
  (EMDP) is a tuple $cal(M) eq lr((S comma A comma T))$ where

  - $S subset.eq bb(R)^k$ is a closed and bounded subset of the
    $k$-dimensional Euclidean space,

  - $A$ is a finite set of actions, and

  - $T colon S times A arrow.r lr((S arrow.r bb(R)_(gt.eq 0)))$ maps each
    state-action pair $lr((s comma a))$ to a probability density function
    over $S$, i.e., we have
    $integral_(s prime in S) T lr((s comma a)) lr((s prime)) d s prime eq 1$.
]<def:emdp> 

For simplicity, the state space $S$ is continuous. However, the
extension to discrete variables, e.g., locations of hybrid components,
is straightforward. Since optimizing strategies is not our focus, we do
not formally introduce the notion of cost and rely on the reader’s
intuition. (See #cite(label("DBLP:conf/vecos/BrorholtJLLS23")) for details.)

A #emph[run] $pi$ of an EMDP is an alternating sequence
$pi eq s_0 a_0 s_1 a_1 dots.h$ of states and actions such that
$T lr((s_i comma a_i)) lr((s_(i plus 1))) gt 0$ for all $i gt.eq 0$. A
(memoryless) stochastic #emph[strategy] for an EMDP is a function
$sigma^(‾) colon S arrow.r lr((A arrow.r lr([0 comma 1])))$, mapping a
state to a probability distribution over the actions. A run
$pi eq s_0 a_0 s_1 a_1 dots.h$ is an #emph[outcome] of $sigma^(‾)$ if
$sigma^(‾) lr((s_i)) lr((a_i)) gt 0$ for all $i gt.eq 0$. Similarly, a
(memoryless) nondeterministic strategy is a function
$sigma colon S arrow.r 2^A$, mapping a state to a set of actions. A run
$pi eq s_0 a_0 s_1 a_1 dots.h$ is an outcome of $sigma$ if
$a_i in sigma lr((s_i))$ for all $i gt.eq 0$.

A #emph[safety property] (or invariant) $phi$ is a set of states
$phi subset.eq S$. A run $pi eq s_0 a_0 s_1 a_1 dots.h$ is #emph[safe]
with respect to $phi$ if $s_i in phi$ for all $i gt.eq 0$. A
nondeterministic strategy $sigma$ is a #emph[shield] with respect
to $phi$ if all outcomes of $sigma$ are safe.

=== Running Example (Bouncing Ball)
<running-example-bouncing-ball>

#subpar.grid(
  [#figure(image("../Graphics/RP25/Player.pdf", width: 100%) + v(15pt),
    caption: [Player component.]
  )<fig:player>],

  [#figure(image("../Graphics/RP25/Ball.pdf", width: 100%),
    caption: [Ball component.]
  )<fig:ball>],
  columns: (3fr, 6fr),
  caption: [The #emph[bouncing ball] modeled in Uppaal.]
)
<fig:uppaalball>

We introduce our running example: a #emph[bouncing ball] that can be hit
by a player to keep it
bouncing #cite(label("DBLP:conf/vecos/BrorholtJLLS23")) #cite(label("DBLP:conf/atva/JaegerJLLST19")).
We shortly explain our two-component Uppaal model. The player component
is shown in @fig:player. In the (initial) location `Choose`, there
are two available control actions (solid lines). The player chooses
every 0.1 seconds (enforced by the clock `x`). The action (upper edge)
attempts to hit the ball, and increments the cost counter `c` to be used
for reinforcement learning in @sect:bb_queries. The other
action (lower edge) does not attempt to hit the ball.

The ball component, shown in @fig:ball, is described by two
state variables, position `p` and velocity `v`, which evolve according to the
ordinary differential equations shown below the initial location `InAir`. The
two dashed edges on the right model a successful `hit` action, which is only
triggered if the ball is high enough (four meters or higher above the
ground); they differ in whether the ball is currently jumping up or
falling down. The two dashed edges on the left model a `bounce` on the ground.
The ball bounces back up with a random dampening (upper edge) or goes to
the state `Stop` if the velocity is very low (lower edge). In the following, we
shall see how to obtain a shield that enforces the safety property that `Stop`
is never reached, i.e., $phi = { s | #[Ball is not in `Stop` in] s}$.

=== Partition-Based Shield Synthesis
<sect:partitioning>
Since an EMDP consists of infinitely many states, we employ a
finite-state abstraction. For that, we partition the state space
$S subset.eq bb(R)^k$ with a regular #emph[rectangular] grid.
(In #cite(label("DBLP:conf/vecos/BrorholtJLLS23")), we only allowed a grid of
uniform size in all dimensions.) Formally, given a (user-defined)
granularity vector $gamma in bb(R)^k$ and offset
vector $omega in bb(R)^k$, we partition the state space into disjoint
#emph[cells] of equal size. Each cell $C$ is the Cartesian product of
half-open intervals
$bracket.l omega_i plus p_i gamma_i semi med omega_i plus lr((p_i plus 1)) gamma_i bracket.l$
in each dimension $i$, for cell index $p in bb(N)^k$. We define the
#emph[grid] as the set
$cal(P)_gamma^omega eq brace.l C divides C inter S eq.not nothing brace.r$
of all cells that overlap with the bounded state space. Note the number
of cells will depend on $gamma$. For each $s in S$,
$lr([s])_(cal(P)_gamma^omega)$ denotes the unique cell containing $s$.

An EMDP $cal(M)$, a granularity vector $gamma$ and offset vector $omega$
induce a finite labeled transition system
$cal(T)_(cal(M) comma gamma comma omega) eq lr((cal(P)_gamma^omega comma A comma arrow.r))$,
where
$ C arrow.r_()^a C prime arrow.l.r.double exists s in C dot.basic med exists s prime in C prime dot.basic med T lr((s comma a)) lr((s prime)) gt 0 dot.basic $<eq:cell_reachability>

Given a safety property $phi subset.eq S$ and a
grid $cal(P)_gamma^omega$, let
$cal(C)_phi^0 eq brace.l C in cal(P)_gamma^omega divides C subset.eq phi brace.r$
denote those cells that are safe in zero steps. We define the set of
#emph[safe cells] as the maximal set $cal(C)_phi$ such that

$ cal(C)_phi eq cal(C)_phi^0 inter brace.l C in cal(P)_gamma^omega divides exists a in A dot.basic med forall C prime in cal(P)_gamma^omega dot.basic med C arrow.r^a C prime arrow.r.double.long C prime in cal(C)_phi brace.r dot.basic $ <eq:safecells>

Given the finiteness of $cal(P)_gamma^omega$ and monotonicity of
@eq:safecells, $cal(C)_phi$ may be obtained in
a finite number of iterations using Tarski’s fixed-point
theorem #cite(label("Tarski55")).

A (nondeterministic) strategy for
$cal(T)_(cal(M) comma gamma comma omega)$ is a function
$nu colon cal(P)_gamma^omega arrow.r 2^A$. The most permissive
shield $nu_phi$ (i.e., safe strategy) obtained from
$cal(C)_phi$ #cite(label("BernetJW02")) is given by
$ nu_phi lr((C)) eq brace.l a in A divides forall C prime in cal(P)_gamma^omega dot.basic med C arrow.r^a C prime arrow.r.double.long C prime in cal(C)_phi brace.r dot.basic $

A shield $nu$ for $cal(T)_(cal(M) comma gamma comma omega)$ induces a
shield $sigma$ for $cal(M)$ in the standard
way #cite(label("DBLP:conf/vecos/BrorholtJLLS23")):

<thm:safety_transfer> Given an EMDP $cal(M)$, a safety
property $phi subset.eq S$, and a grid $cal(P)_gamma^omega$, if $nu$ is
a shield for $cal(T)_(cal(M) comma gamma comma omega)$, then
$sigma lr((s)) eq nu lr((lr([s])_(cal(P)_gamma^omega)))$ is a shield
for $cal(M)$.

#figure(image("../Graphics/RP25/workflow.svg"),
  caption: [Workflow for obtaining a near-optimal shielded strategy in Uppaal.]
)<fig:workflow>

@fig:workflow shows the overall workflow of the shield
synthesis and how the shield can later be used to (reinforcement-) learn
a near-optimal strategy #emph[under this shield]. The green box marks
the steps that we newly integrated in Uppaal.

For the #emph[bouncing ball], we will obtain the shield shown in
@fig:leave_bounds. To effectively implement the
aforementioned approach, there are additional challenges which we
address in the following section.
#subpar.grid(
  [#figure(image("../Graphics/RP25/BB.svg"),
    caption: [
      It is safe to leave the bounds.
    ]
  )<fig:leave_bounds>],

  [#figure(image("../Graphics/RP25/BB_constrained_to_grid.svg"),
    caption: [
      It is unsafe to leave the bounds.
    ]
  )<fig:stay_in_bounds>],
  columns: 2,
  caption: [
    Two shields for the #emph[bouncing ball]. Colors represent the
    allowed actions in the corresponding state of velocity $v$ and
    position $p$ while in location `InAir`.
  ],
  label: <fig:bbshields>
)

== Effective Implementation of Shield Synthesis
<sect:shielding_implementation>
In this section, we discuss our implementation of the approach to
synthesize a shield as outlined in @sect:shielding_algorithm
in #smallcaps[Uppaal Coshy]. In particular, a practical implementation
faces the following two main challenges.

First, we receive the safety property $phi$ in the form of a user query
(see @sect:bb_queries). Thus, the definition of the
cells $cal(C)_phi^0$ that are immediately safe generally requires
symbolic reasoning, which is not readily available. Instead, we check a
finite number of states within each cell, which we describe in
@sect:initial_safe.

Second, determining
@eq:cell_reachability requires to
solve reachability questions for infinitely many states. While this can
be done for simple classes of systems, we deal with very general systems
(e.g., nonlinear hybrid dynamics), for which reachability is
undecidable #cite(label("DFPP18")). This motivated us to instead compute an
approximate solution, which we outline in
@sect:reachability.

Thanks to the above design decisions, our implementation is fully
automatic and supports the expressive formalism of general Uppaal models
(e.g., stochastic hybrid automata with calls to general C code).

We also identified further practical challenges, which we address in the
later parts of this section. @def:emdp requires a
bounded state space, but it is for instance difficult to determine upper
bounds for the position and velocity of the #emph[bouncing ball]; in
@sect:unbounded, we explain how we treat such cases in
practice. In @sect:missing_variables, we discuss an
optimization to omit redundant dimensions.

=== Determining Initial Safe Cells
<sect:initial_safe>
We apply #emph[systematic sampling] from a cell, i.e., samples are not
drawn at random. Rather, we uniformly cover the cell with $n^k$ samples,
where $n in bb(N) comma n eq.not 0$ is a user-defined parameter. Recall
from @sect:partitioning that a cell $C$ of a
grid $cal(P)_gamma^omega$ is rectangular and defined by an index
vector $p$, an offset $omega$ and a granularity vector $gamma$, all of
dimension $k$. Let $delta_i eq frac(gamma_i, n minus 1)$ be the distance
between two samples in dimension $i$ when $n gt 1$, and $delta_i eq 0$
otherwise. For any cell, we define the corresponding set of samples as
$lr({lr((omega_1 plus p_1 gamma_1 plus q_1 delta_1 comma dots.h comma omega_k plus p_k gamma_k plus q_k delta_k)) divides q_i in brace.l 0 comma 1 comma dots.h comma n minus 1 brace.r})$.
To account for the open upper bounds, we subtract a small number
$epsilon.alt gt 0$ from the highest samples. An example of a
two-dimensional set of samples for $n eq 4$ is shown as the dark blue
points inside the light blue cells in @fig:reachability.

We note that the above only applies to continuous variables. Our
implementation treats discrete variables (e.g., component locations) in
the natural way.

Finally, to approximate the set $cal(C)_phi^0$, we draw samples from
each cell and check for each sample whether it violates the
specification. A cell is added to $cal(C)_phi^0$ only if all samples in
that cell satisfy the specification.

For the #emph[bouncing ball], the ball should never be in the `stop` location.
Since the location is a discrete variable, and each cell only belongs to
one location, checking a single sample from a cell $C$ already
determines whether $C in cal(C)_phi^0$. Thus, our approach is exact and
efficient in the common case where the safety property is given via an
error location.

=== Determining Reachability
<sect:reachability>
We approximate cell reachability $C arrow.r^a C prime$, as defined in
@eq:cell_reachability, similarly
to #cite(label("DBLP:conf/vecos/BrorholtJLLS23")) but adapted to work in
Uppaal. In a Uppaal model, actions $a in A$ correspond to controllable
edges (indicating that the controller can act).

For each cell $C$ and action $a in A$, we iterate over all sampled
states $s$ (as described before) and select the edge corresponding to
$a$, which gives us a new state $s prime$; starting from $s prime$, we
simulate the environment (using the built-in simulator in Uppaal) until
a state $s prime.double$ is reached in which the controller has the next
choice (i.e., multiple action edges are enabled) again.
#footnote[Where #cite(label("DBLP:conf/vecos/BrorholtJLLS23")) required a fixed
control period, #smallcaps[Uppaal Coshy] supports non-periodic control.
This is demonstrated in #cite(label("arxiv_version")).] Thus, $s prime.double$
is a witness to add the corresponding
cell $lr([s prime.double])_(cal(P)_gamma^omega)$ to the transition
relation $C arrow.r^a lr([s prime.double])_(cal(P)_gamma^omega)$.
Assuming the simulator is numerically sound, the resulting transition
system underapproximates $cal(T)_(cal(M) comma gamma comma omega)$. As
observed in #cite(label("DBLP:conf/vecos/BrorholtJLLS23")), the more
simulations are run, the more likely do we obtain the true solution. To
check whether this underapproximation is sufficiently accurate, the
existing queries for statistical model checking in Uppaal can be used,
as we shall see in @sect:evaluation.

In general, two simulations starting in the state $s$ may not yield the
same state $s prime.double$ due to stochasticity.
In #cite(label("DBLP:conf/vecos/BrorholtJLLS23")), stochasticity was treated as
additional dimensions over which to sample (systematically). This was
possible by manually crafting the reachability sampling for each model.
Detecting stochastic behavior in Uppaal models automatically turned out
to be difficult due to the rich formalism. Instead, we decided to simply
let the simulator sample from the stochastic distribution. As a side
effect, this new design allows us to support stochasticity with general
distributions, particularly with unbounded support.

Since this design may generally miss some corner-case behavior, we
expose a user-defined parameter $m$ to control the number of times
sampling is repeated.

#subpar.grid(
  [#figure(image("../Graphics/RP25/Reachability1.svg", width: 100%),
    caption: [
      The ball is rising and high enough to be hit. When the ball is
      hit, the outcome is partially random.
    ]
  )<fig:reachabilityA>],

  [#figure(image("../Graphics/RP25/Reachability2.svg", width: 100%),
    caption: [
      The ball is too low to be hit, but it bounces off the ground. The
      velocity loss upon a bounce is partially random.
    ]
  )<fig:reachabilityB>],
  columns: 2,
  caption: [
    Example of a grid for the #emph[bouncing ball]. By sampling from the
    initial cell (blue) and simulating the dynamics, we discover
    reachable cells (green).
  ],
  label: <fig:reachability>
)

We illustrate the reachability approximation for the #emph[bouncing
ball] in @fig:reachability for $n eq 4$ (number of samples
per dimension) and $m eq 1$ (number of re-sampling). When the ball moves
through the air, it behaves deterministically. In
@fig:reachabilityA, when the ball is not hit, we obtain
successor states that keep a regular "formation" (top right green dots).
When the ball is hit, the successor states are affected by randomness
(bottom left green dots). @fig:reachabilityB shows a similar
randomized effect when the ball touches the ground.

=== Generalization to Unbounded State Spaces
<sect:unbounded>
@def:emdp requires the state space to be bounded,
but bounds can be hard to determine for some systems. This includes the
#emph[bouncing ball], for which upper bounds for position and velocity
are not immediately clear. Indeed, if we consider the bounded state
space where $p in lr([0 semi 11])$ and $v in lr([minus 13 semi 13])$,
the system dynamics do not guarantee that the ball stays within these
bounds. If we plot velocity against position, as in
@fig:bbshields, then a falling ball near the left end of the
plot may leave the bounds on the left (because it becomes too fast).

Conceptually, our implementation deals with out-of-bounds situations by
modifying the transition system. All samples leading to a state outside
the specified bounds go to a dummy cell $C_(italic("out"))$, for which
all transitions lead back to itself. A user-defined option with the
following choices determines the behavior:


#pseudocode-list[
  + Raise an error when reaching $C_(italic("out"))$ during simulation (default behavior).
  + #line-label(<it:always_safe>) Include $C_(italic("out"))$ in $C_phi^0$, i.e., leaving the bounds is always safe.
  + #line-label(<it:always_unsafe>) Exclude $C_(italic("out"))$ from $C_phi^0$, i.e., leaving the bounds is always unsafe.
  + #line-label(<it:auto>) Automatically choose between @it:always_safe and @it:always_unsafe using sampling.
]

With @it:auto, samples are taken outside the
specified bounds, similar to @sect:initial_safe. For the
#emph[bouncing ball], our tool samples states such as $paren.l v eq 26$,
$p eq 22$, #convertme[\$\\color{blue}{\\tt{Ball.Stop}})\$], even though these states
may not be reachable in practice. If any sample state is found to be
unsafe, $C_(italic("out"))$ is considered unsafe, and safe otherwise.
The result of synthesizing a shield with this option is shown in
@fig:stay_in_bounds. In particular, that shield forbids to
hit the ball when it is too fast, which ensures that it does not leave
the bounds. Alternatively, we obtain a more permissive shield by
choosing @it:always_safe, as shown
in @fig:leave_bounds.

=== Omitting Variables from Consideration
<sect:missing_variables>
As emphasized in #cite(label("DBLP:conf/aaai/AlshiekhBEKNT18")), a shield can
be obtained from an abstract model that only simulates behaviors
relevant to the safety specification. For example, cost variables may
only be relevant during learning. While every variable in a model can be
included in the partitioning, this is computationally demanding.

Therefore, we allow that variables are omitted from the grid
specification. However, this raises a new challenge when sampling a
state from a cell, since a concrete state requires a value for each
variable. To address that, we set each omitted variable to the unique
value of the initial state, which must always be specified in a Uppaal
model. Hence, the user must define the initial state such that the
values of omitted variables are sensible defaults. (Note that the
initial state is ignored by the shield synthesis in all other respects.)

The choice not to include a variable in the grid must be made carefully,
as this can change the behavior of the transition system and potentially
lead to an unsound shield. As a rule of thumb, it is appropriate to omit
variables if they always have the same value when actions are taken, or
if they are only relevant for keeping track of a performance value such
as cost.

For the #emph[bouncing ball], the player (@fig:player) is
always in the location `Choose` when taking an action. By setting `Choose` as the initial
location, this component’s location is not relevant to keep track of in
the partitioning. Moreover, the variable  is used to keep track of cost
and does not matter to safety. Lastly, the clock variable  is used to
measure time until the next player action. It is always $0$ when it is
time for the player to act, and so it can also be omitted.

== Obtaining a Compact Shield Representation
<sec:maxParts>
In this section, we present a new technique for obtaining a compact
representation of shields that stem from an axis-aligned state-space
partitioning (as described in @sect:partitioning). Here, we
choose to represent the shield as a decision tree. We note that we aim
for a functionality-preserving representation, i.e., we transform a
grid-based shield to an equivalent decision-tree-based shield.

Recall that each cell prescribes a set of allowed actions. Let two cells
be #emph[similar] if the shield assigns the same set of actions to them.
Our goal is to form (hyper)rectangular clusters of similar cells, which
we call #emph[regions]; in other words, we aim to find a coarser
partitioning. In a nutshell, our approach works as follows. Initially,
we start from the finest partitioning where each cell is a separate
region. Then, we iteratively merge neighboring regions of similar cells,
thereby obtaining a coarser partitioning, such that the resulting region
is rectangular again. We call our algorithm
#smallcaps[Caap] (#strong[C]oarsify #strong[A]xis-#strong[A]ligned #strong[P]artitionings).

=== Representation of Partitionings and Regions
<representation-of-partitionings-and-regions>
We start by noting that an axis-aligned partitioning of a state space
$S subset.eq bb(R)^k$ can be represented by a binary decision
tree $cal(T)$ where each leaf node is a set of actions and each inner
node splits the state space with a predicate of the form
$rho lr((s)) eq s_i lt c$, where $s$ is a state vector, $s_i$ is a state
dimension, and $c in bb(R)$. Given a state $s$, the tree evaluation,
written $cal(T) lr((s))$, is defined as usual: Start at the root node.
At an inner node, evaluate the predicate $rho lr((s))$. If
$rho lr((s)) eq top$, descend to the left child; otherwise, descend to
the right child. At a leaf node, return the corresponding set of
actions. We denote the partitioning induced by a decision tree $cal(T)$
as $cal(P)_(cal(T))$. Our goal in this section is: given a decision tree
$cal(T)$ inducing a partitioning $cal(P)_(cal(T))$, find an equivalent
but smaller decision tree.

#figure(table(columns: 5,
    [],    [1], [2], [3], [4],
    $s_1$, [0], [2], [3], [4],
    $s_2$, [0], [2], [3], [4]
  ),
  caption: [Example of matrix $M$ for @fig:expRulesOrg]
)<tab:matrixm>
  
Given a tree $cal(T)$, we store all bounds $c$ of the predicates
$s_i lt c$ in a matrix $M$ of $k$ rows where the $i$-th row contains the
bounds associated with state dimension $s_i$ in ascending order. For
example, consider the bounds in @fig:expRulesOrg and $M$ in @tab:matrixm.

We extract a bounds vector from $M$ via an index vector $p in bb(N)^k$
such that the $i$-th entry of $p$ contains the column index for the
$i$-th row. In other words, the resulting vector consists of the
values $M_(i comma p_i)$. For instance, $p eq lr((1 comma 3))$ yields
the vector $s^p eq lr((0 comma 3))$ (row $s_1$ column $1$ and row $s_2$
column $3$). We can view this vector as a state in the state space given
as $s^p eq lr((M_(1 comma p_1) comma dots.h comma M_(k comma p_k)))$.

We define a region $R$ in terms of two index vectors
$lr((p^min comma p^max))$ representing the minimal and maximal corner in
each dimension. Then, increasing $p_i^max$ corresponds to expanding $R$
in dimension $i$.

=== Expansion of Rectangular Regions
<expansion-of-rectangular-regions>
For an expansion to be legal, it must satisfy the following three
#emph[expansion rules]:

#definition[Let $R prime$ be a candidate region for a new
  partitioning $cal(P) prime$ derived from $cal(P)_(cal(T))$. Then
  $R prime$ is legal if it satisfies these three rules:

  #pseudocode-list[
    + #line-label(<it:rule1>) All cells in region $R prime$ have the same action set,

    + #line-label(<it:rule2>) Region $R prime$ does not intersect with other regions in
      $cal(P) prime$,

    + #line-label(<it:rule3>) Region $R prime$ does not cut any other region $R$ from the
      original partitioning $cal(P)_(cal(T))$ in two, i.e., the difference
      $R backslash R prime$ is either empty or rectangular.
  ]
]<def:expansionRules> 

#subpar.grid(columns: 2,
  align: top,
  [#figure([#image("../Graphics/RP25/rules_org.svg", width: 100%)],
    caption: [An input partitioning.]
  )<fig:expRulesOrg>],

  [#figure([#image("../Graphics/RP25/rule1.svg", width: 100%)],
    caption: [A violation of @it:rule1[Rule], since the expanded region contains different actions.  ]
  )<fig:expRules1>],

  [#figure([#image("../Graphics/RP25/rule2.svg", width: 100%)],
    caption: [A violation of @it:rule2[Rule], since the expanded region overlaps with a striped area.]
  )<fig:expRules2>],

  [#figure([#image("../Graphics/RP25/rule3.svg", width: 100%)],
    caption: [A violation of @it:rule3[Rule], since the expansion cuts the rightmost region into two new regions.]
  )<fig:expRules3>],
  caption: [Expansion example. Yellow and purple denote distinct actions.
    Striped regions have been fixed in previous iterations.
    The dashed border is the new candidate region $R'$.
  ]
)

The first two cases are directly related to the definition of the
problem, i.e., the produced partitioning should respect $cal(T)$ and
only have non-overlapping regions (see @fig:expRules1 and
@fig:expRules2). The third case is required in order to
ensure that in each iteration, the algorithm does not increase the
overall number of regions when adding a region from the original
partitioning to the new partitioning. To appreciate this, consider the
visualization in @fig:expRules3. The candidate expansion
cuts the rightmost region (given by $lr((3 comma 0))$ and
$lr((4 comma 4))$) in two such that the remainder would have to be
represented by #emph[two] regions — one given by
$lr((lr((3 comma 0)) comma lr((4 comma 2))))$ and one given by
$lr((lr((3 comma 3)) comma lr((4 comma 4))))$. Clearly, all three
expansion rules of @def:expansionRules
can be checked in time linear in the number of nodes
of $cal(P)_(cal(T))$.

To determine the expansion of regions, we propose the following greedy
approach: let $lr((p^min comma p^max))$ define a region. We then want to
find a vector $Delta_p in bb(Z)^k$ such that
$lr((p^min comma p^min plus Delta_p))$ defines a region that obeys the
three expansion rules and is (locally) maximal, in the sense that
increasing it in any dimension would violate at least one of the
expansion rules. Note that a vector $Delta_p eq p^max minus p^min$
satisfies the expansion rules trivially but is possibly not maximal.
Thus, a solution is guaranteed to exist. However, note that there is not
necessarily a unique maximal solution, and that the set of solutions is
not convex, i.e., there may exist solutions $Delta_p^1$ and $Delta_p^2$
such that $Delta_p^1 lt.eq Delta_p^2$ but no other $Delta_p prime$ with
$Delta_p^1 lt.eq Delta_p prime lt.eq Delta_p^2$ satisfies the expansion
rules. Formally:

#definition[
  Given $p^min in bb(Z)^k$, a decision tree $cal(T)$ over a
  $k$-dimensional state space, and a set $cal(P)$ of fixed regions,
  $Delta_p in bb(Z)^k$ is a vector such that for
  $p^max eq p^min plus Delta_p$ the region $R eq lr((p^min comma p^max))$
  does not violate any of the expansion rules in
  @def:expansionRules and for any vector
  $Delta prime_p eq lr((Delta_(p_1) comma dots.h comma Delta_(p_i) plus 1 comma dots.h comma Delta_(p_k)))$
  at least one of the rules is violated.
]<def:deltaP> 

Our greedy approach to finding $Delta_p$ starts with
$Delta_p eq p^max minus p^min$ for some region
$R eq lr((p^min comma p^max))$. It then iteratively selects a
dimension $d$ by a uniformly random choice and attempts to increment the
$d$-th entry of $Delta_p$. For that, we define the candidate region
$R prime eq lr((p^min comma p^min plus Delta_p))$ and check the
@it:rule1
@it:rule2. If any of them is violated, we mark
the corresponding dimension $d$ as exhausted, roll back the increment,
and continue with a new dimension not marked as exhausted yet, until
none is left.

As mentioned above, the set of solutions is not convex. Correspondingly,
if @it:rule3 is violated, the algorithm
initiates an attempt at #emph[repairing] the candidate expansion by
continuing the expansion to the largest bound in the expansion dimension
of any of the broken regions. This way, we check whether the violation
can be overcome by simply expanding more aggressively. When all
dimensions have been exhausted, $Delta_p$ adheres to
@def:deltaP.

We note that the algorithm is not guaranteed to find a local optimum.
One reason is that the repair only expands in one dimension. This choice
is deliberate to keep the algorithm efficient and avoid a combinatorial
explosion. A more detailed description including pseudocode can be found
in #cite(label("arxiv_version")).

== Case Studies and Evaluation
<sect:evaluation>
In this section, we evaluate our implementation of #smallcaps[Uppaal
Coshy] and #smallcaps[Caap]. In @sect:bb_queries, we
demonstrate a typical application. In @sect:benchmarks, we
benchmark the implementations on several models.

=== A Complete Run of the Bouncing Ball <sect:bb_queries>


#[
  #set par(justify: false)
  #set table(
    fill: (_, y) => (none, cmyk(0%, 0%, 0%, 4%)).at(calc.rem(y, 2))
  )

  #show regex("acontrol"): set text(fill: emerald, weight: "bold")
  #show regex("minE"): set text(fill: nephritis, weight: "bold")
  #show regex("saveStrategy"): set text(fill: nephritis, weight: "bold")
  #show regex("loadStrategy"): set text(fill: nephritis, weight: "bold")
  #show regex("simulate"): set text(fill: nephritis, weight: "bold")
  #show regex("Pr"): set text(fill: nephritis, weight: "bold")
  #show regex("E"): set text(fill: nephritis, weight: "bold")
  #show regex("strategy"): set text(fill: nephritis)
  #show regex("under"): set text(fill: nephritis)
  #show regex("max:"): set text(fill: nephritis)
  #show regex("\".*\""): set text(fill: carrot)
  #show regex("\d+"): set text(fill: black)
  
  

  #figure(table(
      columns: 3,
      align: (col, row) => (right,left,left,).at(col),
      inset: 6pt,
      table.header([#strong[\#]], [#strong[Query]], [#strong[Result]]),
      [1], [```
      strategy efficient 
        = minE(c) [<=120] {} -> {v, p} : <> time>=120
      ```], [$checkmark$],

      [2], [``` simulate [<=120]{ p, v } under efficient```], [$checkmark$],
      [3], [``` E[<=120;100] (max: c) under efficient```], [$approx 0$],
      [4], [``` Pr[<=120;10000] (<> Ball.Stop) under efficient```], [$lr([0.9995 semi 1])$],

      [5], [``` 
      strategy shield = acontrol: A[] !Ball.Stop 
        { v[-13, 13]:1300, p[0, 11]:550, Ball.location }
      ```], [$checkmark$],

      [6], [``` saveStrategy("shield.json", shield)```], [$checkmark$],
      [7], [``` 
      strategy compact_shield = 
        loadStrategy("compact.json")
      ```], [$checkmark$],
      [8], [``` simulate [<=120]{ p, v }  under compact_shield```], [$checkmark$],

      [9], [``` 
      strategy shielded_efficient = minE(c) [<=120] 
        {} -> {v, p} : <> time>=120 under compact_shield
      ```], [$checkmark$],

      [10], [``` simulate [<=120]{ p, v } under shielded_efficient```], [$checkmark$],
      [11], [``` E[<=120;100] (max: c) under shielded_efficient```], [$34.6 plus.minus 0.6$],

      [12], [``` 
      Pr[<=120;10000] (<> Ball.Stop) 
        under shielded_efficient
      ```], [$lr([0 semi 0.00053])$],
    ),
    caption: [Queries run on the #emph[bouncing ball] model. New query
      type highlighted. All statistical results are given with a 99%
      confidence interval.],
  )<tab:bb_queries>
]
@tab:bb_queries shows a typical usage of Uppaal with a
sequence of queries on the #emph[bouncing ball] example to produce a
safe and efficient strategy (cf. @fig:workflow).
Documentation of the new query syntax is available online and
in #cite(label("arxiv_version")).
#footnote[#link("https://docs.uppaal.org/language-reference/query-syntax/controller_synthesis/#approximate-control-queries")[https://docs.uppaal.org/language-reference/query-syntax/controller\_synthesis/\#approximate-control-queries]]

In Query 1, we train a strategy called , which is only concerned with
cost and does not consider safety. Such a strategy is trivial: simply
never pick the `hit` action. This is seen in Query 2, which simulates a single
run of 120 seconds. It outputs position  and velocity , which are
visualized in @fig:efficient. Query 3 statistically
evaluates the strategy in 100 runs to estimate the expected value of .
The result "$approx 0$" indicates that only this value was observed.
Query 4 estimates the probability of a run being unsafe to be in the
interval $lr([0.9995 semi 1])$ with 99% confidence; in this case, as
expected, all $10 thin 000$ runs were unsafe.

Query 5 synthesizes a shield . The shield matches the one shown in
@fig:leave_bounds. In queries 6 and 7, the shield is
converted to a compact representation by saving it to a file, calling
the #smallcaps[Caap] implementation, and loading the result back into
Uppaal. The shield is simulated in Query 8, for which any of the allowed
actions is selected randomly (this happens implicitly); while safe, this
shielded but randomized strategy is not efficient and hits the ball more
often than needed, as visualized in @fig:safe.

In Query 9, we learn a strategy `shielded efficient` under the shield using
Uppaal Stratego #cite(label("DBLP:conf/tacas/DavidJLMT15")). This strategy
keeps the ball in the air without excessive hitting, as shown by the
output of Query 10 in @fig:shielded_efficient. The result of
Query 11 shows the expected cost, and Query 12 shows that the safety
property holds with high confidence: None of the $10 thin 000$ runs were
unsafe.

=== Further Examples
<sect:benchmarks>
#subpar.grid(columns: 3,
  [#figure([#image("../Graphics/RP25/under_efficient.png", width: 100%)],
    caption: [ `efficient` ]
  )<fig:efficient>],

  [#figure([#image("../Graphics/RP25/under_safe.png", width: 100%)],
    caption: [ `compact_shield` ]
  )<fig:safe>],

  [#figure([#image("../Graphics/RP25/under_safe_and_efficient.png", width: 100%)],
    caption: [ `shielded_efficient` ]
  )<fig:shielded_efficient>],

  caption: [
    #emph[Bouncing ball] simulations (position, velocity) under
    different strategies.
  ],
  label: <fig:simulate>
)

State-space transformations can be used to synthesize a shield more
efficiently #cite(label("DBLP:conf/vecos/BrorholtHLS24")). Since Uppaal
supports function calls, transformations can be applied by modifying the
model. Details can be found in #cite(label("arxiv_version")).

Next, we show quantitative results of the shield synthesis and
subsequent shield reduction, for which we also use three additional
models. Firstly, the #emph[boost
converter] #cite(label("DBLP:conf/vecos/BrorholtJLLS23")) models a real circuit
for stepping up the voltage of a direct current (DC) input. The
controller must keep the voltage close to a reference value, without
exceeding safe bounds for the voltage and current. The state space is
continuous, with significant random variation in the outcome of actions.

In the #emph[random walk]
model #cite(label("DBLP:conf/vecos/BrorholtJLLS23")) #cite(label("DBLP:conf/isola/Jaeger0BLJ20")),
the player must travel a certain distance before time runs out by
choosing between a fast but expensive and a slow but cheap action. The
state space is continuous and the outcomes of actions follow uniform
distributions.

In the #emph[water tank] model inspired
from #cite(label("DBLP:conf/aaai/AlshiekhBEKNT18")), a tank must be kept from
overflowing or running dry. Water flows from the tank at a rate that
varies periodically. At each time step, the player can control the
inflow by switching a pump on or off. The state space is discrete.

We show results for computing and reducing shields in
@tab:evaluation. The #emph[water tank] is fully
deterministic, and the #emph[bouncing ball] only has low-variance
stochastic behavior. The #emph[boost converter] and #emph[random walk]
have a high variance in action outcomes, which is why we use $m eq 20$
simulation runs per sampled state. We evaluated the shields
statistically and found no unsafe runs in $10 thin 000$ trials. The
reduction yields significantly smaller representations at acceptable run
time.

#figure(table(
    columns: 7,
    align: (col, row) => (left,center,right,right,right,right,right,).at(col),
    inset: 6pt,
    [#strong[Model]], [#strong[$n$]], [#strong[$m$]], [#strong[Synthesis
    time]], [#strong[Size]], [#strong[Reduction time]], [#strong[Reduced
    size]],
    [Bouncing ball],
    [3],
    [1],
    [218s],
    [1 430 000],
    [53s],
    [2972],
    [Boost converter],
    [3],
    [20],
    [1 430s],
    [136 800],
    [21s],
    [571],
    [Random walk],
    [4],
    [20],
    [82s],
    [40 000],
    [1.5s],
    [60],
    [Water tank],
    [3],
    [1],
    [0.1s],
    [168],
    [0.1s],
    [24],
  ),
  caption:[Computation time and sizes for synthesizing and reducing
  shields for three models. The original size is the number of cells,
  whereas the reduced size is the number of regions. All shields were
  statistically evaluated to be at least 99.47% safe with a confidence
  interval of 99% (no unsafe runs observed).]
)<tab:evaluation>

== Conclusion
<conclusion>
We have described our implementation of the shield synthesis algorithm
from #cite(label("DBLP:conf/vecos/BrorholtJLLS23")) in the tool
#smallcaps[Uppaal Coshy]. Our tool can work with rich inputs modeled in
Uppaal. We have also presented the #smallcaps[Caap] algorithm to reduce
the shield representation significantly, which is crucial for deployment
on an embedded device.

We see several directions for future integration into Uppaal. As
discussed, our implementation does not apply #emph[systematic] sampling
for random dynamics; however, we think that many sources of randomness
in Uppaal models can be handled systematically. Currently, the reduction
algorithm #smallcaps[Caap] is implemented as a standalone tool, but it
would be useful to also integrate it directly with Uppaal. During
development, we found it helpful to visualize shields, as in
@fig:bbshields, which could be offered in the user interface.
In the same line, an explanation why a state is marked unsafe in a
shield would help in debugging a model.


This research was partly supported by the Independent Research Fund
Denmark under reference number 10.46540/3120-00041B and the Villum
Investigator Grant S4OS under reference number 37819.

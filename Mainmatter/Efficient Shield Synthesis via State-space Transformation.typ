#import "../Config/Macros.typ" : *
#import "@preview/subpar:0.2.2"

#import "@preview/lemmify:0.1.8": *
#let (
  theorem, lemma, corollary,
  remark, proposition, example,
  proof, rules: thm-rules
) = default-theorems("thm-group", lang: "en", thm-numbering: thm-numbering-linear)

#import "@preview/alexandria:0.2.2": *
#show: alexandria(prefix: "B:", read: path => read(path))

= Efficient Shield Synthesis via State-space Transformation
#grid(columns: (1fr, 1fr), row-gutter: 2em,
  [Asger Horn Brorholt \
  _Department of Computer Science \ Aalborg University, Aalborg, Denmark_],

  [Andreas Holck Høeg-Petersen \
  _Department of Computer Science \ Aalborg University, Copenhagen, Denmark_],

  [Kim Guldstrand Larsen \
  _Department of Computer Science \ Aalborg University, Aalborg, Denmark_],

  [Christian~Schilling \
  _Department of Computer Science \ Aalborg University, Aalborg, Denmark_])

#v(1fr)

#heading(level: 2, numbering: none)[Abstract]
We consider the problem of synthesizing safety strategies for control systems, also known as shields. Since the state space is infinite, shields are typically computed over a finite-state abstraction, with the most common abstraction being a rectangular grid. However, for many systems, such a grid does not align well with the safety property or the system dynamics. That is why a coarse grid is rarely sufficient, but a fine grid is typically computationally infeasible to obtain. In this paper, we show that appropriate state-space transformations can still allow to use a coarse grid at almost no computational overhead. We demonstrate in three case studies that our transformation-based synthesis outperforms a standard synthesis by several orders of magnitude. In the first two case studies, we use domain knowledge to select a suitable transformation. In the third case study, we instead report on results in engineering a transformation without domain knowledge.

#pagebreak(weak: true)

== Introduction
<introduction>
Cyber-physical systems are ubiquitous in the modern world. A key
component in these systems is the digital controller. Many of these
systems are safety critical, which motivates the use of methods for the
automatic construction of controllers. Unfortunately, this problem is
intricate for any but the simplest
systems #cite(label("B:LewisVS12")) #cite(label("B:DoyleFT13")).

Two main methods have emerged. The first method is #emph[reinforcement
learning] (RL) #cite(label("B:BusoniuBTKP18")), which provides convergence to an
optimal solution. However, the solution lacks formal guarantees about
safety. The second method is #emph[reactive synthesis], which constructs
a nondeterministic control strategy that is guaranteed to be safe.
However, the solution lacks optimality for secondary objectives.

#figure(image("../Graphics/AISOLA24/Shielding.svg"),
  caption: [
    Reinforcement learning under a shield with a transformation $f$.
  ]
)
<fig:shielding>

Due to their complementary strengths and drawbacks, these two methods
have been successfully combined in the framework of
#emph[shielding] #cite(label("B:DavidJLLLST14")) #cite(label("B:BloemKKW15"))
(cf. @fig:shielding). Through reactive synthesis, one
first computes a nondeterministic control strategy called a
#emph[shield], which is then integrated in the learning process to
prevent unsafe actions. This way, safety is guaranteed and, at the same
time, RL can still provide optimality with respect to the secondary
objectives.

In this work, we focus on the first step: synthesis of a shield. For
infinite state spaces, we employ an abstraction technique based on
state-space partitioning, where we consider the common case of a
#emph[hyperrectangular grid] #cite(label("B:Girard12")) #cite(label("B:Tabuada09")). This grid
induces a finite-state two-player game, from which we can then construct
the most permissive shield with standard algorithms. The downside of a
grid-based approach is that a grid often does not align well with the
dynamics of the system, which causes the game to have many transitions
and thus results in an overly conservative control strategy. To counter
this effect, one can refine the partition, but this has severe
computational cost and quickly becomes infeasible.

The key insight we follow in this work is that a #emph[state-space
transformation] can yield a new state space where the grid aligns much
better with the system dynamics. As we show in three case studies, the
transformation allows to reduce the grid significantly, often by several
orders of magnitude. In extreme cases, no grid may exist for
synthesizing a control strategy in the original state space, while a
simple grid suffices in the transformed state space.

We show that our transformation-based shield synthesis is sound, i.e.,
the guarantees of the shield transfer to the original system. Moreover,
our experiments demonstrate that the transformation does not reduce the
performance of the final controller (in fact, the performance slightly
increases).

Our implementation is based on our previous work on sampling-based
shield synthesis #cite(label("B:PaperA")). The present work integrates
nicely with such a sampling-based method, but also generalizes to
set-based methods.

For the first two case studies, we employ domain knowledge to derive a
suitable transformation. For the third case study, we instead apply a
new heuristic method to synthesize a suitable transformation.

=== Related Work
<related-work>
Abstraction-based controller synthesis is a popular approach that
automatically constructs a controller from a system and a
specification #cite(label("B:Girard12")) #cite(label("B:Tabuada09")). The continuous dynamics
are discretized and abstracted by a symbolic transition system, for
which then a controller is found. The most common abstraction is a
regular hyperrectangular (or even hypercubic) grid. The success of this
approach depends on the choice of the grid cells’ size. If too small,
the state space becomes intractably large, while if too large, the
abstraction becomes imprecise and a controller may not be found. While
the cell size can be optimized #cite(label("B:WeberRR17")), a fixed-sized grid is
often bound to fail. Instead, several works employ multiple layers of
different-sized grids in the hope that coarser cells can be used most of
the time but higher precision can still be used when
necessary #cite(label("B:GirardGM16")) #cite(label("B:HsuMMS18a")). In this paper, we follow an
orthogonal approach. We argue that a hyperrectangular grid is often
inappropriate to capture the system dynamics and specification.
Nevertheless, we demonstrate that, often, a (coarse) grid is still
sufficient when applied in a different, more suitable state space.

In this work, we do not synthesize a full controller but only a
nondeterministic safety strategy, which is known as a shield. We then
employ this shield as a guardrail in reinforcement learning
(cf. @fig:shielding) to limit the choices available to
the agent so that the specification is guaranteed. This is a known
concept, which is for instance applied in the tool #smallcaps[Uppaal
Stratego] #cite(label("B:stratego")) and was popularized by Bloem et
al. #cite(label("B:BloemKKW15")) #cite(label("B:AlshiekhBEKNT18")) #cite(label("B:JansenKJSB20")). A similar
concept is safe model predictive
control #cite(label("B:BastaniL21")) #cite(label("B:WabersichZ21")).

Our motivation for applying a state-space transformation is to better
align with a grid, and ultimately to make the synthesis more scalable.
In that sense, our work shares the goal with some other influential
concepts. In abstract interpretation, the transformation is the
abstraction function and its inverse is the concretization function,
which together form a Galois connection #cite(label("B:CousotC77")). In our
approach, the grid introduces an abstraction, but our additional
transformation preserves information unless it is not injective. Another
related concept is model order reduction, where a system is transformed
to another system of lower dimensionality to simplify the
analysis #cite(label("B:SchildersHR08")). This reduction is typically
approximate, which loses any formal guarantees. However, approaches
based on (probabilistic) bisimulation #cite(label("B:LarsenS91")) still allow to
preserve a subspace and transfer the results to the original system.
These approaches, also called lumpability, use linear transformations
and have been successfully applied to Markov chains #cite(label("B:Buchholz94")),
differential equations #cite(label("B:BacciBLTTV21")), and quantum
circuits #cite(label("B:JimenezPastorLTT24")). In contrast, while we do not put
any restrictions on our transformations, we advocate for injective
transformations in our context; this is because we also need to compute
the preimage under the transformation, which otherwise incur additional
approximation error.

==== Outline.
<outline.>
The remainder of the paper is structured as follows. In
@sec:preliminaries, we recall central concepts
underlying partition-based shielding. In
@sec:shielding, we discuss how state-space
transformations can be used for shield synthesis over grid-based
partitions. In @sec:experiments2, we show experimental
results in three case studies. Finally, we conclude the paper in
@sec:conclusion.

== Preliminaries
<sec:preliminaries>
==== Intervals.
<intervals.>
Given bounds $ell comma u in bb(R)$ with $ell lt.eq u$, we
write $cal(I) eq bracket.l ell semi u bracket.l subset.eq bb(R)$ for the
corresponding (half-open) #emph[interval] with
#emph[diameter] $u minus ell$.

==== Set extension.
<set-extension.>
Given a function $f colon S arrow.r T$, the #emph[set extension]
is $f colon 2^S arrow.r 2^T$
with $f lr((X)) eq union.big_(s in X) brace.l f lr((s)) brace.r$ for any
subset $X subset.eq S$. The extension generalizes to functions with
further arguments, e.g.,
$g lr((X comma y)) eq union.big_(s in X) brace.l g lr((s comma y)) brace.r$.
Set extension is monotonic, i.e., $f lr((X)) subset.eq f lr((X prime))$
whenever $X subset.eq X prime$.

==== Control systems.
<control-systems.>
In this work, we consider discrete-time control systems. Formally, a
control system $lr((S comma italic(A c t) comma delta))$ is
characterized by a bounded $d$-dimensional state
space $S subset.eq bb(R)^d$, a finite set of (control)
actions $italic(A c t)$, and a #emph[successor
function] $delta colon S times italic(A c t) arrow.r 2^S$, which maps a
#emph[state] $s in S$ and a #emph[control action] $a in italic(A c t)$
to a set of successor states (i.e., $delta$ may be nondeterministic).
Often, $delta$ is the solution of an underlying continuous-time system,
measured after a fixed control period, as exemplified next.

#example()[Consider a bivariate harmonic oscillator over the state
  space $S eq bracket.l minus 2 semi 2 bracket.l times bracket.l minus 2 semi 2 bracket.l subset.eq bb(R)^2$,
  whose vector field is shown in @fig:oscillator:a. The
  continuous-time dynamics are given by the following system of
  differential equations: $dot(s) lr((t)) eq A s lr((t))$, where
  $A eq mat(delim: "(", 0, 1; minus 1, 0)$. The solution
  is $s lr((t)) eq e^(A t) s_0$ for some initial state $s_0$. For this
  system, we only have a single (dummy) control action,
  $italic(A c t) eq brace.l a brace.r$. Fixing the control
  period $t eq 1.2$ yields the discrete-time
  system $lr((S comma italic(A c t) comma delta))$
  where $delta lr((s comma a)) approx mat(delim: "(", 0.36, 0.93; minus 0.93, 0.36) s$.
]<ex:oscillator1>

==== Partitioning.
<partitioning.>
A #emph[partition] $cal(G) subset.eq 2^S$ of $S$ is a set of pairwise
disjoint sets of states (i.e.,
$forall C_1 eq.not C_2 in cal(G) dot.basic med C_1 inter C_2 eq nothing$)
whose union is $S$ (i.e., $S eq union.big_(C in cal(G)) C$). We call the
elements $C$ of $cal(G)$ #emph[cells]. For a state $s in S$,
$lr([s])_(cal(G))$ is the unique cell $C$ such that $s in C$. We
furthermore define two helper
functions $⌊ dot.op ⌋_(cal(G)) colon 2^S arrow.r 2^(cal(G))$
and $⌈ dot.op ⌉_(cal(G)) colon 2^S arrow.r 2^(cal(G))$ to under- and
overapproximate a set of states $X subset.eq S$ with cells:
$⌊ X ⌋_(cal(G)) eq brace.l C in cal(G) divides C subset.eq X brace.r$
maps $X$ to all its cells that are contained in $X$,
and $⌈ X ⌉_(cal(G)) eq brace.l C in cal(G) divides C inter X eq.not nothing brace.r$
maps $X$ to all cells that intersect with $X$.

A cell $C$ is #emph[axis-aligned] if there exist
intervals $cal(I)_1 comma dots.h comma cal(I)_d$ such
that $C eq cal(I)_1 times dots.h times cal(I)_d$. A partition $cal(G)$
is axis-aligned if all cells are axis-aligned. Moreover, $cal(G)$ is a
#emph[regular grid] if for any two cells $C_1 eq.not C_2$ in $cal(G)$
and any dimension $i eq 1 comma dots.h comma d$, the diameters in
dimension $i$ are identical. In what follows, we consider axis-aligned
regular grid partitions, or #emph[grids] for short. Grids enjoy
properties such as easy representation by just storing the bounds and
diameters.

==== Strategies and safety.
<strategies-and-safety.>
Given a control system $lr((S comma italic(A c t) comma delta))$, a
#emph[strategy] $sigma colon S arrow.r 2^(italic(A c t))$ maps a
state $s$ to a set of (allowed) actions $a$. (In the special case
where $sigma colon S arrow.r italic(A c t)$ uniquely determines the next
action $a$, we call $sigma$ a #emph[controller].) A
sequence $xi eq s_0 a_0 s_1 a_1 dots.h$ is a #emph[trajectory]
of $sigma$ if $a_i in sigma lr((s_i))$
and $s_(i plus 1) in delta lr((s_i comma a_i))$ for all $i$. A safety
property $phi subset.eq S$ is characterized by the set of safe states.
We call $sigma^X$ a #emph[safety strategy], or #emph[shield], with
respect to a set $X$ if all trajectories starting from any initial
state $s_0 in X$ are safe, i.e., only visit safe states. We often omit
the set $X$.

In general, a safety strategy for infinite state spaces $S$ cannot be
effectively computed. The typical mitigation is to instead compute a
safety strategy for a finite-state abstraction. One common such
abstraction is a grid of finitely many cells. The grid induces a
two-player game. Given a cell $C$, Player 1 challenges with an
action $a in italic(A c t)$. Player 2 responds with a cell $C prime$
such that $C arrow.r^a C prime$. Player 1 wins if the game continues
indefinitely, and Player 2 wins if $C prime subset.eq.not phi$. Solving
this game yields a safety strategy over cells, which then induces a
safety strategy over the (concrete) states in $S$ that uses the same
behavior for all states in the same cell. We formalize this idea next.

==== Labeled transition system.
<labeled-transition-system.>
Given a control system $lr((S comma italic(A c t) comma delta))$, a
grid $cal(G) subset.eq 2^S$ induces a finite labeled transition
system $lr((cal(G) comma italic(A c t) comma arrow.r))$ that connects
cells via control actions if they can be reached in one step:

$ C arrow.r^a C prime arrow.l.r.double exists s in C dot.basic med delta lr((s comma a)) inter C prime eq.not nothing $ <eq:transition>

==== Grid extension.
<grid-extension.>
Given a grid $cal(G)$ and a safety property $phi$, the set of
#emph[controllable cells], or simply #emph[safe cells], is the maximal
set of cells $cal(C)_phi$ such that

$ cal(C)_phi eq ⌊ phi ⌋_(cal(G)) inter brace.l C in cal(G) divides exists a in italic(A c t) dot.basic med forall C prime dot.basic med C arrow.r^a C prime arrow.r.double.long C prime in cal(C)_phi brace.r $ <eq:controllable_cells>

It is straightforward to compute $cal(C)_phi$ with a finite fixpoint
iteration. If $cal(C)_phi$ is nonempty, there exists a safety
strategy $sigma^(cal(G)) colon cal(G) arrow.r 2^(italic(A c t))$ at the
level of cells (instead of concrete states) with respect to the
set $cal(C)_phi$, where the most permissive such
strategy #cite(label("B:BernetJW02")) is
$ sigma^(cal(G)) lr((C)) eq brace.l a in italic(A c t) divides forall C prime dot.basic med C arrow.r^a C prime arrow.r.double.long C prime in cal(C)_phi brace.r $

A safety strategy $sigma^(cal(G))$ over the grid $cal(G)$ induces the
safety
strategy $sigma^X lr((s)) eq sigma^(cal(G)) lr((lr([s])_(cal(G))))$ over
the original state space $S$, with respect to the
set $X eq union.big_(C in cal(C)_phi) C$. The converse does not hold,
i.e., a safety strategy may exist over $S$ but not over $cal(G)$,
because the grid introduces an abstraction, as demonstrated next.

#lemma[Let $lr((S comma italic(A c t) comma delta))$ be a
  control system, $phi subset.eq S$ be a safety property, and
  $cal(G) subset.eq 2^S$ be a partition. If $sigma^(cal(G))$ is a safety
  strategy over cells, then
  $sigma^X lr((s)) eq sigma^(cal(G)) lr((lr([s])_(cal(G))))$ is a safety
  strategy over states $s in X subset.eq S$,
  where $X eq union.big_(C in cal(C)_phi) C$.
]<lemma:soundness>



Recall that a grid is an abstraction. The precision of this abstraction
is controlled by the size of the grid cells, which we also refer to as
the granularity.



#example()[Consider again the harmonic oscillator from
  @ex:oscillator1. To add a safety
  constraint, we place a disc-shaped obstacle, i.e., a set of
  states $O subset.eq S$, in the center. Since this system only has a
  dummy action $a$, there is a unique strategy $sigma$ that always selects
  this action. Clearly, $sigma$ is safe for all states that do not
  intersect with the obstacle $O$ because all trajectories circle the
  origin.

  With a rectangular grid in the $x slash y$ state space (with cell
  diameter $1$ in each dimension), we face two fundamental problems. The
  first problem is that, in order to obtain a tight approximation of a
  disc with a rectangular grid, one requires a fine-grained partition.
  Thus, precision comes with a significant computational overhead. Recall
  that the cells that are initially marked unsafe are given
  by $⌈ O ⌉_(cal(G))$, which are drawn black in
  @fig:oscillator:a.

  The second problem is similar in nature, but refers to the system
  dynamics instead. Since the trajectories of most systems do not travel
  parallel to the coordinate axes, a rectangular grid cannot capture the
  successor relation (and, hence, the required decision boundaries for the
  strategy) well. Consider the state highlighted in green in
  @fig:oscillator:a. Its trajectory leads to an unsafe
  cell, witnessing that its own cell is also unsafe. By iteratively
  applying this argument, the fixpoint is $cal(C)_phi eq nothing$, i.e.,
  no cell is considered safe (@fig:oscillator:b). This
  means that, for the chosen grid granularity, no safety
  strategy $sigma^(cal(G))$ at the level of cells exists.
  
]<ex:oscillator2> 


#subpar.grid(
  [#figure(image("../Graphics/AISOLA24/Original State Space.svg"),
    caption: [Original state space. \ #hide[x]]
  )<fig:oscillator:a>],

  [#figure(image("../Graphics/AISOLA24/After Fixpoint Iteration.svg"),
    caption: [After fixpoint iteration. \ #hide[x]]
  )<fig:oscillator:b>],

  [#figure(image("../Graphics/AISOLA24/Transformed State Space.svg"),
    caption: [Transformed state space.]
  )<fig:oscillator:c>],

  columns: 3,
  // placement: bottom,
  caption: [
    Harmonic oscillator in $x slash y$ state space with an obstacle $O$
    (gray). Initially, the black cells $⌈ O ⌉_(cal(G))$ are unsafe. The
    example state (green) leads to an unsafe cell, rendering its cell
    unsafe too. In the fixpoint, all cells are unsafe.  Transformation
    to polar coordinates. The initial marking is also the fixpoint.
  ]
)
<fig:oscillator>

We remark that, since we are only interested in safety at discrete
points in time, finer partitions could still yield safety strategies for
this example.

== Shielding in Transformed State Spaces
<sec:shielding>
In this section, we show how a transformation of the state space can be
used for grid-based shield synthesis, and demonstrate that it can be
instrumental.

=== State-Space Transformations
<state-space-transformations>
We recall the principle of state-space transformations. Consider a state
space $S subset.eq bb(R)^d$. A transformation to another state
space $T subset.eq bb(R)^(d')$ is any
function $f colon S arrow.r T$.

For our application, some transformations are better than others. We
call these transformations #emph[grid-friendly], where, intuitively,
cells in the transformed state space $T$ are better able to separate the
controllable from the uncontrollable states, i.e., capture the decision
boundaries well. This is for instance the case if there is an invariant
property and $f$ maps this property to a single dimension.

#example[Consider again the harmonic oscillator from
  @ex:oscillator2. We transform the
  system to a new state space, with the goal of circumventing the two
  problems identified above. Recall that we want to be able to represent a
  disc shape as well as circular trajectories in a grid-friendly way.
  Observe that the radius of the circle described by a trajectory is an
  invariant of the trajectory. This motivates to choose a transformation
  from Cartesian coordinates to polar coordinates. In polar coordinates,
  instead of $x$ and $y$, we have the dimensions $theta$ (angle) and $r$
  (radius). The transformation is
  $f lr((x comma y)) eq lr((theta comma r))^top eq lr(("atan2" lr((y comma x)) comma sqrt(x^2 plus y^2)))^top$,
  and the transformed state space
  is $T eq bracket.l minus pi semi pi bracket.l times bracket.l 0 semi sqrt(8) bracket.l$.
  The result after transforming the system, including the obstacle and the
  two example states, is shown in @fig:oscillator:c. As
  can be seen, the grid boundaries are parallel to both the obstacle
  boundaries as well as the dynamics, which is the best-case scenario.
  Observe that the radius dimension ($r$) is invariant. Hence, no white
  cell reaches a black cell and no further cells need to be marked unsafe.
]<ex:oscillator3>

=== Shield Synthesis in a Transformed State Space
<shield-synthesis-in-a-transformed-state-space>
In the following, we assume to be given a control
system $lr((S comma italic(A c t) comma delta_S))$, a safety
property $phi$, another state space $T$, a
transformation $f colon S arrow.r T$, and a grid $cal(G) subset.eq 2^T$.
Our goal is to compute the controllable cells similar to
@eq:controllable_cells. However,
since the grid is defined over $T$, we need to adapt the definition. The
set of controllable cells is the maximal set of cells $cal(C)_phi^f$
such that

$ cal(C)_phi^f eq ⌊ f lr((phi)) ⌋_(cal(G)) inter brace.l C in cal(G) divides exists a in italic(A c t) dot.basic med forall C prime dot.basic med C arrow.r^a C prime arrow.r.double.long C prime in cal(C)_phi^f brace.r $ <eq:controllable_cells_transform>

The first change is to map $phi$ to cells over $T$. Next, it is
convenient to define a new control
system $lr((T comma italic(A c t) comma delta_T))$ that imitates the
original system in the new state space. The new successor
function $delta_T colon T times italic(A c t) arrow.r 2^T$ is given
indirectly as

$ delta_T lr((f lr((s)) comma a)) eq f lr((delta_S lr((s comma a)))) $ <eq:successor_transformed_implicit>

The second change in
@eq:controllable_cells_transform
is implicit in the transition relation $C arrow.r^a C prime$ of the
labeled transition
system $lr((cal(G) comma italic(A c t) comma arrow.r))$. Recall from
@eq:transition that the transitions are
defined in terms of the successor function $delta_T$:
$ C arrow.r^a C prime arrow.l.r.double exists t in C dot.basic med delta_T lr((t comma a)) inter C prime eq.not nothing $

==== State-based successor computation.
<state-based-successor-computation.>
To simplify the presentation, for the moment, we only consider a single
state $t in T$. To effectively compute its successors, we cannot
directly use
@eq:successor_transformed_implicit
because it starts from a state $s in S$ instead. Hence, we first need to
map $t$ back to $S$ using the #emph[inverse
transformation] $f^(minus 1) colon T arrow.r 2^S$, defined
as $f^(minus 1) lr((t)) eq brace.l s in S divides f lr((s)) eq t brace.r$.
The resulting set is called the #emph[preimage].

Now we are ready to compute $delta_T lr((t comma a))$ for any
state $t in T$ and action $a in italic(A c t)$. First, we map $t$ back
to its preimage $X eq f^(minus 1) lr((t))$. Second, we apply the
original successor function $delta_S$ to
obtain $X prime eq delta_S lr((X comma a))$. Finally, we obtain the
corresponding transformed states $Y eq f lr((X prime))$. In summary, we
have

$ delta_T lr((t comma a)) eq f lr((delta_S lr((f^(minus 1) lr((t)) comma a)))) $ <eq:suc_transformed>

Note that, if the transformation $f$ is bijective, its
inverse $f^(minus 1)$ is deterministic and we
have $f^(minus 1) lr((f lr((s)))) eq s$
and $f lr((f^(minus 1) lr((t)))) eq t$ for all $s in S$ and $t in T$.

Consider again the harmonic oscillator from
@ex:oscillator2. The inverse
transformation
is $f^(minus 1) lr((theta comma r)) eq vec(r cos (theta), r sin (theta)) $.
The blue successor state of the green state in
@fig:oscillator:c is computed by mapping to the green
state in @fig:oscillator:a via $f^(minus 1)$, computing
the blue successor state via $delta$, and mapping back via $f$.

#subpar.grid(
  [#figure(image("../Graphics/AISOLA24/Commutative Diagram.svg", width: 50%) + v(15pt),
      caption: [Commutative diagram.]
    )<fig:commutative_diagram>
  ], 

  [#figure([#h(8%) $S$ #h(40%) $T$ \
      #v(-1.5em)
      #image("../Graphics/AISOLA24/Spiral/Sampling.svg", width: 100%)
      ],
      caption: [
        Illustration of
        $delta_T lr((C comma a)) eq f lr((delta_S lr((f^(minus 1) lr((C)) comma a))))$.
      ]
    )<fig:transformation_successor_illustration>
  ],
  columns: (40%, 60%),
  label: <fig:transformation_successor>,
  caption: [
    The successor function $delta_T$ for the cell $C$ (green) in the
    transformed state space $T$ is computed in three steps. First, we
    map to the original state space $S$ via $f^(minus 1)$. Second, we
    compute the successors via $delta_S$. Third, we map back to the
    transformed state space $T$ via $f$ (dark blue). Finally, we can
    identify all cells intersecting with this set
    via $⌈ dot.op ⌉_(cal(G))$ (light blue).
  ],
)


==== Grid-based successor computation.
<grid-based-successor-computation.>


@eq:suc_transformed is directly
applicable to cells via set extension, and no further modification is
required. We provide illustrations of the construction in
@fig:transformation_successor.

The construction allows us to compute sound shields, both in the
transformed and in the original state space.

#theorem[Let $lr((S comma italic(A c t) comma delta))$ be a
  control system, $phi subset.eq S$ be a safety property,
  $f colon S arrow.r T$ be a transformation with
  inverse $f^(minus 1) colon T arrow.r 2^S$, and $cal(G) subset.eq 2^T$ be
  a partition of $T$. Define the control
  system $lr((T comma italic(A c t) comma delta_T))$ with $delta_T$
  according to @eq:suc_transformed.
  Let $cal(C)_phi^f$ be according to
  @eq:controllable_cells_transform
  and $sigma^(cal(G))$ be a safety strategy over cells. Then the following
  are safety strategies over states:

  - $sigma^Y lr((t)) eq sigma^(cal(G)) lr((lr([t])_(cal(G))))$ over states
    in $t in Y subset.eq T$, where $Y eq union.big_(C in cal(C)_phi^f) C$

  - $sigma^X lr((s)) eq sigma^(cal(G)) lr((lr([f lr((s))])_(cal(G))))$
    over states in $s in X subset.eq S$,
    where $X eq f^(minus 1) lr((union.big_(C in cal(C)_phi^f) C))$
]<thm:soundness>

#proof[We first need to argue that $delta_T$ is well-defined.
  If $f$ is not injective, then $f^(minus 1)$ is nondeterministic, i.e.,
  generally yields a set of states, but the set extension of $delta_S$
  treats this case. If $f$ is not surjective, its inverse is undefined for
  some states $t in T$. Note that the set extension ignores these states:
  for any set $Y subset.eq T$ we
  have $f^(minus 1) lr((Y)) eq brace.l s in S divides f lr((s)) in Y brace.r$.
  In particular, if no state in $C$ has a preimage,
  $delta_T lr((C comma a)) eq nothing$. Thus, $delta_T$ is well-defined.

  The first claim follows directly from
  @lemma:soundness. For the second
  claim, fix any state $s in X$ and $a in sigma^X lr((s))$. We need to
  show that all states in $delta_S lr((s comma a))$ are safe, i.e., in $X$
  as well. By construction, $f lr((s)) in union.big_(C in cal(C)_phi^f) C$
  and $a in sigma^(cal(G)) lr((lr([f lr((s))])_(cal(G))))$. Hence,
  $ delta_T lr((f lr((s)) comma a)) subset.eq union.big_(C in cal(C)_phi^f) C $ <eq:suc_contained>

  We also use the following simple lemma:
  $ forall s prime in S dot.basic med s in f^(minus 1) lr((f lr((s prime)))) $ <eq:monotonicity>

  Finally, we get (applying monotonicity in the last inclusion):


  $
  delta_S (s, a)
  & subset.eq^#[(#ref(supplement: none, <eq:monotonicity>))]    delta_S (f^(-1)(f(s)), a)
    subset.eq^#[(#ref(supplement: none, <eq:monotonicity>))]    f^(-1)(f(delta_S (f^(-1)(f(s)), a))) \
  & subset.eq^#[(#ref(supplement: none, <eq:suc_transformed>))] f^(-1)(delta_T (f(s), a))
    subset.eq^#[(#ref(supplement: none, <eq:suc_contained>))]  f^(-1)  (union.big_(C in cal(C)_phi^f) C)  
    =X
  $
]

Note that we obtain @lemma:soundness
as the special case where $f$ is the identity.

=== Shielding and Learning
<shielding-and-learning>
We assume the reader is familiar with the principles of reinforcement
learning. Here we shortly recall from #cite(label("B:PaperA")) how to
employ $sigma^(cal(G))$ for safe reinforcement learning. The input is a
Markov decision process (MDP) and a reward function, and the output is a
controller maximizing the expected cumulative return. The MDP is a model
with probabilistic successor
function $delta_P colon S times italic(A c t) times S arrow.r lr([0 comma 1])$.
An MDP induces a control
system $lr((S comma italic(A c t) comma delta_S))$ with nondeterministic
successor
function $delta_S lr((s comma a)) eq brace.l s prime in S divides delta_P lr((s comma a comma s prime)) gt 0 brace.r$
as an abstraction where the distribution has been replaced by its
support.

Now consider @fig:shielding, which integrates a
transformed shield into the learning process. In each iteration, the
shield removes all unsafe actions (according to $sigma^(cal(G))$) from
the agent’s choice. By construction, when starting in a controllable
state, at least one action is available, and all available actions are
guaranteed to lead to a controllable state again. Thus, by induction,
all possible trajectories are infinite and never visit an unsafe state.
Furthermore, filtering unsafe actions typically improves learning
convergence because fewer options need to be explored.

==== Learning in $S$ and $T$.
<learning-in-s-and-t.>
Recall from @thm:soundness that we
can apply the shield both in the transformed state space and in the
original state space by using the transformation function $f$. This
allows us to also perform the learning in either state space. We
consider the following setup the default: learning in the original state
space $S$ under a shield computed in the transformed state space $T$.

An alternative is to directly learn in $T$. A potential motivation could
be that learning, in particular agent representation, may also be easier
in $T$. For instance, the learning method implemented in
#smallcaps[Uppaal Stratego] represents an agent by axis-aligned
hyperrectangles #cite(label("B:JaegerJLLST19")). Thus, a grid-friendly
transformation may also be beneficial for learning, independent of the
shield synthesis. We will investigate the effect in our experiments.

== Experiments
<sec:experiments2>
In this section, we demonstrate the benefits of state-space
transformations for three models.#footnote[A repeatability package is
available here: \
#link("https://github.com/AsgerHB/state-space-transformation-shielding").]
For the first two models, we use domain knowledge to select a suitable
transformation. For the third model, we instead derive a transformation
experimentally. The implementation builds on our synthesis
method #cite(label("B:PaperA")).

=== Satellite Model
<satellite-model>

#figure(grid(columns: (3fr, 5fr), align: horizon, gutter: 2em,
    image("../Graphics/AISOLA24/Spiral/Unsafe Spiral Trace.svg"),
    infobox(name: "State Space")[
      #set math.equation(numbering: none)
      $lr((x comma y)) in S eq bracket.l minus 2 semi 2 bracket.l times bracket.l minus 2 semi 2 bracket.l$\
      $lr((theta comma r)) in T eq bracket.l minus pi semi pi bracket.l times bracket.l 0 semi 2 bracket.l$\
      $f lr((x comma y)) eq lr(("atan2" lr((y comma x)) comma sqrt(x^2 comma y^2)))^top$\
    ]
  ),
  placement: top,
  caption: [
    Satellite model.
  ]
)
<fig:satellite_unsafe_trace>

For the first case study, we extend the harmonic oscillator with two
more control actions to also move inward and outward:
$italic(A c t) eq brace.l italic("ahead") comma italic("out") comma italic("in") brace.r$.
The box to the side shows the relevant information about the
transformation. Compared to
@ex:oscillator3, beside the actions,
we modify two parts. First, the transformed state space $T$ is reduced
in the radius dimension to $r in bracket.l 0 semi 2 bracket.l$ because
values outside the disc with radius $2$ are not considered safe (see
below). Second, the successor function still uses matrix $A$ from
@ex:oscillator1 but with a control
period of $t eq 0.05$. The successor function thus becomes
$delta lr((s comma a)) eq e^(A t) paren.l vec(r c cos lr((theta)), r c sin lr((theta))) H E L L O O O$,
where for $s eq lr((x comma y))^top$ and $f$ as in
@ex:oscillator3 we have
$ vec(theta, r) eq f lr((s)) comma quad c eq cases(delim: "{", 0.99 & upright("if ") a eq italic("in"), 1.01 & upright("if ") a eq italic("out"), 1 & upright("otherwise.")) comma quad e^(A t) approx mat(delim: "(", 1.00, 0.05; minus 0.05, 1.00; #none) $

Instead of one large obstacle, we add several smaller stationary
(disc-shaped) obstacles. The shield has two goals: first, the agent must
avoid a collision with the obstacles; second, the agent’s distance to
the center must not exceed $2$.
@fig:satellite_unsafe_trace shows the size and position
of the obstacles (gray). Overlaid is a trajectory (blue) produced by a
random agent that selects actions uniformly. Some states of the
trajectory collide with obstacles (red).

Additionally, we add an optimization component to the system. A
disc-shaped #emph[destination] area (purple) spawns at a random initial
position (inside the 2-unit circle). Colliding with this area grants a
reward and causes it to reappear at a new position. The optimization
criterion for the agent is thus to visit as many destinations as
possible during an episode.

#subpar.grid(
  [#figure(image("../Graphics/AISOLA24/Spiral/Spiral Shield - Standard State Space.svg"),
    caption: [Shield in $S$ (176,400 cells). \ #hide("x")]
  )<fig:satellite_shield_original>],

  [#figure(image("../Graphics/AISOLA24/Spiral/Spiral Shield - Altered State Space.svg"),
    caption: [Shield in $T$ (27,300 cells), including a transformation back to $S$.]
  )<fig:satellite_shield_transformed>],
  columns: 2,
  caption: [Shields for the satellite model. The legend applies to both figures.],
  label: <fig:satellite_shields>
)

@fig:satellite_shield_original shows a shield obtained
in the original state space. First, we note that a fine grid granularity
is required to accurately capture the decision boundaries. In
particular, the "tails" behind the obstacles split into regions where
moving #emph[ahead] is no longer possible. There is a small region at
the tip of the tail (yellow) where the agent may either move #emph[in]
or #emph[out], but not #emph[ahead] anymore.

Moreover, despite this high precision, the obstacle in the center causes
a large set of cells around it to be marked unsafe, although we know
that the #emph[ahead] (and also #emph[out]) action is safe. This is a
consequence of the abstraction in the grid.

Now we transform the system, for which we choose polar coordinates
again. @fig:satellite_shield_transformed shows a shield
obtained in this transformed state space. As we saw for the harmonic
oscillator, the boundary condition is well captured by a grid. The
obstacles also produce "tails" in this transformation, which require
relatively high precision in the grid to be accurately captured. Still,
since the shapes are axis-aligned, and the size of the transformed state
space is different, the number of cells can be reduced by one order of
magnitude. The grid over the original state space had
$176 comma 400$ cells, compared to $27 comma 300$ cells in the
transformed state space. Computing the original shield took $2$ minutes
and $41$ seconds, while computing the transformed shield only took
$10$ seconds. Finally, the region marked unsafe at the bottom of
@fig:satellite_shield_transformed, which corresponds to
the central obstacle in the original state space, is tight, unlike in
@fig:satellite_shield_original. In summary, the
transformed shield is both easier to compute and more precise.

=== Bouncing-Ball Model
<bouncing-ball-model>
#figure(grid(columns: (3fr, 5fr), align: horizon, gutter: 2em,
    image("../Graphics/AISOLA24/Bouncing Ball/Bouncing Ball.svg", width: 75%),
    infobox(name: "State Space")[
      $lr((v comma p)) in S eq bracket.l minus 13 semi 13 bracket.l times bracket.l 0 semi 8 bracket.l$  \
      $lr((E_m comma v)) in T eq bracket.l 0 semi 100 bracket.l times bracket.l minus 13 semi 13 bracket.l$ \
      $f lr((v comma p)) eq lr((m g p plus 1 / 2 m v^2 comma v))^top$ \
    ]
  ),
  placement: top,
  caption: [
    Bouncing-ball model.
  ]
)
<fig:bouncing_ball>
#subpar.grid(
  [#figure(image("../Graphics/AISOLA24/Bouncing Ball/automaton.png"),
    caption: [Hybrid automaton.]
  )<fig:bb_automaton>],

  [#figure(image("../Graphics/AISOLA24/Bouncing Ball/BB Shield - Standard State Space.svg"),
    caption: [Shield in $S$ (520,000 cells).]
  )<fig:bb_shield_original>],

  [#figure(image("../Graphics/AISOLA24/Bouncing Ball/BB Shield - Altered State Space.svg"),
    caption: [Shield in $T$ (650 cells).]
  )<fig:bb_shield_transformed>],

  [#figure(image("../Graphics/AISOLA24/Bouncing Ball/BB Shield - Altered State Space but Shown in Standard State Space.svg"),
    caption: [Shield in $T$ transformed back to $S$.]
  )<fig:bb_shield_transformed_projection>],
  placement: top,
  columns: 2,
  caption: [
    Hybrid automaton and shields for the bouncing-ball model.
  ],
  label: <fig:bb_shield>
)

For the second case study, we consider the model of a bouncing ball
from #cite(label("B:PaperA")). @fig:bouncing_ball shows
an illustration of the system, while @fig:bb_automaton
shows the hybrid-automaton model. The state space consists of the
velocity $v$ and the position $p$ of the ball. When the ball hits the
ground, it loses energy subject to a stochastic dampening (dashed
transition). The periodic controller is modeled with a clock $x$ with
implicit dynamics $dot(x) eq 1$ and control period $P eq 0.1$. The
available actions
are $italic(A c t) eq brace.l italic("nohit") comma italic("hit") brace.r$,
where the #emph[nohit] action has no effect and the #emph[hit] action
pushes the ball downward subject to its velocity, but only provided it
is high enough ($p gt.eq 4$).

The goal of the shield is to keep the ball bouncing indefinitely, which
is modeled as nonreachability of the set of
states $p lt.eq 0.01 and lr(|v|) lt.eq 1$.

The optimization task is to use the #emph[hit] action as rarely as
possible, which is modeled by assigning it with a cost and minimizing
the total cost.

Despite its simple nature, this model has quite intricate dynamics,
including stochastic and hybrid events that require zero-crossing
detection, which makes determining reachability challenging. It was
shown in #cite(label("B:PaperA")) that a sampling-based shield synthesis
is much more scalable than an approach based on guaranteed reachability
analysis ($19$ minutes compared to $41$ hours). The grid needs to be
quite fine-grained to obtain a fixpoint where not every cell is marked
unsafe. This corresponds to $520 comma 000$ cells, and the corresponding
shield is shown in @fig:bb_shield_original.

Now we use a transformation to make the shield synthesis more efficient.
The mechanical energy $E_m$ stored in a moving object is the sum of its
potential energy and its kinetic energy, respectively. Formally,
$E_m lr((p comma v)) eq m g p plus 1 / 2 m v^2$, where $m eq 1$ is the
mass and $g eq 9.81$ is gravity. Thus, the mechanical energy of a ball
in free fall (both with positive or negative velocity) remains
invariant. Hence, $E_m$ is a good candidate for a transformation.

However, only knowing $E_m$ is not sufficient to obtain a permissive
shield because states with the same value of $E_m$ may be below or
above $p eq 4$ and hence may or may not be hit. The equation for $E_m$
depends on both $p$ and $v$. In this case, it is sufficient to know only
one of them. Here, we choose the transformed state space $T$ with
just $E_m$ and $v$. The transformation function
is $f lr((v comma p)) eq lr((m g p plus 1 / 2 m v^2 comma v))^top$ and
its inverse
is $f^(minus 1) lr((E_m comma v)) eq lr((lr((E_m minus 1 / 2 m v^2)) slash lr((m g)) comma v))^top$.
We note that using $E_m$ and $p$ instead yields a shield that marks all
cells unsafe. This is because $v$ is quadratic in $E_m$ and, thus, we
cannot determine its sign.

@fig:bb_shield_transformed shows the shield obtained in
this transformed state space. It can be seen that this results in a very
low number of just $650$ cells in total, which is a reduction by three
orders of magnitude. This shield can be computed in just $1.3$ seconds,
which compared to $19$ minutes is again a reduction by three orders of
magnitude.

To provide more intuition about how precise this shield still is, we
project the shield back to the original state space in
@fig:bb_shield_transformed_projection. While a direct
comparison is not fair because the grid granularity differs vastly,
overall the shapes are similar.

=== Cart-Pole Model
<cart-pole-model>
#figure(grid(columns: (3fr, 5fr), align: horizon, gutter: 2em,
    image("../Graphics/AISOLA24/Cart Pole/Cart Pole.svg", width: 75%),
    infobox(name: "State Space")[
      $lr((theta comma omega)) in S eq bracket.l minus 2.095 semi 2.095 bracket.l times bracket.l minus 3 semi 3 bracket.l$ \
      $lr((theta comma p lr((theta comma omega)))) in T eq bracket.l minus 2.095 semi 2.095 bracket.l times bracket.l minus 3 semi 3 bracket.l$ \
      $f lr((theta comma omega)) eq lr((theta comma omega minus p lr((theta))))^top$
    ],
  ),
  placement: top,
  caption: [
    Cart-pole model.
  ]
)
<fig:cart_pole>

For the third case study, we consider a model of an inverted pendulum
installed on a cart that can move horizontally. This model is known as
the cart-pole model. An illustration is shown in
@fig:cart_pole. The dynamics are given by the following
differential equations #cite(label("B:Florian05")):
$ dot(theta) & eq omega & dot(omega) & eq frac(g sin lr((theta)) plus cos lr((theta)) dot.op lr((frac(minus F minus m_p ell omega^2 sin lr((theta)), m_c plus m_p))), ell lr((4 / 3 minus frac(m_p cos^2 lr((theta)), m_c plus m_p))))\
dot(x) & eq v & dot(v) & eq frac(F plus m_p ell lr((omega^2 sin lr((theta)) minus dot(omega) cos lr((theta)))), m_c plus m_p) $

The state dimensions are the pole’s angle $theta$ and angular
velocity $omega$ as well as the cart’s position $x$ and velocity $v$.
Moreover, $g eq 9.8 m slash s^2$ is gravity, $ell eq 0.5$ m is the
pole’s length, $m_p eq 0.1$ kg is the pole’s mass, and $m_c eq 1$ kg is
the cart’s mass. Finally, $F eq plus.minus 10$ is the force that is
applied, corresponding to the action
from $italic(A c t) eq brace.l italic("left") comma italic("right") brace.r$,
which can be changed at a rate of $0.02$ (control period).

The goal of the shield is to balance the pole upright, which translates
to the condition that the angle stays in a small
cone $lr(|theta|) lt.eq 0.2095$.

The optimization goal is to keep the cart near its initial
position $x lr((0))$. Moving more than $2.4$ m away yields a penalty
of $1$ and resets the cart.

Observe that the property for the shield only depends on the pole and
not on the cart. Hence, it is sufficient to focus on the pole
dimensions $theta$ and $omega$ for shield synthesis, and leave the cart
dimensions for the optimization. A shield in the original state space is
shown in @fig:cart_pole_shield_original.

In the following, we describe a state-space transformation for shield
synthesis. Unlike for the other models, we are not aware of an invariant
property that is useful for our purposes. Instead, we will derive a
transformation in two steps.

Recall that a transformation is useful if a grid in the new state space
captures the decision boundaries well, i.e., the new decision boundaries
are roughly axis-aligned. Thus, our plan is to approximate the shape of
the decision boundaries in the first step and then craft a suitable
transformation in the second step.

==== Approximating the Decision Boundaries.
<approximating-the-decision-boundaries.>
#subpar.grid(
  [#figure(image("../Graphics/AISOLA24/Cart Pole/Angle Original State Space Shield.svg"),
    caption: [Shield in $S$ ($900$ cells). \ #hide("x")]
  )<fig:cart_pole_shield_original>],

  [#figure(image("../Graphics/AISOLA24/Cart Pole/Fitting Polynomial to Unfinished Shield V2.svg"),
    caption: [Approximating the decision boundaries in $S$.]
  )<fig:cart_pole_shield_unfinished>],

  [#figure(image("../Graphics/AISOLA24/Cart Pole/Angle Polynomial from Unfinished Shield.svg"),
    caption: [Shield in $T$ ($400$ cells).]
  )<fig:cart_pole_shield_transformed>],

  [#figure(image("../Graphics/AISOLA24/Cart Pole/Angle Polynomial from Unfinished Shield Projected Back to Original State Space.svg"),
    caption: [Shield in $T$ projected back to $S$.]
  )<fig:cart_pole_shield_transformed_projected>],
  columns: 2,
  caption: [
    Shield computation for the cart-pole model. The legend in
    @fig:cart_pole_shield_original applies to all
    subfigures.
  ]
)
<fig:cart_pole_shield>

@fig:cart_pole_shield_original shows the decision
boundaries of a fixpoint computed using $30 times 30$ cells. However,
our work of state-space transformations was motivated because computing
the shield is generally not feasible in the first place.

Therefore, here we take a different approach, which uses a grid of
just $20 times 20$ cells. Computing a shield for such a coarse grid in
the original state space yields $cal(C)_phi eq nothing$, i.e., all cells
become unsafe. This is a consequence of the abstraction, i.e., a
trajectory at the grid level may be spurious at the state level. This
abstraction grows with the number of steps of the trajectory. Our idea
is thus to only perform the fixpoint iteration at the grid level for a
low number (here: three) of steps. (Technically, this means that the
strategy is only guaranteed to be safe for three steps.) The result is
the marking of cells in
@fig:cart_pole_shield_unfinished. Indeed, the decision
boundaries roughly approximate those in
@fig:cart_pole_shield_original.

==== Crafting a Transformation.
<crafting-a-transformation.>
We want to find a grid-friendly transformation that "flattens out" the
decision boundaries. Our idea is to keep the dimension $theta$ and
replace $omega$ by a transformation that is "flatter." We observe that
the upper (yellow) and lower (purple) decision boundaries are symmetric.
Hence, the distance to the average of the upper and lower boundaries is
a good approximation.

This idea is visualized in
@fig:cart_pole_shield_unfinished. Here we compute the
average (diamonds) of the upper and lower boundaries (triangles). Then
we fit a polynomial to approximate this shape. In our implementation, we
used the Julia
#link("https://github.com/JuliaMath/Polynomials.jl")[`Polynomials`]
library, which implements a standard linear least squares
method #cite(label("B:DraperS98")). Here, a third-degree
polynomial $p lr((theta)) eq minus 141.6953 dot.op theta^3 minus 4.5508 dot.op theta$
is sufficient.

To obtain the full transformation, we need to express the offset
from $p lr((theta))$. Thus, we
choose $f lr((theta comma omega)) eq lr((theta comma omega minus p lr((theta))))^top$.
The inverse function
is $f^(minus 1) lr((theta comma z)) eq lr((theta comma z plus p lr((theta))))^top$,
where $z$ is the new dimension in the transformed state space ($T$).

The resulting shield is shown in
@fig:cart_pole_shield_transformed. The grid size is
$400$ cells, as compared to $900$ cells in the original state space.
Both took less than a second to synthesize, at $244$ ms and $512$ ms,
respectively.

=== Strategy Reduction
<strategy-reduction>



#figure(table(
    columns: 4,
    align: (center + horizon, center, right, right),
    inset: 6pt,
    table.header([#strong[Model]], [#strong[State space]], [#strong[Number of cells]], [#strong[Number of nodes]]),
    table.cell(rowspan: 2)[Satellite],  [$S$],  [176,400],  [4,913],  
                                        [$T$],  [27,300],  [544],
    table.hline(),
    table.cell(rowspan: 2)[Bouncing ball],  [$S$],  [520,000],  [940],  
                                            [$T$],  [650],  [49],
    table.hline(),
    table.cell(rowspan: 2)[Cart-pole],  [$S$],  [900],  [99],
                                        [$T$],  [400],  [32],
  ),
  caption: [Representation sizes of the computed shields.]
)<tab:shield_reduction>


We provide an overview of the savings due to computing the shield in the
transformed state space in @tab:shield_reduction. The
column labeled #emph[Number of cells] clearly shows a significant
reduction in all cases. We remark that, in order to have a fair
comparison, we have selected the grid sizes from visual inspection to
ensure that the plots look sufficiently close. However, it is not the
case that one of the shields is more permissive than the other.

The strategies above can be represented with a $d$-dimensional matrix.
Matrices are inherently limiting representations of shields, especially
when the shield should be stored on an embedded device. Empirically, a
decision tree with axis-aligned predicates is a much better
representation. To demonstrate the further saving potential, we
converted the shields to decision trees and additionally applied the
reduction technique from #cite(label("B:HoegPetersenLWJ23")). The last column in
@tab:shield_reduction shows the number of nodes in the
decision trees. As can be seen, we always achieve another significant
reduction by one to two orders of magnitude.

=== Shielded Reinforcement Learning
<shielded-reinforcement-learning>


#figure(table(
    columns: 10,
    align: center,
    table.header(
      strong[Learning], 
      table.cell(colspan: 3, strong[Satellite ($arrow.tr$)]), 
      table.cell(colspan: 3, strong[Bouncing ball ($arrow.br$)]),
      table.cell(colspan: 3, strong[Cart-pole, ($arrow.br$)]),
    ),
    [], [None], [$S$], [$T$], [None], [$S$], [$T$], [None], [$S$], [$T$],
    [$S$], [1.123], [0.786], strong[1.499], [39.897], [37.607], strong[36.593], [0.007], [0.019], strong[0.001], [$T$], [0.917], [0.889],  strong[1.176], [39.128], [40.024], strong[39.099], strong[0.000], strong[0.000], strong[0.000],
  ),
  caption: [Cumulative return over $1000$ episodes with both
shielding and learning in either of the state spaces. Higher return is
better for the satellite model, and vice versa for the other models.
Each row’s best result is marked in bold face.],
)<tab:shielded_learning>

The only motivation for applying a state-space transformation was to be
able to compute a cheaper shield. From the theory, we cannot draw any
conclusions about the impact on the controller performance. We
investigate this impact in the following experiments, with the main
result that the transformed shield actually increases the performance
consistently.

We conduct six experiments for each of the three models. For shielding,
we consider three variants (no shield, shielding in the original state
space $S$, and shielding in the transformed state space $T$). For each
variant, we reinforcement-learn two controllers. One controller is
trained in the original state space $S$, while the other controller is
trained in the transformed state space $T$.

In @tab:shielded_learning, we provide the learning
results for all combinations of shielding and learning. The data is
given as the cumulative return obtained over $1000$ executions of the
environment and the respective learned agent using #smallcaps[Uppaal].

The results show that, for all models, the highest reward is achieved by
the controller operating under the shield in the transformed state
space. This holds regardless of which state space the controller was
trained in. Additionally, the controller that was trained in the
original state space achieves higher performance. Thus, the
transformation was not helpful for the learning process itself.

== Conclusion
<sec:conclusion>
We have demonstrated that state-space transformations hold great
potential for shield synthesis. We believe that they are strictly
necessary when applying shield synthesis to many practical systems due
to state-space explosion.

In the first two case studies, we used domain knowledge to select a
suitable transformation. In the third case study, we instead engineered
a transformation in two steps. We plan to generalize these steps to a
principled method and investigate how well it applies in other cases.

State-space transformations can be integrated with many orthogonal prior
extensions of grid-based synthesis. One successful extension is, instead
of precomputing the full labeled transition system, to compute its
transitions on the fly #cite(label("B:HsuMMS18b")). Another extension is the
multilayered abstraction #cite(label("B:GirardGM16")) #cite(label("B:HsuMMS18a")). Going one
step further, in cases where a single perfect transformation does not
exist, we may still be able to find a family of transformations of
different strengths.

==== Acknowledgments
<acknowledgments>
We thank Tom Henzinger for the suggestion to study level sets.

#[
  #set heading(numbering: none) 
  == References

  #bibliographyx("../Bibliography.bib",
    prefix: "B:",
    title: none,
  )
]
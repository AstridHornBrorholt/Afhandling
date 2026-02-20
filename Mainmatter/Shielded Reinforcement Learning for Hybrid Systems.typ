#import "@preview/subpar:0.2.2"
#import "@preview/lovelace:0.3.0": *
#import "@preview/lemmify:0.1.8": *

#import "@preview/alexandria:0.2.2": *
#show: alexandria(prefix: "A:", read: path => read(path))

#let (
  theorem, lemma, corollary,
  remark, proposition, example,
  proof, rules: thm-rules
) = default-theorems("thm-group", lang: "en")

= Shielded Reinforcement Learning \ for Hybrid Systems <paper:A>
#grid(columns: (1fr, 1fr), row-gutter: 2em,
  [Asger Horn Brorholt \
  _Department of Computer Science \ Aalborg University, Aalborg, Denmark_],

  [Peter Gjøl Jensen \
  _Department of Computer Science \ Aalborg University, Aalborg, Denmark_],

  [Kim Guldstrand Larsen \
  _Department of Computer Science \ Aalborg University, Aalborg, Denmark_],

  [Florian~Lorber \
  _Department of Computer Science \ Aalborg University, Aalborg, Denmark_],

  [Christian~Schilling \
  _Department of Computer Science \ Aalborg University, Aalborg, Denmark_])

#v(1fr)

#heading(level: 2, numbering: none)[Abstract]
Safe and optimal controller synthesis for switched-controlled hybrid systems, which combine differential equations and discrete changes of the system's state, is known to be intricately hard. Reinforcement learning has been leveraged to construct near-optimal controllers, but their behavior is not guaranteed to be safe, even when it is encouraged by reward engineering. One way of imposing safety to a learned controller is to use a \emph{shield}, which is correct by design. However, obtaining a shield for non-linear and hybrid environments is itself intractable. In this paper, we propose the construction of a shield using the so-called \emph{barbaric method}, where an approximate finite representation of an underlying partition-based two-player safety game is extracted via systematically picked samples of the true transition function. While hard safety guarantees are out of reach, we experimentally demonstrate strong statistical safety guarantees with a prototype implementation and \uppaalstratego. Furthermore, we study the impact of the synthesized shield when applied as either a pre-shield (applied before learning a controller) or a post-shield (only applied after learning a controller). We experimentally demonstrate superiority of the pre-shielding approach. We apply our technique on a range of case studies, including two industrial examples, and further study post-optimization of the post-shielding approach.

#pagebreak(weak: true)

== Introduction
<sec:introduction>
Digital controllers are key components of cyber-physical systems.
Unfortunately, the algorithmic construction of controllers is intricate
for any but the simplest
systems #cite(label("A:lewis2012optimal")) #cite(label("A:doyle2013feedback")). This motivates
the usage of rl, which is a powerful machine-learning method applicable
to systems with complex and stochastic dynamics #cite(label("A:BusoniuBTKP18")).

However, while controllers obtained from rl provide near-optimal
average-case performance, they do not provide guarantees about
worst-case performance, which limits their application in many relevant
but safety-critical domains, ranging from power converters to traffic
control #cite(label("A:VlachogiannisH04")) #cite(label("A:NoaeenNGCAABF22")). A typical way to
tackle this challenge is to integrate safety into the optimization
objective via #emph[reward shaping] during the learning phase, which
punishes unsafe behavior #cite(label("A:10.5555/2789272.2886795")). This will
make the controller more robust to a certain degree, but safety
violations will still be possible, and the integration of safety into
the optimization objective can reduce the performance, thus yielding a
controller that is neither safe nor optimal.

#subpar.grid(columns: 2,
    [#figure(image("../Graphics/AISOLA23/preshielding.svg"),
      caption: [
        Pre-shield.
      ]
    ) <fig:pre-shield>],

    [#figure(image("../Graphics/AISOLA23/postshielding.svg"),
      caption: [
        Post-shield.
      ]
    ) <fig:pst-shield>],
  caption: [
    Pre- and post-shielding in a reinforcement-learning setting.
  ],
  label: <fig:shieldingTypes>
)

A principled approach to obtain worst-case guarantees is to use a
#emph[shield] that restricts the available
actions #cite(label("A:DBLP:conf/tacas/BloemKKW15")). This makes it possible to
construct correct-by-design and yet near-optimal controllers.
@fig:shieldingTypes depicts two ways of shielding RL
agents: #emph[pre-] and #emph[post-shielding]. Pre-shielding is already
applied during the learning phase, and the learning agent receives only
safe actions to choose from. Post-shielding is only applied during
deployment, where the trained agent is monitored and, if necessary,
corrected. Such interventions to ensure safety interfere with the
learned policy of the agent, potentially causing a loss in optimality.

In a nutshell, the algorithm to obtain a shield works as follows. First
we compute a finite partitioning of the state space and approximate the
transitions between the partitions. This results in a two-player safety
game, and upon solving it, we obtain a strategy that represents the most
permissive shield.

Cyber-physical systems exhibit behavior that is both continuous (the
environment) and discrete (the control, and possibly the environment
too). We are particularly interested in a class of systems we refer to
as #emph[hybrid Markov decision processes] (HMDPs). In short, these are
control systems where the controller can choose an action in a periodic
manner, to which the environment chooses a stochastic continuous
trajectory modeled by a stochastic hybrid
automaton #cite(label("A:DBLP:journals/corr/abs-1208-3856")). While HMDPs
represent many real-world systems, they are a rich extension of hybrid
automata, and thus their algorithmic analysis is intractable even under
serious restrictions #cite(label("A:HenzingerKPV98")). These complexity barriers
unfortunately also carry over to the above problem of constructing a
shield.

In this paper, we propose a new practical technique to automatically and
robustly synthesize a shield for HMDPs. The intractability in the
shield-synthesis algorithm is due to the rigorous computation of the
transition relation in the abstract transition system, since that
computation reduces to the (undecidable) reachability problem. Our key
to get around this limitation is to approximate the transition relation
through systematic sampling, in a way that is akin to the #emph[barbaric
method] (a term credited to Oded
Maler #cite(label("A:KapinskiKMS03")) #cite(label("A:Donze10"))).

We combine our technique with the tool #smallcaps[Uppaal Stratego] to
learn a shielded near-optimal controller, which we evaluate in a series
of experiments on several models, including two real-world cases. In our
experiments we also find that pre-shielding outperforms post-shielding.
While the shield obtained through our technique is not guaranteed to be
safe in general due to the approximation, we demonstrate that the
controllers we obtain are statistically safe, and that a moderate number
of samples is sufficient in practice.

#emph[Related work.] Enforcing safety during RL by limiting the choices
available to the agent is a known concept, which is for instance applied
in the tool #smallcaps[Uppaal Stratego] #cite(label("A:stratego")). The term
"shielding" was coined by Bloem et
al. #cite(label("A:DBLP:conf/tacas/BloemKKW15")), who introduced special
conditions on the enforcer like #emph[shields with minimal interference]
and #emph[k-stabilizing shields] and later demonstrated shielding for RL
agents @A:AlshiekhBEKNT18, where they correct potentially
unsafe actions chosen by the RL agent. Jansen et
al. #cite(label("A:jansen2020safe")) introduced shielding in the context of RL
for probabilistic systems. A concept similar to shielding has also been
proposed for safe model predictive
control #cite(label("A:BastaniL21")) #cite(label("A:WabersichZ21")). Carr et
al. #cite(label("A:DBLP:conf/aaai/Carr0JT23")) show how to shield partially observable
environments. In a related spirit, Maderbacher et al. start from a safe
policy and switch to a learned policy if safe at run
time #cite(label("A:MaderbacherSBBNK23")).

(Pre-)Shielding requires a model of the environment in order to provide
safety guarantees during learning. Orthogonal to shielding, several
model-free approaches explore an rl environment in a #emph[safer] way,
but without any guarantees. Several works are based on barrier
certificates and adversarial examples #cite(label("A:ChengOMB19")) #cite(label("A:LuoM21")) or
Lyapunov functions #cite(label("A:HasanbeigAK20")). Similarly, Berkenkamp et
al. describe a method to provide a safe policy with high
probability #cite(label("A:BerkenkampTS017")). Chow et al. consider a relaxed
version of safety based on expected cumulative cost #cite(label("A:ChowNDG18")).
In contrast to these model-free approaches, we assume a model of the
environment, which allows us to safely synthesize a shield just from
simulations before the learning phase. We believe that the assumption of
a model, typically derived from first principles, is realistic, given
that our formalism allows for probabilistic modeling of uncertainties.
To the best of our knowledge, none of the above works can be used in
practice for safe rl in the complex class of HMDPs.

Larsen et al. #cite(label("A:10.1007/978-3-030-23703-5_6")) used a set-based
Euler method to overapproximate reachability for continuous systems.
This method was used to obtain a safety strategy and a safe near-optimal
controller. Contrary to that work, we apply both pre- and
post-shielding, and our method is applicable to more general hybrid
systems. We employ state-space partitioning, which is common for control
synthesis #cite(label("A:MajumdarOS20")) and reachability
analysis #cite(label("A:KlischatA20")) and is also used in recent work on
learning a safe controller for discrete stochastic systems in a
teacher-learner framework #cite(label("A:ZikelicLHC23")). Contemporary work by
Badings et al. #cite(label("A:badings_robust_2023")) also uses a finite
state-space abstraction along with sample-based reachability estimation,
to compute a reach-avoid controller. The method assumes linear dynamical
systems with stochastic disturbances, to obtain upper and lower bounds
on transition probabilities. In contrast, our method supports a very
general hybrid simulation model, and provides a safety shield, which
allows for further optimization of secondary objectives.

A special case of the HMDPs we consider is the class of stochastic
hybrid systems (SHSs). Existing reachability approaches are based on
state-space partitioning #cite(label("A:AbateAPLS07")) #cite(label("A:ShmarovZ15")), which we
also employ in this work, or have a statistical
angle #cite(label("A:Bujorianu12")). We are not aware of any works that extended
SHSs to HMDPs.

#emph[Outline.] The remainder of the paper is structured as follows. In
@sec:EMDP we present the formalism we use. In
@sec:computingreachability we present our synthesis
method to obtain a safety strategy and explain how this strategy can be
integrated into a shield. We demonstrate the performance of our pre- and
post-shields in several cases in @sec:experiments.
Finally we conclude the paper in @sec:conc.

== Euclidian and Hybrid Markov Decision Processes
<sec:EMDP>
In this section we introduce the system class we study in this paper:
hybrid Markov decision processes (HMDPs). They combine Euclidean Markov
decision processes and stochastic hybrid automata, which we introduce
next. HMDPs model complex systems with continuous, discrete and
stochastic dynamics.

=== Euclidean Markov Decision Processes
<euclidean-markov-decision-processes>
A Euclidean Markov decision process
(EMDP) #cite(label("A:DBLP:conf/atva/JaegerJLLST19")) #cite(label("A:randomwalk")) is a
continuous-space extension of a Markov decision process (MDP). We recall
its definition below.

A #emph[Euclidean Markov decision process] of dimension $k$ is a tuple
$cal(M) eq lr((cal(S) comma s_0 comma italic("Act") comma T comma C comma cal(G)))$
where

- $cal(S) subset.eq bb(R)^k$ is a bounded and closed part of
  $k$-dimensional Euclidean space,

- $s_0 in cal(S)$ is the initial state,

- $italic("Act")$ is the finite set of actions,

- $T colon cal(S) times italic("Act") arrow.r lr((cal(S) arrow.r bb(R)_(gt.eq 0)))$
  maps each state-action pair $lr((s comma a))$ to a probability density
  function over $cal(S)$, i.e., we have
  $integral_(s prime in cal(S)) T lr((s comma a)) lr((s prime)) d s prime eq 1$,

- $C colon cal(S) times italic("Act") times cal(S) arrow.r bb(R)$ is the
  cost function, and

- $G subset.eq cal(S)$ is the set of goal states.

#example(name: [Random Walk])[
  @fig:RandomWalk illustrates an EMDP of
  a (semi-)random walk on the state space
  $cal(S) eq lr([0 comma x_(m a x)]) times lr([0 comma t_(m a x)])$
  (one-dimensional space plus time). The goal is to cross the $x eq 1$
  finishing line before $t eq 1$. Two movement actions are available: fast
  and expensive (blue), or slow and cheap (brown). Both actions have
  uncertainty about the distance traveled and time taken. Given a state
  $lr((x comma t))$ and an action
  $a in brace.l italic(s l o w) comma italic(f a s t) brace.r$, the
  next-state density function $T lr((lr((x comma t)) comma a))$ is a
  uniform distribution over the successor-state set
  $lr((x plus d_x lr((a)) plus.minus epsilon.alt)) times lr((t plus d_t lr((a)) plus.minus epsilon.alt))$,
  where $d_x lr((a))$ and $d_t lr((a))$ respectively represent the
  direction of movement in space and time given action $a$, while
  $epsilon.alt$ models the uncertainty.
]<ex:random_walk>

#figure([#image("../Graphics/AISOLA23/RWExample.svg", width: 40%)], caption: [
  A random walk with action sequence _slow, slow, slow, slow, fast, slow, fast_.
])
<fig:RandomWalk>

A run $pi$ of an EMDP is an alternating sequence
$s_0 a_0 s_1 a_1 dots.h$ of states and actions such that
$T lr((s_i comma a_i)) lr((s_(i plus 1))) gt 0$ for all $i gt.eq 0$. A
(memoryless) strategy for an EMDP is a function
$sigma colon cal(S) arrow.r lr((italic("Act") arrow.r lr([0 comma 1])))$,
mapping a state to a probability distribution over $italic("Act")$.
Given a strategy $sigma$, the expected cost of reaching a goal state is
defined as the solution to a Volterra integral equation as follows:

<def:expcost> Let
$cal(M) eq lr((cal(S) comma s_0 comma italic("Act") comma T comma C comma cal(G)))$
be an EMDP and $sigma$ be a strategy. If a state $s$ can reach the goal
set $cal(G)$, the #emph[expected cost] is the solution to the following
recursive equation:

$ 
bb(E)_sigma^(cal(M)) (s) eq 
cases(delim: "{", 
  0 & upright("if ") s in cal(G), 
  sum_(a in italic("Act")) sigma (s) (a) dot.op integral_(s prime in cal(S)) T (s comma a) (s prime) dot.op ( C lr((s comma a comma s prime)) plus bb(E)_sigma^(cal(M)) lr((s prime)) ) thin d s prime & upright("if ") s in.not cal(G)
)
$

A strategy $sigma^ast.basic$ is optimal if it minimizes
$bb(E)_sigma^(cal(M)) lr((s_0))$. We note that there exists an optimal
strategy which is deterministic.

=== Stochastic Hybrid Systems
<stochastic-hybrid-systems>
In an EMDP, the environment responds instantaneously to an action
proposed by the agent according to the next-state density function $T$.
In a more refined view, the agent proposes actions with some period $P$,
and the response of the environment is a stochastic, time-bounded
trajectory (bounded by the period $P$) over the state space. For this
response, we use a stochastic hybrid system
(SHS) #cite(label("A:DBLP:journals/corr/abs-1208-3856")) #cite(label("A:DBLP:conf/formats/Larsen12")),
which allows the environment to interleave continuous evolution and
discrete jumps.

#subpar.grid(
    [#figure([#image("../Graphics/AISOLA23/BBSimple.png", )],
      caption: [
        SHA for the bouncing ball.
      ]
    )],

    [#figure([#image("../Graphics/AISOLA23/BallBounceDensity.svg", )],
      caption: [
        State density after one bounce.
      ]
    )],
  columns: 2, 
  caption: [
    An SHA for the bouncing ball and a visualization after one bounce.
  ],
  label:<fig:BBBehaviour>, 
)

A #emph[stochastic hybrid system] of dimension $k$ is a tuple
$H eq lr((cal(S) comma F comma mu comma eta))$ where

- $cal(S) subset.eq bb(R)^k$ is a bounded and closed part of
  $k$-dimensional Euclidean space,

- $F colon bb(R)_(gt.eq 0) times cal(S) arrow.r cal(S)$ is a flow
  function describing the evolution of the continuous state with respect
  to time, typically represented by differential equations,

- $mu colon cal(S) arrow.r lr((bb(R)_(gt.eq 0) arrow.r bb(R)_(gt.eq 0)))$
  maps each state $s$ to a delay density function $mu lr((s))$
  determining the time point for the next discrete jump, and

- $eta colon cal(S) arrow.r lr((cal(S) arrow.r bb(R)_(gt.eq 0)))$ maps
  each state $s$ to a density function $eta lr((s))$ determining the
  next state.

#example(name: "Bouncing ball")[
  To represent an SHS, we use a stochastic hybrid automaton
  (SHA) #cite(label("A:DBLP:journals/corr/abs-1208-3856")), which we only introduce
  informally here. @fig:BBBehaviour shows an SHA of a
  bouncing ball, which we use as a running example. Here the state of the
  ball is given by a pair $lr((p comma v))$ of continuous variables, where
  $p in bb(R)_(gt.eq 0)$ represents the current height (position) and
  $v in bb(R)$ represents the current velocity of the ball. Initially (not
  visible in the figure) the value of $v$ is zero while $p$ is picked
  randomly in $lr([7.0 semi 10.0])$. The behavior of the ball is defined
  by two differential equations: $v prime eq minus 9.81 m slash s^2$
  describing the velocity of a falling object and $p prime eq v$ stating
  that the rate of change of the height is the current velocity. The
  invariant $p gt.eq 0$ expresses that the height is always nonnegative.
  The single transition of the automaton triggers when $p lt.eq 0$, i.e.,
  when the ball hits the ground. In this case the velocity reverts
  direction and is subject to a random dampening effect (here "" draws a
  random number from $lr([0 comma 0.12])$ uniformly). The state density
  after one bounce is illustrated in @fig:BBBehaviour.
  The SHA induces the following SHS, where $delta$ denotes the Dirac delta
  distribution:

  - $cal(S) eq lr([0 comma 10]) times lr([minus 14 comma 14])$,

  - $F lr((lr((p comma v)) comma t)) eq lr((lr((minus 9.81 slash 2)) t^2 plus v t plus p comma minus 9.81 t plus v))$

  - $mu lr((lr((p comma v)))) eq delta ( (v plus sqrt(v^2 plus 2 dot.op 9.81 dot.op p)) slash 9.81 )$

  - $eta lr((lr((p comma v)))) eq lr((p comma v dot.op U_(lr([minus 0.97 comma minus 0.85]))))$,
    with uniform distribution $U_(lr([l comma u]))$ over
    $lr([l comma u])$.
] <example-bouncing-ball>

A timed run $rho$ of an SHS $H$ with $n$ jumps from an initial state
density $iota$ is a sequence
$rho eq s_0 s prime_0 t_0 s_1 s prime_1 t_1 s_2 s prime_2 dots.h t_(n minus 1) s_n s prime_n$
respecting the constraints of $H$, where each $t_i in bb(R)_(gt.eq 0)$.
The total duration of $rho$ is $sum_(i eq 0)^(n minus 1) t_i$, and the
density of $rho$ is
$iota lr((s_0)) dot.op product_(i eq 0)^(n minus 1) mu lr((s prime_i)) lr((t_i)) dot.op eta lr((s_(i plus 1))) lr((s prime_(i plus 1)))$.

Given an initial state density $iota$ and a time bound $T$, we denote by
$Delta_(H comma iota)^T$ the density function on $cal(S)$ determining
the state after a total delay of $T$, when starting in a state given by
$iota$. The following recursive equation defines
$Delta_(H comma iota)^T$:#footnote[For SHS with an upper bound on the
number of discrete jumps up to a given time bound $T$, the equation is
well-defined.]
$ Delta_(H comma iota)^T lr((s prime)) eq cases(delim: "{", iota lr((s prime)) & upright("if ") T eq 0, integral_s iota lr((s)) dot.op integral_(t lt.eq T) mu lr((s)) lr((t)) dot.op Delta_(H comma eta lr((F lr((t comma s)))))^(T minus t) lr((s prime)) thin d t thin d s & upright("if ") T gt 0) $

For $T eq 0$, the density of reaching $s prime$ is given by the initial
state density function $iota$. For $T gt 0$, reaching $s prime$ at $T$
first requires to start from an initial state $s$ (chosen according to
$iota$), followed by some delay $t$ (chosen according to $mu lr((s))$),
leaving the system in the state $F lr((t comma s))$. From this state it
remains to reach $s prime$ within time $lr((T minus t))$ using
$eta lr((F lr((t comma s))))$ as initial state density.

=== Hybrid Markov Decision Processes
<hybrid-markov-decision-processes>
A hybrid Markov decision process (HMDP) is essentially an EMDP where the
actions of the agent are selected according to some time period
$P in bb(R)_(gt.eq 0)$, and where the next-state probability density
function $T$ is obtained from an SHS.

<def:HDMP> A #emph[hybrid Markov decision process] is a tuple
$H M eq lr((cal(S) comma s_0 comma italic("Act") comma P comma N comma H comma C comma cal(G)))$
where $cal(S) comma s_0 comma italic("Act") comma C comma cal(G)$ are
defined the same way as for an EMDP, and

- $P in bb(R)_(gt.eq 0)$ is the period of the agent,

- $N colon cal(S) times italic("Act") arrow.r lr((cal(S) arrow.r bb(R)_(gt.eq 0)))$
  maps each state $s$ and action $a$ to a probability density function
  determining the immediate next state under $a$, and

- $H eq lr((cal(S) comma F comma mu comma eta))$ is a stochastic hybrid
  system describing the responses of the environment.

An HMDP
$H M eq lr((cal(S) comma s_0 comma italic("Act") comma P comma N comma H comma C comma cal(G)))$
induces the EMDP $M_(H M) eq$
$lr((cal(S) comma s_0 comma italic("Act") comma T comma C comma cal(G)))$,
where $T$ is given by
$T lr((s comma a)) eq Delta_(H comma N lr((s comma a)))^P$. That is, the
next-state probability density function of $M_(H M)$ is given by the
state density after a delay of $P$ (the period) according to $H$ with
initial state density $N$.


==== Example <ex:hitting> (Hitting the bouncing ball).
<example-hitting-the-bouncing-ball.>
@fig:HBB shows an HMDP extending the SHS of
the bouncing ball from @fig:BBBehaviour. Now a player
has to keep the ball bouncing indefinitely by periodically choosing
between the actions #emph[hit] and #emph[nohit],

#figure([#image("../Graphics/AISOLA23/HBB.png", width: 60%)], caption: [An HMDP for hitting a bouncing ball.]) <fig:HBB>

(three solid transitions). The period $P eq 0.1$ is modeled by a clock
$x$ with suitable invariant, guards and updates. The top transition
triggered by the #emph[nohit] action has no effect on the state (but
will have no cost). The #emph[hit] action affects the state only if the
height of the ball is at least 4m ($p gt.eq 4$). The left transition
applies if the ball is falling with a speed not greater than
$minus 4$m/s ($v gt.eq minus 4$) and accelerates to a velocity of
$minus 4$m/s. The right transition applies if the ball is rising, and
sets the velocity to a random value in
$lr([minus v minus 4 comma minus 0.9 v minus 4])$. The bottom dashed
transition represents the bounce of the ball as in
@fig:BBBehaviour, which is part of the environment
and outside the control of the agent.

A time-extended state $lr((p comma v comma t))$ is in the goal set $G$
if either $t gt.eq 120$ or $lr((p lt.eq 0.01 and lr(|v|) lt.eq 1))$ (the
ball is deemed dead). The cost ($C$) is 1 for the #emph[hit] action and
0 for the #emph[nohit] action, with an additional penalty of
$1 comma 000$ for transitions leading to a dead state.
@fig:UnshieldedTrace illustrates the near-optimal
strategy $sigma^ast.basic$ obtained by the RL method implemented in
#smallcaps[Uppaal Stratego] and the prefix of a random run. The expected
number of #emph[hit] actions of $sigma^ast.basic$ within 120s is
approximately $48$.$lt.tri$


#subpar.grid(
  [
    #figure([#image("../Graphics/AISOLA23/UnshieldedTrace1.svg")],
      caption: [
        Strategy.
      ]
    )
  ],
  [
    #figure([#image("../Graphics/AISOLA23/UnshieldedTrace2.svg")],
      caption: [
        Example run for 10 seconds.
      ]
    )

  ],
  columns: 2,
  label: <fig:UnshieldedTrace>,
  caption: [
    Near-optimal strategy learned by #smallcaps[Uppaal Stratego].
  ]
)

== Safety, Partitioning, Synthesis and Shielding
<sec:computingreachability>
=== Safety
<safety>
In this section we are concerned with a strategy obtained for a given
EMDP being #emph[safe]. For example, a safety strategy for hitting the
bouncing ball must ensure that the ball never reaches a dead state
($p lt.eq 0.01 and lr(|v|) lt.eq 1$). In fact, although safety was
encouraged by cost-tweaking, the strategy $sigma^ast.basic$ in
@fig:UnshieldedTrace is #emph[not] safe. In the
following we use symbolic techniques to synthesize safety strategies.

Let
$cal(M) eq lr((cal(S) comma s_0 comma italic("Act") comma T comma C comma cal(G)))$
be an EMDP. A safety property $phi$ is a set of states
$phi subset.eq cal(S)$. A run $pi eq s_0 a_0 s_1 a_1 s_2 dots.h$ is safe
with respect to $phi$ if $s_i in phi$ for all $i gt.eq 0$. Given a
nondeterministic strategy
$sigma colon cal(S) arrow.r 2^(italic("Act"))$, a run
$pi eq s_0 a_0 s_1 a_1 s_2 dots.h$ of $M$ is an outcome of $sigma$ if
$a_i in sigma lr((s_i))$ for all $i$. We say that $sigma$ is a safety
strategy with respect to $phi$ if all runs that are outcomes of $sigma$
are safe.

=== Partitioning and Strategies
<partitioning-and-strategies>
Given the infinite-state nature of the EMDP $M$, we will resort to
finite partitioning (similar to  #cite(label("A:ZikelicLHC23"))) of the state
space in order to algorithmically synthesize nondeterministic safety
strategies. Given a predefined granularity $gamma$, we partition the
state space into disjoint regions of equal size (we do this for
simplicity; our method is independent of the particular choice of the
partitioning). The partitioning along each dimension of $cal(S)$ is a
half-open interval belonging to the set
$cal(I)_gamma eq brace.l bracket.l k gamma semi k gamma plus gamma bracket.l divides k in bb(Z) brace.r$.
For a bounded $k$-dimensional state space $cal(S)$,
$cal(A) eq brace.l mu in cal(I)_gamma^k divides mu inter cal(S) eq.not nothing brace.r$
provides a finite partitioning of $cal(S)$ with granularity $gamma$. For
each $s in cal(S)$ we denote by $lr([s])_A$ the unique region containing
$s$.

Given an EMDP $M$, a partitioning $A$ induces a finite labeled
transition system
$T_M^A eq lr((cal(A) comma italic("Act") comma arrow.r))$, where
$ mu arrow.r_()^a mu prime arrow.l.r.double exists s in mu dot.basic med exists s prime in mu prime dot.basic med T lr((s comma a)) lr((s prime)) gt 0 dot.basic $

#subpar.grid(
  [#figure([#image("../Graphics/AISOLA23/SquaresReachabilityBarbaric.svg")],
    caption: [Scenario where the ball is rising and high enough to be hit. \ #hide("x")]
  )],

  [#figure([#image("../Graphics/AISOLA23/SquaresReachabilityBounceBarbaric.svg")],
    caption: [Scenario where the ball is too low to be hit, but bounces off the ground.]
  )],
  columns: 2,
  label: <fig:SquaresReachabilityGroup>,
  caption: [
    State-space partitioning for
    @ex:hitting. Starting in the blue
    region and depending on the action, the system can end up in the
    green regions within one time period, witnessed by simulations from
    $16$ initial states.
  ]
)

@fig:SquaresReachabilityGroup shows a partitioning for
the running example and displays some witnesses for transitions in the
induced transition system.

Next, we view $T_M^A$ as a 2-player game. For a region $mu in A$,
Player 1 challenges with an action $a in italic("Act")$. Player 2
responds with a region $mu prime in A$ such that
$mu arrow.r^a mu prime$.

Let $phi subset.eq cal(S)$ be a safety property and $A$ a partitioning.
We denote by $phi^A$ the set
$brace.l mu in A divides mu subset.eq phi brace.r$. The set of safe
regions with respect to $phi$ is the maximal set of regions $bb(S)_phi$
such that

$ bb(S)_phi eq phi^A inter brace.l mu divides exists a dot.basic med forall mu prime dot.basic med mu arrow.r^a mu prime arrow.r.double.long mu prime in bb(S)_phi brace.r dot.basic $ <defeq>

Given the finiteness of $A$ and monotonicity
of @defeq, $bb(S)_phi$ may be obtained in a finite
number of interations using Tarski’s fixed-point
theorem #cite(label("A:Tarski55")).

A (nondeterministic) strategy for $T_M^A$ is a function
$nu colon A arrow.r 2^(italic("Act"))$. The most permissive safety
strategy $nu_phi$ obtained from $bb(S)_phi$ #cite(label("A:BernetJW02")) is given
by
$ nu_phi lr((mu)) eq brace.l a divides forall mu prime dot.basic med mu arrow.r^a mu prime arrow.r.double.long mu prime in bb(S)_phi brace.r dot.basic $

The following theorem states that we can obtain a safety strategy for
the original EMDP $M$ from a safety strategy $nu$ for $T_M^A$.

#theorem()[Given an EMDP $M$, safety property
  $phi subset.eq cal(S)$ and partitioning $A$, if $nu$ is a safety
  strategy for $T_M^A$, then $sigma lr((s)) eq nu lr((lr([s])_(cal(A))))$
  is a safety strategy for $M$.
]<thm:safety_transfer> 

=== Approximating the 2-player Game
<approximating-the-2-player-game>
Let $M$ be an EMDP and $phi$ be a safety property. To algorithmically
compute the set of safe regions $bb(S)_phi$ for a given partitioning
$A$, and subsequently the most permissive safety strategy $nu_phi$, the
transition relation $arrow.r^a$ needs to be a decidable predicate. If
$M$ is derived from an HMDP
$H M eq lr((cal(S) comma s_0 comma italic("Act") comma P comma N comma H comma C comma cal(G)))$,
this requires decidability of the predicate
$Delta_(H comma N lr((s comma a)))^P lr((s prime)) gt 0$. Consider the
bouncing ball from @ex:hitting. The
regions are of the form
$mu eq brace.l lr((p comma v)) divides l_p lt.eq p lt u_p and l_v lt.eq v lt u_v brace.r$.
For given regions $mu comma mu prime$, the predicate
$mu arrow.r^(n o h i t) mu prime$ is equivalent to the following
first-order predicate over the reals (note that
$F lr((lr((p comma v)) comma t))$ is a pair of polynomials in
$p comma v$ and $t$):#footnote[We assume that at most one bounce can
take place within the period $P$.]
$ exists lr((p comma v)) in mu dot.basic med F lr((lr((p comma v)) comma P)) in mu prime or  & exists beta in lr([0.85 comma 0.97]) dot.basic med exists t prime lt.eq P dot.basic med exists v prime dot.basic\
 & F lr((lr((p comma v)) comma t prime)) eq lr((0 comma v prime)) and F lr((lr((0 comma minus beta dot.op v prime)) comma P minus t prime)) in mu prime $

#figure(kind: "algorithm", supplement: [Algorithm], placement: bottom,
  pseudocode-list(numbered-title: [Approximation of $->^a$], booktabs: true)[
    - *Input:* $mu in cal(A), a in italic("Act")$
    - *Output:* $mu ->^a_italic("app") mu' "iff" mu' in R$
    + $R = emptyset$
    + *For all* $s_i in italic("app")[mu]$ *do*
      + select $s'_i ~ N(s_i, a)$
      + simulate $cal(H)$ from $s'_i$ for $P$ time units
      + let $s''_i$ be the resulting state
      + add $[s''_i]_cal(A)$ to $R$
    - *End for*
  ]
)<MCAlgo>

For this simple example, the validity of the formula can be
decided #cite(label("A:Tarski48")), which may however require doubly exponential
time #cite(label("A:DavenportH88")), and worse, when considering nonlinear
dynamics with, e.g., trigonometric functions, the problem becomes
undecidable #cite(label("A:Laczkovich03")). One can obtain a conservative answer
via over-approximate reachability analysis #cite(label("A:DFPP18")); in
@sec:experiments we compare to such an approach and
demonstrate that, while effective, that approach also does not scale.
This motivates to use an efficient and robust alternative. We propose to
approximate the transition relation using equally spaced samples, which
are simulated according to the SHS $cal(H)$ underlying the given HMDP $cal("HM")$.


@MCAlgo describes how to compute an
approximation $mu arrow.r^a_(a p p) mu prime$ of
$mu arrow.r^a mu prime$. The algorithm draws from a finite set of $n$
evenly distributed supporting points per dimension
$a p p lr([mu]) eq brace.l s_1 comma dots.h comma s_(n^k) brace.r subset.eq mu$
and simulates $H$ for $P$ time units. A region $mu prime$ is declared
reachable from $mu$ under action $a$ if it is reached in at least one
simulation. When stochasticity is involved in a simulation, additional
care must be taken. The random variables can be considered an additional
dimension to be sampled from; alternatively, a worst-case value can be
used if available, such as the bouncing ball with the highest velocity
damping.
@fig:SquaresReachabilityGroup
illustrates 16 ($n eq 4$) possible starting points for the bouncing ball
together with most pessimistic outcomes, depending on the action taken.

The result $arrow.r^a_(a p p)$ is an underapproximation of the
transition relation $arrow.r^a$ , with a corresponding transition system
$hat(T)_M^A eq lr((cal(A) comma italic("Act") comma arrow.r^()_(a p p)))$.
Thus if we compute a safety strategy $nu$ from $arrow.r^a_(a p p)$, then
the strategy $sigma lr((s)) eq nu lr((lr([s])_(cal(A))))$ from
@thm:safety_transfer is not
necessarily safe. However, in @sec:experiments we
will see that this strategy is statistically safe in practice. We
attribute this to two reasons. 1) The underapproximation of
$arrow.r^a_(a p p)$ can be made accurate. 2) Since $arrow.r^a$ is
defined over an abstraction, it is often robust against small
approximation errors.

=== Shielding
<shielding>
As argued above, we can obtain the most permissive safety strategy
$nu_phi$ from $arrow.r^a_(a p p)$ over $cal(A)$ and then use
$sigma_phi lr((s)) eq nu_phi lr((lr([s])_(cal(A))))$ as an approximation
of the most permissive safety strategy over the original HMDP. We can
employ $sigma_phi$ to build a shield. As discussed in the introduction,
we focus on two ways of shielding: #emph[pre-shielding] and
#emph[post-shielding] (recall @fig:shieldingTypes). In
pre-shielding, the shield is already active during the learning phase of
the agent, which hence only trains on sets of safe actions. In
post-shielding, the shield is only applied after the learning phase, and
unsafe actions chosen by the agent are corrected (which is possibly
detrimental to the performance of the agent).

#figure(stack(dir: ltr, image("../Graphics/AISOLA23/RWShield.svg", width: 50%), image("../Graphics/AISOLA23/BBShield.svg", width: 50%)),
  placement: top,
  caption: [
    Synthesized nondeterministic strategies for \
    random walk (left) and bouncing ball
    (right).
  ]
) <fig:ShieldsRWBB>

@fig:ShieldsRWBB shows examples of such strategies for
the random walk (@ex:random_walk)
and the bouncing ball. As can be seen, most regions of the state space
are either unsafe (black) or both actions are safe (white). Only in a
small area (purple) will the strategy enforce walking fast or hitting
the ball, respectively. In the white area, the agent can learn the
action that leads to the highest performance.

#figure([#image("../Graphics/AISOLA23/StrategoMyPreShielding.svg", width: 100%)],
  placement: bottom,
  caption: [
    Complete method for pre-shielding and statistical model checking
    (SMC).
  ]
)
<fig:StrategoMyPreShielding>

We use #smallcaps[Uppaal Stratego] #cite(label("A:stratego")) to train a shielded
agent based on $sigma_phi$. The complete workflow of pre-shielding and
learning is depicted in @fig:StrategoMyPreShielding.
Starting from the EMDP, we partition the state space, obtain the
transition system using @MCAlgo and solve
the game according to a safety property $phi$, as described above. The
produced strategy is then conjoined with the original EMDP to form the
shielded EMDP, and reinforcement learning is used to produce a
near-optimal deterministic strategy $sigma^ast.basic$. This strategy can
then be used in the real world, or get evaluated via statistical model
checking. The only difference in the workflow in post-shielding is that
the strategy $sigma_phi$ is not applied to the EMDP, but on top of the
deterministic strategy $sigma^ast.basic$.

== Experiments
<sec:experiments>
In this section we study our proposed approach with regard to different
aspects of our shields. In addition to the random walk
(@ex:random_walk) and bouncing ball
(@ex:hitting), we consider three
benchmark cases:

- #emph[Cruise
  control] #cite(label("A:larsen2015cruisecontrol")) #cite(label("A:10.1007/978-3-030-23703-5_6")) #cite(label("A:DBLP:conf/qest/AshokKLCTW19")):
  A car is controlled to follow another car as closely as possible
  without crashing. Either car can accelerate, keep its speed, or
  decelerate freely, which makes finding a strategy challenging. This
  model was subject to several previous studies where a safety strategy
  was carefully designed, while our method can be directly applied
  without human effort.

- #emph[DC-DC converter] #cite(label("A:dcdcconverter")): This industrial DC-DC
  boost converter transforms input voltage of $10$V to output voltage of
  $15$V. The controller switches between storing energy in an inductor
  and releasing it. The output must stay in $plus.minus 0.5$V around
  $15$V, and the amount of switching should be minimized.

- #emph[Oil pump] #cite(label("A:hydac")): In this industrial case, flow of oil
  into an accumulator is controlled to satisfy minimum and maximum
  volume constraints, given a consumption pattern that is
  piecewise-constant and repeats every $20$ seconds. Since the exact
  consumption is unknown, a random perturbation is added to the
  reference value. To reduce wear, the volume should be kept low.

#subpar.grid(
  [#figure([#image("../Graphics/AISOLA23/CCShield.svg")],
    caption: [ Cruise control ($n eq 4$, $gamma eq 0.5$) when the car’s velocity is $0 m slash s$]
  ) <fig:CCShield>],

  grid.cell(rowspan: 2)[#figure([#image("../Graphics/AISOLA23/OPShieldOn.svg")],
    caption: [
      Oil pump ($n eq 4 comma gamma eq 0.1$) when the pump is #emph[on].
      The periodic piecewise consumption pattern has been overlaid.
      Turning off the pump requires it to stay off for two seconds,
      which could cause an underflow in the yellow area. Conversely, the
      purple area shows the states where the pump #emph[must] be turned
      off to avoid overflow. Since the pump is on in this projection,
      this can wait until the last moment.
    ]
  )
  <fig:OPShieldOn>],

  [#figure([#image("../Graphics/AISOLA23/DCShield.svg")],
    caption: [
      DC-DC boost converter ($n eq 4$, $gamma eq 0.01$) when the output
      resistance is $30 Omega$.
    ]
  )
  <fig:DCShield>],

  columns: 2,
  label: <fig:Shields>,
  caption: [
    Projected views of synthesized most permissive safety strategies.
  ]
)

@fig:Shields shows the synthesized most permissive
safety strategies. For instance, in @fig:CCShield we see
the strategy for the cruise-control example when the controlled car is
standing still. If the car in front is either close or reverses at high
speed, the controlled car must also reverse (purple area). The yellow
area shows states where it is safe to stand still but accelerating may
lead to a collision.

We conduct four series of experiments to study different aspects of our
approach.

The quality of our approximation of the transition relation
$arrow.r^a_(a p p)$,<lab:exp:bbtrans>

the computational performance of our approximation in comparison with a
fully symbolic approach,<lab:exp:julia>

the performance in terms of reward and safety of the pre- and
post-shields synthesized with our method, and<lab:exp:prepost>

the potential of post-optimization for post-shielding.<lab:exp:postopt>

All experiments are conducted on an AMD Ryzen 7 5700x with 33 GiB RAM.
Our implementation is written in Julia, and we use #smallcaps[Uppaal
Stratego] #cite(label("A:stratego")) for learning and statistical model checking.
The experiments are available online #cite(label("A:REP")).

=== Quality of the Approximated Transition System
<quality-of-the-approximated-transition-system>
In the first experiment we statistically assess the approximation
quality of $arrow.r^a_(a p p)$ wrt. the underlying infinite transition
system. For varying granularity $gamma$ of $cal(A)$ and numbers of
supporting points $n$ per dimension (see
@sec:computingreachability) we first compute
$arrow.r^a_(a p p)$ with @MCAlgo. Then we
uniformly sample $10^8$ states $s$ and compute their successor states
$s prime$ under a random action $a$. Finally we count how often
$lr([s])_(cal(A)) arrow.r^a_(a p p) lr([s prime])_(cal(A))$ holds.

#figure(stack(dir: ltr, image("../Graphics/AISOLA23/BarbaricAccuracyN.svg", width: 50%), image("../Graphics/AISOLA23/BarbaricAccuracyG.svg", width: 50%)),
  caption: [
    Accuracy of the approximation $arrow.r^a_(a p p)$ under different \
    granularity $gamma$ and number of supporting points $n$ per
    dimension.
  ]
)
<fig:BarbaricAccuracy>

Here we consider the bouncing-ball model, where we limit the domain to
$p in lr([0 comma 15])$, $v in lr([minus 15 comma 15])$. The results are
shown in @fig:BarbaricAccuracy. An increase in the
number of supporting points $n$ correlates with increased accuracy. For
$gamma lt.eq 1$, using $n eq 3$ supporting points already yields
accuracy above $99$%. Finer partition granularity $gamma$ increases
accuracy, but less so compared to increasing $n$.

=== Comparison with Fully Symbolic Approach
<comparison-with-fully-symbolic-approach>
As described in @sec:computingreachability, as an
alternative to @MCAlgo one can use a
reachability algorithm to obtain an overapproximation of the transition
relation $arrow.r^a$. Here we analyze the performance of such an
approach based on the reachability tool
#smallcaps[JuliaReach] #cite(label("A:JuliaReach")). Given a set of initial
states of a hybrid automaton where we have substituted probabilities by
nondeterminism, #smallcaps[JuliaReach] can compute an overapproximation
of the successor states. In #smallcaps[JuliaReach], we select the
reachability algorithm from #cite(label("A:GuernicG09")). This algorithm uses
time discretization, which requires a small time step to give precise
answers. This makes the approach expensive. For instance, for the
bouncing-ball system, the time period is $P eq 0.1$ time units, and a
time step of $0.001$ time units is required, which corresponds to $100$
iterations.

The shield obtained with #smallcaps[JuliaReach] is safe by construction.
To assess the safety of the shield obtained with
@MCAlgo, we choose an agent that selects
an action at random and let it act under the post-shield for $10^6$
episodes. (We use a random agent because a learned agent may have
learned to act safely most of the time and thus not challenge the shield
as much.) If no safety violation was detected, we compute 99% confidence
intervals for the statistical safety.

#figure([
  #let c(n, content) = table.cell(content, align: horizon, rowspan: n)
  #table(
    columns: 5,
    align: (col, row) => (center,center,center,right,center,).at(col),
    inset: 6pt,
    table.header(
      [#strong[$gamma$]], [#strong[$arrow.r^a_(a p p)$ method]],
      [#strong[Parameters]], [#strong[Time]], [#strong[Probability safe]]
    ),
    [0.02],   c(4)[@MCAlgo],   [$n eq 2$],  [1m 50s],  [unsafe run found],
    [0.02],                    [$n eq 4$],  [2m 14s],  [$lr([99.9999 percent semi 100 percent])$],
    [0.02],                    [$n eq 8$],  [4m 02s],  [$lr([99.9999 percent semi 100 percent])$],
    [0.02],                    [$n eq 16$],  [11m 03s],  [$lr([99.9999 percent semi 100 percent])$],
    table.hline(),
    [0.01],   c(4)[@MCAlgo],   [$n eq 2$],   [16m 49s],   [$lr([99.9999 percent semi 100 percent])$],
    [0.01],                    [$n eq 4$],   [19m 00s],   [$lr([99.9999 percent semi 100 percent])$],
    [0.01],                    [$n eq 8$],   [27m 21s],   [$lr([99.9999 percent semi 100 percent])$],
    [0.01],                    [$n eq 16$],   [56m 32s],   [$lr([99.9999 percent semi 100 percent])$],
    table.hline(),
    [0.01],   c(2)[#smallcaps[JuliaReach]],   [time step $0.002$],   [24h 30m],   [considers $s_0$ unsafe],
    [0.01],                                   [time step $0.001$],   [41h 05m],   [safe by construction],
  )],
  caption: [ Synthesis results for the bouncing ball under varying
    granularity ($gamma$) and supporting points ($n$) using
    @MCAlgo (top) and two choices of the
    time-step parameter using #smallcaps[JuliaReach] (bottom). The safety
    probability is computed for a 99% confidence interval. $gamma eq 0.02$
    corresponds to $9.0 dot.op 10^5$ partitions, and $gamma eq 0.01$
    quadruples the number of partitions to $3.6 dot.op 10^6$. ]
)<tab:BBSynthesis>


We consider again the bouncing-ball model. #smallcaps[JuliaReach]
requires a low partition granularity $gamma eq 0.01$; for
$gamma eq 0.02$ it cannot prove that a safety strategy exists, which may
be due to conservatism, while our method is able to synthesize a shield
that, for $n gt.eq 4$, is statistically safe.
@tab:BBSynthesis shows the results obtained from the
two approaches. In addition, the reachability algorithm uses time
discretization, and a small time step is required to find a safety
strategy.


We remark that the bouncing-ball model has linear dynamics, for which
reachability analysis is relatively efficient compared to nonlinear
dynamics, and thus this model works in favor of the symbolic method.
However, the hybrid nature of the model and the large number of queries
(one for each partition-action pair) still make the symbolic approach
expensive. Considering the case $gamma eq 0.01$ and $n eq 4$, our method
can synthesize a strategy in $19$ minutes, while the approach based on
#smallcaps[JuliaReach] takes $41$ hours.

@fig:DifferenceRigorousBarbaric
visualizes the two strategies and shows how the two approaches largely
agree on the synthesized shield – but also the slightly more pessimistic
nature of the transition relation computed with #smallcaps[JuliaReach].

#figure(
  image("../Graphics/AISOLA23/DifferenceRigorousBarbaric.svg"), 
  caption: [Superimposed strategies of our method and #smallcaps("JuliaReach").],
  placement: top
)<fig:DifferenceRigorousBarbaric>

=== Evaluation of Pre- and Post-shields
<evaluation-of-pre--and-post-shields>
In the next series of experiments, we evaluate the full method of
obtaining a shielded agent. The first step is to approximate
$arrow.r^a_(a p p)$ using @MCAlgo and
extract the most permissive safety strategy $sigma_phi$ to be used as a
shield. For the second step we have two options: pre- or post-shielding.
Recall from @fig:shieldingTypes that a pre-shield is
applied to the agent during training while a post-shield is applied
after training.

In the case of the bouncing ball, the post-shielded agent’s strategy is
shown in @fig:ShieldedTrace. It consists of the
unshielded strategy from @fig:UnshieldedTrace plus the
purple regions of the safety strategy in
@fig:ShieldsRWBB. Correspondingly,
@fig:ShieldedTrace shows the pre-shielded strategy,
which is significantly simpler because it does not explore unsafe
regions of the state space. This also leads to faster convergence.

#subpar.grid(
  figure([#image("../Graphics/AISOLA23/PreShieldedTrace.svg")],
    caption: [
      Pre-shield.
    ]
  ),
  figure([#image("../Graphics/AISOLA23/PostShieldedTrace.svg")],
    caption: [
      Post-shield.
    ]
  ),
  label:  <fig:ShieldedTrace>,
  columns: 2,
  caption: [
    Learned shielded strategies for the bouncing ball.
  ],
  placement: bottom,
)

Tables #ref(<tab:CCSynthesis>, supplement: none)---#ref(<tab:DCSynthesis>, supplement: none) report the same data as
in @tab:BBSynthesis for the other models. Overall, we
see a similar trend in all tables. For a low number of supporting points
(say, $n eq 3$) we can obtain a safety strategy that we find to be
statistically safe. In all cases, no unsafe run was detected in the
statistical evaluation. The synthesis time varies depending on the model
and is generally feasible. The longest computation times are seen for
the oil-pump example, which has the most dimensions. Still, times are
well below #smallcaps[JuliaReach] for the comparatively simple bouncing
ball.

#figure(table(
    columns: 4,
    align: (col, row) => (center,center,right,center,).at(col),
    inset: 6pt,
    table.header([#strong[$gamma$]], [#strong[$n$]], [#strong[Time]], [#strong[Probability safe]]),
    [1],    [2],    [1m 50s],    [Considers $s_0$ unsafe],
    [0.5],    [2],    [13m 16s],    [$lr([99.9995 percent semi 100 percent])$],
    [0.5],    [3],    [23m 03s],    [$lr([99.9995 percent semi 100 percent])$],
    [0.5],    [4],    [35m 55s],    [$lr([99.9995 percent semi 100 percent])$],
  ),
  caption: [Cruise control. $ gamma=1$ corresponds to $1.9 times 10^5$ partitions, and $ gamma=0.5$ to $1.5 times 10^6$.]
)<tab:CCSynthesis>

#figure(table(
    columns: 4,
    align: (col, row) => (center,center,right,center,).at(col),
    inset: 6pt,
    table.header([#strong[$gamma$]], [#strong[$n$]], [#strong[Time]], [#strong[Probability safe]]),
    [0.2],    [2],    [3m 07s],    [considers $s_0$ unsafe],
    [0.1],    [2],    [32m 15s],    [$lr([99.9995 percent semi 100 percent])$],
    [0.1],    [3],    [1h 37m],    [$lr([99.9995 percent semi 100 percent])$],
    [0.1],    [4],    [5h 23m],    [$lr([99.9995 percent semi 100 percent])$],
  ),
  caption: [Oil pump. $gamma=0.2$ corresponds to $2.8 times 10^5$ partitions, and $gamma=0.1$ to $1.1 times 10^6$.],
) <tab:OPSynthesis>

#figure(table(
    columns: 4,
    align: (col, row) => (center,center,right,center,).at(col),
    inset: 6pt,
    table.header([#strong[$gamma$]], [#strong[$n$]], [#strong[Time]], [#strong[Probability safe]]),
    [0.05],    [2],    [41s],    [$lr([99.9995 percent semi 100 percent])$],
    [0.05],    [3],    [1m 50s],    [considers $s_0$ unsafe],
    [0.05],    [4],    [3m 30s],    [considers $s_0$ unsafe],
    [0.02],    [2],    [3m 43s],    [$lr([99.9995 percent semi 100 percent])$],
    [0.02],    [3],    [8m 59s],    [$lr([99.9995 percent semi 100 percent])$],
    [0.02],    [4],    [18m 11s],    [$lr([99.9995 percent semi 100 percent])$],
    [0.01],    [2],    [15m 48s],    [$lr([99.9995 percent semi 100 percent])$],
    [0.01],    [3],    [38m 26s],    [$lr([99.9995 percent semi 100 percent])$],
    [0.01],    [4],    [1h 19m],    [$lr([99.9995 percent semi 100 percent])$],
  ),
  caption: [DC-DC boost converter. $gamma eq 0.05$ corresponds to
  $3.1 dot.op 10^5$ partitions, $gamma eq 0.02$ to $1.7 dot.op 10^6$ and
  $gamma eq 0.01$ to $7.0 dot.op 10^6 dot.basic$])
<tab:DCSynthesis>

#subpar.grid(
  grid.cell(rowspan: 2)[#figure(image("../Graphics/AISOLA23/RWShieldingResults.svg"),
    caption: [Average cost per run. \ #hide("x")]
  )<fig:RWShieldingResults>],

  [#figure(image("../Graphics/AISOLA23/RWShieldingDeaths.svg"),
    caption: [Safety violations for unshielded agents]
  )<fig:RWShieldingDeaths>],

  [#figure(image("../Graphics/AISOLA23/RWShieldingInterventions.svg"),
    caption: [Interventions for post-shielded agents.]
  )<fig:RWShieldingInterventions>],
  columns: 2,
  caption: [
    Results of shielding the random walk using $gamma eq 0.005$.
  ],
  label: <fig:RWShieldingResultsGroup>
)


#subpar.grid(
  grid.cell(rowspan: 2)[#figure(image("../Graphics/AISOLA23/BBShieldingResults.svg"),
    caption: [Average #emph[hit] actions per 120s. \ #hide("x")]
  )<fig:BBShieldingResults>],

  [#figure(image("../Graphics/AISOLA23/BBShieldingDeaths.svg"),
    caption: [Safety violations for unshielded agents.]
  )<fig:BBShieldingDeaths>],

  [#figure(image("../Graphics/AISOLA23/BBShieldingInterventions.svg"),
    caption: [Interventions for post-shielded agents.]
  )<fig:BBShieldingInterventions>],
  columns: 2,
  caption: [
    Results of shielding the bouncing ball using $n eq 16$,
    $gamma eq 0.01$.
  ],
  label: <fig:BBShieldingResultsGroup>
)

#subpar.grid(
  grid.cell(rowspan: 2)[#figure(image("../Graphics/AISOLA23/CCShieldingResults.svg"),
    caption: [Accumulated distance per 120s. \ #hide("x")]
  )<fig:CCShieldingResults>],

  [#figure(image("../Graphics/AISOLA23/CCShieldingDeaths.svg"),
    caption: [Safety violations for unshielded agents.]
  )<fig:CCShieldingDeaths>],

  [#figure(image("../Graphics/AISOLA23/CCShieldingInterventions.svg"),
    caption: [Interventions for post-shielded agents.]
  )<fig:CCShieldingInterventions>],
  columns: 2,
  caption: [
    Results of shielding the cruise control using $n eq 4$,
    $gamma eq 0.5$.
  ],
  label: <fig:CCShieldingResultsGroup>
)

#subpar.grid(
  grid.cell(rowspan: 2)[#figure(image("../Graphics/AISOLA23/DCShieldingResults.svg"),
    caption: [Accumulated error plus number of switches per 120s.]
  )<fig:DCShieldingResults>],

  [#figure(image("../Graphics/AISOLA23/DCShieldingDeaths.svg"),
    caption: [Safety violations for unshielded agents.]
  )<fig:DCShieldingDeaths>],

  [#figure(image("../Graphics/AISOLA23/DCShieldingInterventions.svg"),
    caption: [Interventions for post-shielded agents.]
  )<fig:DCShieldingInterventions>],
  columns: 2,
  caption: [
    Results of shielding the DC-DC boost converter using $n eq 4$,
    $gamma eq 0.01$.
  ],
  label: <fig:DCShieldingResultsGroup>
)

#subpar.grid(
  grid.cell(rowspan: 2)[#figure(image("../Graphics/AISOLA23/OPShieldingResults.svg"),
    caption: [Accumulated oil volume \ per 120s.]
  )<fig:OPShieldingResults>],

  [#figure(image("../Graphics/AISOLA23/OPShieldingDeaths.svg"),
    caption: [Safety violations for unshielded agents.]
  )<fig:OPShieldingDeaths>],

  [#figure(image("../Graphics/AISOLA23/OPShieldingInterventions.svg"),
    caption: [Interventions for post-shielded agents.]
  )<fig:OPShieldingInterventions>],
  columns: 2,
  caption: [
    Results of shielding the oil pump using $n eq 4$, $gamma eq 0.1$.
  ],
  label: <fig:OPShieldingResultsGroup>
)



Next, we compare our method to other options to make an agent safe(r).
As the baseline, we use the classic RL approach, where safety is
encouraged using reward shaping. We experiment with a deterrence
$d in brace.l 0 comma 10 comma 100 comma 1000 brace.r$ (negative reward)
as a penalty for safety violations for the learning agent. Note that
this penalty is only applied during training, and not included in the
total cost when we evaluate the agent below. As the second option, we
use a post-shielded agent, to which the deterrence also applies. The
third option is a pre-shielded agent. In all cases, training and
evaluation is repeated 10 times, and the mean value is reported. The
evaluation is based on 1000 traces for each repetition.

Figures #ref(<fig:RWShieldingResultsGroup>, supplement: none),
to #ref(<fig:OPShieldingResultsGroup>, supplement: none) report the results for the
different models. Each subfigure shows the following content: (a) shows
the average cost of the final agent, (b) shows the amount of safety
violations of the unshielded agents and (c) shows the number of times
the post-shielded agents were intervened by the shield.

Overall, we observe similar tendencies. The unshielded agent has lowest
average cost at deployment time under low deterrence, but it also
violates safety. Higher deterrence values improve safety, but do not
guarantee it.

The pre-shielded agents outperform the post-shielded agents. This is
because they learn a near-optimal strategy subject to the shield, while
the post-shielded agents may be based on a learned unsafe strategy that
contradicts the shield, and thus the shield interference can be more
detrimental.

#figure(table(
    columns: (3fr, 1fr, 1fr, 1fr, 1fr),
    align: (col, row) => (left,center,center,center,center,).at(col),
    inset: 6pt,
    table.header([#strong[Configuration]], table.cell(colspan: 2)[#strong[Cost]], table.cell(colspan: 2)[#strong[Interventions]]),
    [Baseline with \ uniformly  random choice],  table.cell(colspan: 2)[11371],  table.cell(colspan: 2)[13.50],
    table.hline(),
    [Minimizing interventions],  [11791],  [($plus 3.7 percent$)],  [11.43],  [($minus 15.3 percent$)],
    [Minimizing cost],  [10768],  [($minus 5.3 percent$)],  [17.43],  [($plus 29.1 percent$)],
    [Agent preference],  [11493],  [($minus 1.1 percent$)],  [14.55],  [($plus 7.8 percent$)],
    [Pre-shielded agent],  [6912],  [($minus 39.2 percent$)],  [–],  [–],
  ),
  caption: [Change of post-optimization relative to the
uniform-choice strategy. The strategy was trained for $12 comma 000$
episodes with $d eq 10$ and post-optimized for $4 comma 000$ episodes.
Performance of the pre-shielded agent is included for comparison, but
interventions are not applicable (because the shield was in place during
training).]
)<tab:CCPostShieldComparison>

=== Post-Shielding Optimization
<post-shielding-optimization>
When a post-shield intervenes, more than one action may be valid. This
leaves room for further optimization, for which we can use
#smallcaps[Uppaal Stratego]. Compared to a uniform baseline, we assess
three ways to resolve nondeterminism:
1) minimizing interventions,
2) minimizing cost and
3) at the preference of the shielded agent (the so-called Q-value #cite(label("A:Watkins89"))).

@tab:CCPostShieldComparison shows the effect of
post-optimization on the cost and the number of interventions for the
cruise-control example. Notably, cost is only marginally affected, but
the number of shield interventions can get significantly higher. The
pre-shielded agent has lower cost than all post-optimized alternatives.

== Conclusion
<sec:conc>
We presented a practical approach to synthesize a near-optimal safety
strategy via finite (2-player) abstractions of hybrid Markov decision
processes, which are systems of complex probabilistic and hybrid nature.
In particular, we deploy a simulation-based technique for inferring the
2-player abstraction, from which a safety shield can then be
constructed. We show with high statistical confidence that the shields
avoid unsafe outcomes in the case studies, and are significantly faster
to construct than when deploying symbolic techniques for computing a
correct 2-player abstraction. In particular, our method demonstrates
statistical safety on several case studies, two of which are industrial.
Furthermore, we study the difference between pre- and post-shielding,
reward engineering and a post-shielding optimization. In general, we
observe that reward engineering is insufficient to enforce safety, and
secondarily observe that pre-shielding provides better controller
performance compared to post-shielding.

Future work includes applying the method to more complex systems, and
using formal methods to verify the resulting safety strategies, maybe
based on #cite(label("A:ForetsFS20")).


#[
  #set heading(numbering: none) 
  == References

  #bibliographyx("../Bibliography.bib",
    prefix: "A:",
    title: none,
  )
]
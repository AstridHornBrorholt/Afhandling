#import "../Config/Macros.typ" : *
#import "@preview/cetz:0.4.2"
#import "@preview/subpar:0.2.2"
#import "@preview/lemmify:0.1.8": *
#import "@preview/lovelace:0.3.1": *

#let (
  theorem, lemma, corollary,
  remark, proposition, example,
  proof, definition, rules: thm-rules
) = default-theorems("thm-group", lang: "en", thm-numbering: thm-numbering-linear)

#[
  #set heading(numbering: none)
  = Introduction
]

Digital control of physical components enables time-saving automation and efficient use of available resources.
This can range from a simple if/then switch to a complex neural network managing multiple interconnected processes.
It is not uncommon for several digital components to be deployed in concert to serve complementary purposes.
Such cyber-physical systems @lee2006cyber @lee2008cyber are becoming more ubiquitous and more advanced.

With applications such as autonomous vehicles, water management systems, industrial hydraulics, and power controllers, great care must be taken to ensure the safety of people, equipment, and resources that are directly or indirectly affected by the system.
Under these safety constraints, the systems must also behave in a way that achieves their objectives efficiently.

This can be achieved through the field of formal methods, which has a wide variety of approaches that can provide proof that a given system restricts itself to a safe subset of behaviours #cl("HandbookOfModelChecking")@lewis2012optimal@doyle2013feedback.
This presumes an accurate model of the (cyber-physical) system under verification. 
However, with the complexity of many real-world systems, correct-by-construction methods of policy synthesis become computationally infeasible.

_Reinforcement learning_ (RL) #cl("DBLP:books/lib/SuttonB98") @kaelbling1996reinforcement @arulkumaran2017deep has proven useful at approximating the optimal policy through exploration even in complex systems.
RL methods based on neural networks #cl("DBLP:journals/nature/LeCunBH15") are especially notable for having achieved impressive performance in a wide variety of tasks #cl("DBLP:journals/nature/SchrittwieserAH20").
This performance is achieved by controllers that use a high number of neurons, making direct formal verification infeasible.


*Shielding* @AlshiekhBEKNT18 @BloemKKW15@DavidJLLLST14 is a promising technique that restricts the behaviour of an RL policy in a way that formally guarantees a safety specification.
A _shield,_ tasked with enforcing this safety specification, acts as a guardrail to keep the RL policy within safe bounds.
To do so, the shield must avoid any states where leaving the bounds cannot be prevented.
Synthesizing such a shield is subject to the same complexities discussed above, but these can be significantly mitigated by creating a safety-relevant abstraction.
This abstraction omits aspects of the system that are only relevant for keeping track of the reward.
This shield can then be combined with an efficient policy, such as one obtained by RL, to achieve both safety and efficiency.
Therefore, shielding has been widely studied in the literature 
#cl("DBLP:conf/concur/0001KJSB20")#cl("DBLP:conf/aaai/Carr0JT23")#cl("DBLP:conf/nips/MelcerAT22")
but the ability of a shield to enforce safety depends on which assumptions can be made about the system, and there is no truly scalable "silver bullet" to ensure safety in all cases.

This thesis continues the work of developing novel shielding methods -- with a focus on scalability -- that enforce safety under systems and assumptions that are realistic for real-world cyber-physical systems.
The thesis will address shielding  hybrid systems, multi-agent settings and unknown environments, and describes efforts to enhance scalability, and accessibility through the development of user-friendly tools.

The remainder of this introduction will describe the basics first of RL, then of shielding.
These fundamental definitions are used as a basis for formulating a research hypothesis, after which alternative systems and shielding approaches are described. 
The last part of the introduction summarises the papers which make up the remainder of this thesis.

== Reinforcement Learning <sec:rl>

RL  #cl("DBLP:books/lib/SuttonB98", "kaelbling1996reinforcement", "arulkumaran2017deep") is a major class of machine learning techniques, separate from supervised and unsupervised learning @alloghani2020systematic.
In supervised learning, models learn from labelled data, to predict the labels of unseen data.
Unsupervised (or self-supervised) learning similarly trains the model on a set amount of unlabelled data, to discover relevant patterns and approximations.
In contrast, reinforcement learning _agents_ are actively interacting with a system, directing exploration and receiving observation data and rewards, as the system responds to actions taken by the agent.

The interaction between an agent and a system is illustrated in @fig:RL:
The agent observes its current state, and makes a decision on which action to take.
Taking the action yields a reward that the agent can use to update its policy, and an observation of the updated state which it will use to pick the next action.

#figure(include("../Graphics/Intro/Unshielded.typ"), caption: [The reinforcement learning loop.] )<fig:RL>

The reinforcement learning problem can be stated in many different ways, depending on the nature of the problem, but is perhaps most commonly defined in terms of a Markov decision process (MDP) #cl("Puterman94").
MDPs describe stochastic systems, where the outcomes of actions only depend on the current (observable) state of the system, and not on which actions or states were seen previously.

#definition(name: "MDP")[
An MDP is defined as a tuple $(S, s_0, A, P, R)$ where
  - $S$ is a finite set of states,
  - $s_0 in S$ is the initial state,
  - $A$ is a finite set of actions,
  - $P : S times A → (S → [0; 1])$ with  $forall s in S, a in A : sum_(s' in S) P(s, a)(s') = 1$ is the transition function, which gives the  probability of reaching state $s'$ from state $s$ as a result of  taking the action $a$, 
  - and $R : S times A times S -> RR$ gives the reward $R(s, a, s')$ for reaching $s'$ by taking $a$ in $s$.
]<def:mdp>

The state-space $S$ is often represented as a finite set of vectors over $ZZ^n$ where each element of a state-vector represents the value of a variable in the model (usually defined within a bounded interval).
The number of states $|S|$ grows exponentially with the number of variables $n$. This growth is known as _state-space explosion._

The definition also requires every action $a in A$ to be defined for every state in $S$. 
This assumption is made w.l.o.g. to simplify notation.

Sometimes models are defined as having a cost $C$ to be minimized, rather than reward $R$ to be maximised. These definitions are effectively interchangeable, as any cost can be re-defined as reward by flipping its sign: $R(s, a, s') = -C(s, a, s')$.
To maximise the reward yielded by $R$, a policy $pi$ acts upon the model $mdp$.

#definition(name: "Policy")[
  A policy  is a function that chooses the next action from a given state. 
  There are three different kinds of policy:
    - _deterministic_ $S -> A$, uniquely selecting one specific action for each state, 
    - _probabilistic_ $S -> (A -> [0; 1])$, giving a probability distribution ($forall s in S : sum_(a in A) pi(s)(a) = 1$) over actions, 
    - or _nondeterministic_ $S -> powerset(A) \\ emptyset $, giving a set $A' subset.eq A$ of possible actions. 

]<def:policy>

#definition(name: "Traces, trace segments")[
  For an MDP $mdp$, a _trace_ $xi$ is an interleaved series of states and actions $xi = s_0 a_0 s_1 a_1 s_2 a_2 ...$ starting in the initial state~$s_0$. 
  A trace $xi$ is an _outcome_ of a probabilistic policy $pi : S -> (A -> [0; 1])$ if for every $i >= 0$ it holds $pi(s_i)(a_i) > 0$ and $P(s_i, a_i)(s_(i+1)) > 0$.
  Outcomes are defined similarly for deterministic and nondeterministic policies.

  Since @def:mdp does not include a stopping condition, traces will be infinite.
  A finite section of a trace $xi_m^n = s_m a_m s_(m + 1) a_(m + 1) ... a_(n-1) s_n$ are the interleaved states and actions from $s_m$ up to $s_n$.
  Other types of models may produce finite traces, if they have a stopping criterion, e.g. a set of terminal states, or a probability that the system abruptly halts. 
]<def:trace>

To express the reward obtained by an infinite trace, it is not useful to simply consider the sum of rewards.
This is illustrated in the following example.

#example(name: "Injection Moulding")[
  A factory has an indefinite contract to produce injection moulded components for a fixed price per unit.
  Every cycle, the factory can choose to produce a batch of 100 units (abbreviated to the action $p$) or clean the mould and then produce a single unit (action $c$).
  The mould has 2 states: clean ($○$) and contaminated ($◍$). 
  
  When producing a batch in a clean mould, there is a $5%$ risk of contamination.
  A contaminated mould may compromise quality, but as stipulated by the contract this does not factor in to the price paid per unit.

  #figure(image("../Graphics/Intro/Factory.png", width: 120pt),
    caption: [MDP representing an injection moulding process. Solid lines represent actions. Dashed lines show possible outcomes of actions, giving a probability of occurring (as percentage) and the resulting reward.]
  )<fig:InjectionMoulding>
  
  The MDP $cal(I) = (S, s_0, A, P, R)$ modelling this system is shown in @fig:InjectionMoulding.
  It has state space $S = { ○, ◍ }$ with initial state $s_0 = ○$, and actions $A = { p, c }$. 

  The transition function is given as $ P(○, p)(○) = 0.95, P(○, p)(◍) = 0.05$ and deterministically $1.00 = P(◍, p)(◍) = & P(○, c)(○) = P(◍, c)(○) $. 
  For all $s, s' in S$ the reward is $R(s, p, s') = 100$ and $R(s, c, s') = 1$.

  Imagine one policy that cleans the moulds after each unit produced, and another policy that always produces a batch of units without concern for quality. 
  These policies are $pi(s) = p$ and $pi'(s) = c$ for either $s in S$.
  Is the policy $pi'$ more profitable than $pi$? We see that 
  $ lim_(n -> infinity) sum_(i=0)^n 1 && = infinity  = 
   lim_(n -> infinity) sum_(i=0)^n 100 $
]<ex:InjectionMoulding>

To measure the relative usefulness of strategies over an infinite horizon, a  discount factor $gamma in #h(4pt) ]0; 1]$ is applied to the reward, giving preference to more immediate gains.
This _discounted_ reward is defined as $R_gamma (xi) = sum_(i=0)^infinity gamma^i R(s_i)$. 
Note that in the special case where $gamma = 1$, $R_1$ is the same as the undiscounted reward $R$.
The discount factor $gamma$ may be interpreted as the probability of the trace continuing, while with probability $1 - gamma$ the trace may end in the next step, losing access to future rewards.

#example[
  With $mdp, pi$ and $pi'$ as in @ex:InjectionMoulding, a discounted reward can be used to compare them.
  For example, $gamma = 0.99$ gives the geometric series
  $ & lim_(n -> infinity) sum_(i=0)^n 0.99^i times 1 && = 1/(1-0.99) = 100  & "and" \
     & lim_(n -> infinity) sum_(i=0)^n 0.99^i times 100 && = 100/(1-0.99) = 10000 & "" $
]<ex:discounted>

In contrast to the reward gained from just one trace, the expected discounted reward #cl("DBLP:books/lib/SuttonB98") for a probabilistic policy is defined as:

#definition(name: "Expected reward")[
  Given an MDP $M = (S, s_0, A, P, R)$, a deterministic policy $pi : S -> A$ and a discount factor $gamma in #h(4pt) ]0; 1]$, the expected reward of $pi$ on $mdp$ at state $s in S$ is the unique fixed point of the following equation:

  $ EE_pi^mdp (s) = sum_(s' in S) P(s, pi(s))(s') (R(s, pi(s), s') + gamma  EE_pi^mdp (s')) $ 

  A similar definition of expected reward can be given for probabilistic policies $pi : S → (A → [0;1])$.
  It is undefined for nondeterministic policies.

  $ EE_pi^mdp (s) = sum_(a in A) pi(s)(a) sum_(s' in S) P(s, a)(s') (R(s, a, s') + gamma  EE_pi^mdp (s')) $ 
]<def:expected-reward>

This is used in the definition of the optimization problem of finding the policy with the highest expected discounted reward for $mdp$.

#definition(name:"Optimization problem")[
  Given an MDP $mdp = (S, s_0, A, P, R)$ and a discount factor $gamma$, find the policy $pi^star$ such that

  $ pi^star = argmax_(pi) EE_pi^mdp (s_0) $
]<def:Optimization>

For an MDP, the optimal policy is deterministic #cl("DBLP:books/lib/SuttonB98").
It may be possible to compute $pi^star$ directly, through e.g. direct search, through dynamic- or linear programming, or to accurately approximate them using value iteration #cl("DBLP:books/lib/SuttonB98").
These methods require full knowledge of the transition probabilities $P$ and rewards $R$, and have polynomial runtime on the number of states $|S|$ which make them suitable for a wide range of problems, with up to millions of states on modern hardware.
However, MDPs are often described using several variables or components. Known as the _state-space explosion,_ the size of the state-space is exponential in the number of these components or variables.  

If the state-space is prohibitively large, or the MDP is not fully known but can be sampled from, the optimal policy may instead be approximated through learning. 

#todo[The following section conflates representations, implementations, and learning algorithms. Re-write.]

State of the art reinforcement learning techniques learn intricate behaviour through deep neural networks such as PPO~#cl("DBLP:journals/corr/SchulmanWDRK17"), and decision trees such as random forest~#cl("DBLP:journals/ml/Breiman01"), or a combination of the two like MuZero~#cl("DBLP:journals/nature/SchrittwieserAH20").
In the following, a description of the comparatively simple Q-learning approach will be given. The method serves to illustrate the core concepts of reinforcement learning, such as the difference between on-policy and off-policy learning, value estimation, and exploration strategies. 

=== Q-learning <sec:QLearning>

Q-learning @QLearning @Watkins89 #cl("DBLP:books/lib/SuttonB98") is a model-free, off-policy, reinforcement learning algorithm for models that have finite state- and action-space.
The algorithm maintains a "Q-table"  that represents for every pair $(s, a)$ the estimated expected reward for taking action $a$ in state $s$.
It is the function $Q : S times A -> RR$, which is updated in every step.

The table can be initialized arbitrarily,
#footnote[However if the model has terminal states $T subset S$, then $Q$ must be initialized such that $forall t in T, a in A : Q (t, a) = 0$.]
e.g. $Q (s, a) = 0.1$ for all $s in S, a in A$.
Although there is no theoretical requirement on the initialization of $Q$ it may be natural to use random values, zeroes, a heuristic, or a relatively high ("optimistic") value to encourage exploration.

The notational shorthand $Q [(s, a) mapsto x]$ is used to describe updates to the function where its value is changed to $x$ for $Q(s, a)$, while remaining unaltered for all other values in its domain. I.e. $Q [(s, a) mapsto x](s', a') = cases(x & "if" (s', a') = (s, a), Q(s', a') &"otherwise")$.

By gradual updates to $Q$, the function will approximate the expected reward for taking action $a$ in state $s$.
The method of approximation is given in @alg:QLearning, with the update rule shown in @l:QUpdate.
Note the similarity of the update rule to @def:expected-reward.
The algorithm has additional input parameters, which will be described in the following.

#figure(kind: "algorithm", supplement: "Algorithm", 
  pseudocode-list(numbered-title: [Q-learning])[
    - *Input:* MDP $mdp = (S, s_0, A, P, R)$, 
      discount factor $gamma$,
      initial $Q : S times A -> RR$,
      number of episodes $n$,
      episode length $m$,
      learning rate $alpha : NN -> #h(4pt) ]0; 1]$,
      and 
      exploration factor $epsilon : NN -> [ 0; 1]$.
      
    - *Output:* Approximation $hat(pi) : S -> A$ of the optimal deterministic policy.
    + *Loop*  $i ← 0$ *up to* $n - 1$ *inclusive*
      + $s ← s_0$
      + *Loop* $j ← 0$ *up to* $m - 1$ *inclusive*                         #line-label(<l:EpisodeLoop>)
        + Flip a weighted coin that has probability $epsilon(i)$ of landing on heads.
        + *If* heads *then*  select $a$ according to a uniform distribution over $A$ #line-label(<l:Explore>) 
        + *Else* $a  ← argmax_(a' in A) Q (s, a') $   #line-label(<l:Exploit>) 
        + $s' ~ P(s, a)$ #comment[Take action $a$ in state $s$, call the next state $s'$.]
        + #line-label(<l:QUpdate>) #v(.8em)
          $Q ← Q[(s, a) &mapsto \
            &(1-alpha(i))Q (s, a) + alpha (i) (R(s, a, s') + gamma max_(a' in A) Q (s', a')) ]$ 
        + $s ← s'$
    + *Return* $hat(pi) (s) = argmax_(a in A) Q (s, a)$ #line-label(<l:Return>)
  ],
)<alg:QLearning>

The algorithm explores the model $mdp$ over a number of episodes $n$, which are finite traces that are cut off at length $m$.
This inner loop ensures, that $s_0$ will be visited at least $n$ times.
Setting $m$ too low may impact the estimate, since the policy will not be able to capitalize on future rewards beyond step $m$. 
Thus, $m$ should be picked according to $gamma$ such that $gamma^m$ is suitably low. 

Updates are performed according to a learning rate $alpha: NN -> [0; 1[$, a function over the learning steps.
This represents how much the new experience should influence the estimation of $Q(s,a)$.
As the number of episodes increases, so does the number of times $Q(s,a)$ is updated, and a decreasing learning rate reflects growing confidence in the estimate.

The $epsilon$-greedy exploration strategy in @alg:QLearning ensures that every possible transition is taken infinitely often in an infinite number of episodes. That is, with with $P(s, a)(s') > 0$ and $s$ reachable from $s_0$, the expected number of times a transition triple $s a s'$ is seen increases with the number of episodes $n$.

The $epsilon$-greedy exploration strategy is conceptually simple, and therefore used in many textbooks and standard implementations.
Other exploration strategies exist that makes better use of existing knowledge to find out which actions are worth exploring.
These include upper confidence bound #cl("DBLP:books/lib/SuttonB98"), Boltzmann exploration @kaelbling1996reinforcement,  Thompson sampling @thompson1933likelihood@daniel2018tutorial or by adding an entropy term to the loss function of deep RL @williams1991function@foster_entropy.
The use of Q-values that are relatively high compared to the actual expected reward is another way to encourage exploration  #cl("DBLP:books/lib/SuttonB98").

Notice how the Q-update in @l:QUpdate uses the current reward, and the Q-value of the best action in the next state.
As such, it estimates the expected reward obtained by greedily selecting the most rewarding action each step, as is the case for the policy~$hat(pi)$ returned in @l:Return.
Because the estimate assumes a purely greedy policy, it does not match how the Q-learning agent explores, which uses $ε$-greedy action selection.
This makes Q-learning an _off-policy_ algorithm, since it explores the environment with one policy ($epsilon$-greedy) but estimates the expected return of a different policy (entirely greedy).
The similar reinforcement learning method _SARSA_  @rummery1994line#cl("DBLP:books/lib/SuttonB98") is _on-policy_ because it uses Q-values of actions actually taken.
This is done by augmenting the term $gamma max_(a' in A) Q(s', a')$ to include the $ε$ chance of instead exploring a random action: $(1 - ε(i)) gamma max_(a' in A) Q(s', a') + ε(i) sum_(a'' in A) Q(s', a'')/(|A|)$.

Q-learning is an early example of an algorithm which was proven @QLearning to almost surely converge to the optimal policy, as the number of episodes $n$ (and episode length $m$) goes to infinity.
The proof requires that the environment remains static, i.e. $mdp$ does not change during learning.
It also requires the learning rate to satisfy the assumption, $sum_i^infinity alpha(i) = infinity and sum_i^infinity alpha(i)^2 < infinity$.
This condition can be stated informally as "$alpha$ decreases towards zero, but not too fast."
The intuition behind the proof is that the value update in @l:QUpdate requires that every transition triple $(s, a, s')$ occurs infinitely often.
This is ensured by the fact that $s_0$ is visited infinitely often as $n -> infinity$ and that there is always a non-zero chance (by $epsilon(i) > 0$) of eventually reaching state $s$ and taking action $a$ in $s$.

#example(name: "Grid World")[
  A robot 🤖 can move around along the cardinal directions on a $4 times 4$ grid, and must find an efficient path towards a goal 🏁 while avoiding a harmful tile 💀.  Movement is deterministic except for the ice tiles 🧊 where there is a chance of slipping in a different random direction. 
  The system is defined by the MDP $cal(W) = (S, s_0, A, P, R)$, with $S={1, 2, ...,  16}$, $s_0=14$ and $A={⬅, ⬆, ➡, ⬇}$. $P$ and $R$ are described below:

  The state-space is laid out in a $4 times 4$ grid as illustrated in @fig:GridWorld, with $s_0$ marked by 🤖.
  With the exception of states 10, 11, (🧊) 15 (💀) and 16(🏁), transitions deterministically follow the cardinal direction indicated by the action. If the action would cause the agent to leave the grid, it remains in the same state.  

  For example, $P(1, ➡)(2)  = 1$ (for $s!=2$ then $P(1, ➡)(s) = 0$), $P(2, ⬇)(6) = 1$ and $P(5, ⬅)(5) = 1$.
  
  In states 10 and 11, there is a 0.625 probability of moving in the manner described above, while the remaining probability mass is distributed among the other directions, i.e. $P(11, ➡)(15) = 0.125$. States 15 and 16 are terminal, which is modelled as $P(15, a)(15) = 1$ and $P(16, a)(16) = 1$ for any $a$. 
  
  The reward $R$ is defined for any action $a$ as 
   - $R(15, a, 15) = 0$ and $R(16, a, 16) = 0$. (Terminate in 💀 and 🏁.)
   - $R(s, a, 15) = -50$ for $s != 15$. (💀)
   - $R(s, a, s') = -1$ otherwise.
  
    #figure(
      {
        set text(size: 8pt)
        table(
          stroke: 0.4pt,
          columns: (auto, auto, auto, auto),
          align: left,
          inset: (bottom: 12pt),
          rows: 4,
          [ 1], [ 2], [ 3], [ 4],
          [ 5], [ 6], [ 7], [ 8],
          [ 9], [ 10 🧊], [ 11 🧊], [12],
          [ 13 #hide([🧊])], [ 14 🤖], [ 15 💀], [ 16 🏁],
        )
      },
      caption: [A map showing the initial state of Grid World with slippery tiles 🧊, an untimely end 💀, a goal state 🏁, and  initial agent position 🤖.]
    )<fig:GridWorld>
  
  Q-learning is performed with a discount factor of  $gamma = 0.9$, episode length $m=100$, initial $Q(s) = 0$ for all $s in S$, and learning rate $alpha$ and exploration factor $epsilon$:

  $ alpha(i) = epsilon(i) = cases(0.1 &"if" i < n/2, 0.1/(1 + 0.01*(i - n/2)) &"otherwise") $

  Outcomes of Q-learning in Grid World $cal(W)$ with these parameters are shown in @fig:QGraph and @fig:VTable.
  The graph in @fig:QGraph shows the sum of rewards collected in each episode, up to $n=500$.
  The resulting policy is visualized in @fig:VTable, which shows for every state $s$, the policy's action $hat(pi)(s) = argmax_(a in A) Q(s, a)$, and the state's _value_ $V(s) = max_(a in A) Q(s, a)$.

  Since the learning process is stochastic, it may return a different policy each time.
  In this case, the policy passes through state 10, taking a fast but somewhat risky route to the 🏁 goal. 

  Notice how the values have still not converged, and that the estimates are least accurate for the states furthest from the policy's route. 
  For example the value of state 8 has converged to $Q(8, ⬇) = R(8, ⬇, 12) + gamma Q(12, ⬇) = -1 + 0.9 times -1 = #{-1 + 0.9 * -1}$. 
  However, the action suggested in state 1 is not helpful, and the estimated reward for following it is not low enough.

  #subpar.grid(columns: 3, align: top,
    [#figure(image("../Graphics/Intro/Q-learning 500.png"),
      caption: [Cumulative reward.]
    )<fig:QGraph>],
    [#figure(image("../Graphics/Intro/V-table 500.png"),
      caption: [Value $max_a Q(s, a)$ and best action \ after 500 episodes.]
    )<fig:VTable>],
    [#figure(image("../Graphics/Intro/V-table Prism.png"),
      caption: [Expected reward computed by #prism.]
    )<fig:VTablePrism>],
    label: <fig:gridQ>,
    caption: [Q-learning in the grid world.]
  )

  After training, the behaviour of the policy during operation (cf. @sec:TrainingAndOperation) was simulated by generating 1000 traces of length 100, using the resulting greedy policy (returned in @l:Return of @alg:QLearning).
  The mean undiscounted reward was found to be -7.624.

  During evaluation, the policy was seen to reach 💀, which is unsurprising since it passes through state 10.
  Re-training the policy with the same parameters may yield a safe policy.
  This can be made more likely through changes to the reward function, giving a heavier penalty for reaching this state.
  However it is not straightforward to determine how the reward function should be defined in order to guarantee convergence to a safe policy, or whether this is even possible for a given model.

  The same MDP can be modelled in the model-checking tool #prism @PRISM, and the optimal policy can be approximated precisely and quickly by its built-in value iteration method.
  #footnote[Discounted cost was implemented using a variable `t` that increments each step, multiplying the cost `C` with `gamma^t`. The query `Rmin=?[C<=100]` was used to compute cost. Cost was converted to reward by flipping the sign.]
  The resulting state values $V(s)$ are shown in @fig:VTablePrism.
]<ex:GridWorld>

=== Training and Operation Phases <sec:TrainingAndOperation>

When discussing solutions developed for cyber-physical systems, it can be useful to distinguish between two phases:
Initial training, and subsequent operation as part of a real-life system.
The *training phase* is defined as the period where the agent changes its policy to gradually improve expected reward, possibly in a controlled environment. 
This is followed by the *operation phase* where the policy is no longer mutable, always taking the best action according to the final policy.

In the common view of reinforcement learning, the agent is continually exploring, learning, and improving, even when in operation #cl("DBLP:books/lib/SuttonB98")@kaelbling1996reinforcement.
Importantly, this lets the policy respond to changes in the environment (which are not uncommon despite the theoretical assumption that the system is static).
However, continually training the agent is not always possible in practice.
Legal requirements may warrant a costly re-certification every time changes are made to a policy, prohibiting the agent from adapting its behaviour during operation.
Technical limitations during operations may also preclude learning, such as in embedded platforms. Reductions may have even been applied to the policy representation, in order to stay within memory limits.
Such a reduction could be the transformation from a Q-table to a list of state-action pairs, discarding the exact Q-values and keeping only the optimal action for each state.


== Safety through Shielding <sec:Shielding>

Complex physical systems may have multiple requirements placed upon them, which cannot always be combined into a single reward signal.
These requirements may be in tension with each other, and it could be that some concerns should always come first, such as the safety of people or equipment. 

=== Safety <sec:Safety>

Safety properties are a subset of properties on a system, which describe a state, or finite sequence of states, that should never occur.
In @ex:InjectionMoulding, the safety property could be "the mould is cleaned as soon as it becomes contaminated." 
I.e. the state $◍$  is always followed by $○$, or equivalently, the sequence ◍ ◍ never occurs. (See @ex:QualityInjectionMoulding)
A safety property for @ex:GridWorld could be "the state 💀 is never reached." (See @ex:GridWorldSafety.)
A subset of safety properties are invariants, that are sets of individual states that should not be reached.
The aforementioned safety property "never 💀" is an invariant, while "never ◍ ◍" is not.

Besides safety, the other category of properties to describe a system is liveness.  
Such properties state that an event will eventually occur in the system, with no time bound on when this should be fulfilled.
This could be e.g. "the mould is eventually cleaned" or "the state 🏁 is eventually reached."
If a time bound is given on the event(s) occurring, the statement becomes a safety property, since any finite sequence of states where the bound is exceeded becomes a witness of its violation.

The focus in this thesis is on safety:
Consider again an MDP $mdp = (S, s_0, A, P, R)$. Formally, a property is a safety property iff for every trace $xi = s_0 a_0 s_1 a_1 ...$ that violates the property, there exists an $i in NN$ such that the finite sub-trace $xi_0^i = s_0 a_0 ... a_(i-1) s_i$ is enough to show the property is violated #cl("DBLP:reference/mc/ClarkeHV18").
An important fragment of the safety properties are invariants, expressing that some proposition holds in every state.
The safety property $forall s_i : s_i != 💀$, is an invariant.
These properties can be given as a set of states, $phi$, or as the _linear temporal logic_ (LTL) #cl("DBLP:reference/mc/ClarkeHV18")#cl("DBLP:reference/mc/PitermanP18") safety fragment "$#strong("AG") psi$" where $psi$ is a predicate on $S$.

A safety property can be re-formulated as an invariant by modifying the MDP, so it includes a "monitor" that will move the model to a specific state if the property is violated. 
In the following, safety will be discussed in terms of invariants, given as a set of safe states.

#definition(name: "Safe states, traces and policies")[
  For an MDP $mdp$ and a safe set $phi subset.eq S$, a state $s in S$ is safe if $s in phi$. 
  Given a safe set $phi$, a trace $xi$ is safe if for every $s_i$ in $xi$, $s_i in phi$.
  This extends to sections of traces $xi_n^m$ in the natural way.
  A policy $pi$ is safe with regard to $phi$ if every trace that is an outcome of $pi$ is safe.
 Safety according to $phi$ is indicated with $models$, as respectively $s models phi$, $xi models phi$ and $pi models phi$.
]<def:Safety>

A safe set $phi$ does not necessarily have a safe policy $pi models phi$. For example, consider a Grid World $cal(W)' = (S, s_0, A, P, R)$ as described in @ex:GridWorld, except with $s_0 = 10$.
From this initial state, there is a nonzero probability of reaching 💀 regardless of which actions are taken.
The safe set $S \\ {💀}$ is said to be infeasible for $cal(W)'$.


#definition(name: "Feasibility")[
  A safe set $phi$ is said to be feasible for an MDP $mdp$ if there exists at least one safe policy $pi models phi$ for $mdp$.
]<def:Feasibility>

However, some policies may be safe with higher probability than others. For a discussion of probabilistic safety and shielding, see @sec:ProbabilisticShielding.

The optimization problem stated in @def:Optimization does not include a notion of safety, and as noted in @ex:GridWorld, a policy might not converge to safe behaviour.
Even then, the convergence guarantee for Q-learning relies on an infinite number of traces, meaning that models trained in practice may not have learned fully safe behaviour even if the reward function is correctly designed to encourage it.

=== Shielding

Among the many approaches to enforcing safety in reinforcement learning  #cl("DBLP:conf/iros/WenET15")#cl("DBLP:conf/tacas/Junges0DTK16")#cl("DBLP:journals/jmlr/GarciaF15")@MaderbacherSBBNK23@ChengOMB19@LuoM21@BloemKKW15#cl("DBLP:conf/isola/Jaeger0BLJ20")@BerkenkampTS017, shielding @DavidJLLLST14@AlshiekhBEKNT18@BloemKKW15@ChowNDG18#cl("DBLP:journals/cacm/KonighoferBJJP25") is a promising technique which restricts the actions available to the agent, in order to ensure safe behaviour.
Since shields work by restricting actions, they can be applied to any existing reinforcement learning method, including deep learning, allowing it to work in concert with state of the art methods to achieve safe and optimized behaviour.

#definition(name: "Shield, maximally permissive shield, permitted policies")[
  For an MDP $mdp$ and safe set $phi$, a _shield_ is a safe nondeterministic policy $shield : S -> powerset(A)$.
  
  A shield $shield$ for a safe set $phi$ and MDP $mdp$ is _maximally permissive_ if for all shields $shield'$ for $φ$ and $mdp$, and for all states $s in S$,  it holds that $shield'(s) subset.eq shield(s)$

  An action $a$ is permitted in state $s$ by $shield$ if $a in shield(s)$. A deterministic policy $pi$ is permitted by $shield$ if $forall s in S : pi(s) in shield(s)$.
  Similarly for a nondeterministic policy $pi$ if $forall s in S : pi(s) subset.eq shield(s)$.
  And for a probabilistic policy $pi(s, a) > 0 => a in shield(s)$.
  The application of a shield in a reinforcement learning setting is discussed in @sec:ApplyingTheShield.
]<def:Shielding>

For any MDP $mdp$ and feasible safe set $phi$, a unique maximally permissive shield exists @BernetJW02 @PaperB.
Many shield synthesis methods guarantee the resulting shield will be maximally permissive for the given model, such as @AlshiekhBEKNT18@DavidJLLLST14@PaperA#cl("DBLP:journals/cacm/KonighoferBJJP25").
The permissiveness of the shield is an important property, since an overly restrictive shield can severely harm the performance of the resulting policy.

#example(name: "Quality standards for injection moulding")[
  Due to concerns over quality, the contract from @ex:InjectionMoulding is re-negotiated to require that the mould is immediately cleaned whenever it becomes contaminated. 

  Recall the MDP $cal(I) = ({○, ◍},○, { p, c }, P, R)$ shown in @fig:InjectionMoulding. This new requirement in the contract corresponds to the safety property "for any trace $xi = s_0, a_0, s_1, a_1...$, for every $s_i$ in $xi$, $s_i = ◍  => s_(i+1) = ○$."

  This safety property can be turned into an invariant, by extending the state-space to $S={○, ◍, ●}$ with the safe set $phi = {○, ◍}$.
  The state $●$ is reached when a batch is produced in a contaminated mould, as shown in @fig:QualityInjectionMoulding. 

  #figure(image("../Graphics/Intro/FactorySink.png", width: 200pt),
    caption: [MDP representing an injection moulding process.]
  )<fig:QualityInjectionMoulding>

  The maximally permissive shield which enforces the invariant $phi$ is  respectively $shield(○) = {p, c}$, $shield(◍) = {c}$ and $shield(●) = emptyset$.
  The optimal policy under this shield is $pi(○) = p, pi(◍) = c$.
  Let $gamma = 0.99$. The expected reward for this policy as given by @def:expected-reward is:

  #let expectation = $EE^cal(I)_pi$
  $ expectation(○) = &P(○, p)(○)(R(○, p, ○) + gamma expectation(○)) \
    + &P(○, p)(◍)(R(○, p, ◍) + gamma expectation(◍)) \
    = &0.95(100 + 0.99 expectation(○)) + 0.05(100 + 0.99 expectation(◍)) \
  $
  Since $expectation(◍) = 1 + 0.99 expectation(○)$, the equation reduces to  \
  $expectation(○) = 
  (100 + 0.05 times 0.99)/(1 - 0.95 times 0.99 - 0.05 times 0.99^2) approx 9533.06$.

  A less permissive shield with $shield^-(○) = {c}$, $shield^-(◍) = {c}$ and $shield^-(●) = emptyset$
  is still safe, but disallows the optimal policy. The only policy allowed by $shield^-$ is the one which collects an expected discounted reward of 100 (cf. @ex:discounted).
] <ex:QualityInjectionMoulding>

=== Origin of the Term

In the 2014 paper by David et al. @DavidJLLLST14, it was shown how a safety property can be enforced through a maximally permissive, safe, non-deterministic policy.
While acting within the constraints of this policy, reinforcement learning was utilized to optimize for a second objective, achieving near-optimal behaviour within the safety constraints.

The term *shield* was coined in @BloemKKW15 to describe a component which would work in concert with a (mostly safe) policy, and intervene to prevent unsafe behaviour.
Thus, the behaviour of the shield and policy together is verifiably safe, as long as the shield is safe.
Contrary to runtime monitors #cl("DBLP:journals/csr/KhouryT12")#cl("DBLP:journals/tse/DelgadoGR04"), which enforce a property by retroactively altering or halting a trace, the shield will intervene by altering the actions of the policy.
The authors proposed guarantees of minimal interference, and of $k$-stabilization, which states that the shield will at most intervene $k$ times before control is handed back to the policy.

This concept was extended to a framework of *shielded reinforcement learning* in @AlshiekhBEKNT18.
Here, a shield monitors and possibly corrects the actions of a learning agent, which enables safe exploration.
This enables the safe use of complex learning agents that can achieve cost optimal behaviour.
Approaches such as deep Q-learning or proximal policy optimization can be safely used in this framework, even though these methods cannot feasibly be verified directly.

The paper describes how a "shield" can be synthesized from an *abstract model* of the system, one which only models behaviour relevant to the safety property being enforced.
Such an abstraction could be significantly simpler than the full system, allowing shielded reinforcement learning to scale to systems where other methods for safe and optimal control are infeasible.
This is illustrated in @ex:SafetyRelevantAbstraction.

Since this first article covering shielded reinforcement learning in finite MDPs, other shielding methods building upon the same framework have been described in the literature #cl("DBLP:conf/concur/0001KJSB20")@9196867@BastaniL21@PaperA@PaperC@PaperB#cl("DBLP:journals/corr/ZhangB19")#cl("DBLP:conf/amcc/BharadwajBDKT19")#cl("DBLP:conf/atal/Elsayed-AlyBAET21")#cl("DBLP:conf/atal/XiaoLD23")#cl("DBLP:conf/aaai/Carr0JT23")#cl("DBLP:conf/atva/PrangerKPB21")@PaperD@MedicalShielding#cl("DBLP:conf/isola/TapplerPKMBL22")#cl("DBLP:conf/ijcai/YangMRR23")@giacobbe_shielding_2021#cl("DBLP:conf/atal/XiaoLD23")@bloem_its_2020#cl("DBLP:journals/corr/abs-2509-12085").

#example(name: "Safety-relevant Abstraction")[
  The contract from @ex:QualityInjectionMoulding is once again re-negotiated, this time to replace a fixed price of batches with variable pricing scheme depending on market forces.
  (The safety requirement to avoid state $●$ is kept.)
  Rather than a fixed reward of 100 for producing a full batch, the reward now varies and can at times be negative to reflect the sale price going below the cost to produce a batch.
  The option to wait $w$ is therefore added to the action space $A = {p, c, w}$. This action always has reward zero.

  The sale price is not known in advance, but can be predicted based on (say)
  - the number of times the action $p$ was taken in the last 100 steps,
  - the week of the year,
  - whether the MSCI World stock market index is trending _up_ or _down,_ and 
  - the quality of the material used for casting, on a 10-step scale.

  These market factors all become part of the state-space, which grows in size from $|{○, ◍, ●}| = 3$ to size $3 times 100 times 52 times 2 times 10 = 312#h(1pt)000$.
  This growth in the state-space from adding just four variables is an example of state-space explosion.

  The updated reward function $R$ and transition function $P$ will not be given here.
  Instead, it is sufficient to note that the state-space has become significantly larger, but not in a way that affects the safety property.
  To stay within the safe set, it is still sufficient to always clean $c$ the mould whenever a state with $◍$ is entered, regardless of the other values in a state.

  Thus, the model described in @ex:QualityInjectionMoulding is a _safety-relevant abstraction_ of the more complex model given in this example.
  The state-space of this abstraction is significantly smaller, and for some models, such reductions can make shield synthesis computationally feasible where it was not otherwise.
]<ex:SafetyRelevantAbstraction>


=== Pre- and Post-shielding During Training and Operation <sec:ApplyingTheShield>

There are multiple options for how and when a shield is applied.
The terms _pre-_ and _post-shielding_ #cl("DBLP:journals/corr/abs-1708-08611") #cl("DBLP:journals/cacm/KonighoferBJJP25") commonly refer to how the shield is applied.
Additionally, this section introduces terms to describe when the shield is in use.
A brief overview of the terms is given below, followed by detailed descriptions of each.

/ How: the shield ensures only safe actions reach the environment:
  / Pre-shielding: gives a set of safe actions that the shielded agent or policy must choose from.(@fig:PreShielding)
  / Post-shielding: changes unsafe actions to alternative, safe actions. Safe actions remain unchanged. (@fig:PostShielding)
/ When: the shield is an active component:
  / Training-only: uses the shield in the training phase, and produces a trained policy that is safe by construction. (@fig:TrainingOnly)
  / End-to-end: has a shield in place during both training an operation.  Necessary when a policy representation is not safe by construction. (@fig:EndToEnd)
  / Operation-only: adds a shield during operation to a -- potentially unsafe -- policy that was trained without access to a shield. (@fig:OperationOnly)

When and how the shield is employed are orthogonal properties, and the terms can be freely combined.
For example, a training-only shielding setup can use either a pre- or post-shield.


#subpar.grid(columns: 2,
  [#figure(include("../Graphics/Intro/Pre-shielding.typ"),
  caption: [Pre-shielding],
  )<fig:PreShielding>],
  [#figure(include("../Graphics/Intro/Post-shielding.typ"),
    caption: [Post-shielding],
  )<fig:PostShielding>], 
  caption: [*How* the shield ensures only safe actions reach the environment.],
  label: <fig:PrePostShielding>
)
#subpar.grid(columns: 3, align: top,
  [#figure(include("../Graphics/Intro/Training Only.typ"),
  caption: [Training only.]
  )<fig:TrainingOnly>],
  [#figure(include("../Graphics/Intro/End-to-end Shielding.typ"),
  caption: [End-to-end shielding.]
  )<fig:EndToEnd>],
  [#figure(include("../Graphics/Intro/Operation Only.typ"),
    caption:[Operation only.]
  )<fig:OperationOnly>],
  caption: [*When* the shied is applied in the process of obtaining a policy.],
  label: <when_shielding>
)

#remark[
  The terminology introduced in this section does not align with #paperref(<paper:A>).
  This section distinguishes two sets of concepts which are described by the paper as linked, as shown in @tab:NamingDiscrepancy.
  The paper uses _post-shielding_ to mean operation-only post-shielding.
  Conversely, the paper uses _pre-shielding_ to mean end-to-end pre-shielding.

  #figure(table(columns: (2), align: center,
      table.header( [*Term used in #paperref(<paper:A>)* #h(.5em)], [*Corresponding terms in this section*] ),
      [Pre-shielding], [End-to-end Pre-shielding ],
      table.hline(),
      [Post-shielding], [Operation-only Post-shielding]
    ),
    caption: [This section uses different terms compared to #paperref(<paper:A>).]
  )<tab:NamingDiscrepancy>
]
==== Pre-shielding
Illustrated in @fig:PreShielding, this term refers to the shield $shield$ restricting the behaviour of the the policy by providing a set of actions $shield(s) subset.eq A$, that are permitted for the given state $s$.
The learning must be set up in such a way as to only pick an action $a$ if it is included in the set $shield(s)$.

For Q-learning, unsafe actions can be excluded from consideration as follows: 
For some default value $q_0$ and bottom element $-infinity$, the Q-values can be initialized as $Q(s, a) = cases(-infinity &" if " a in.not shield(s), q_0 &"otherwise")$.
If $epsilon$-greedy exploration (@l:Explore in @alg:QLearning) is used, the exploratory actions should picked from just $shield(s)$ and not the full action space $A$.

Directly applying the shield to the Q-table is possible because the learning method is able to assign values to every state in the finite state-space.
A similar approach is not possible for e.g. decision trees, neural networks, etc. where states in the system are not explicitly represented. 

==== Post-shielding <sec:postshielding>
Rather than provide a set of safe actions to choose from, post-shielding overrides the RL algorithm whenever it takes an unsafe action.
The RL algorithm can choose any action $a in A$, which, as shown in @fig:PostShielding, is intercepted by the shield.
If the action is safe, the shield passes it on to the environment unaltered.
Otherwise an alternative, safe, action is chosen according to a fallback policy.

This is akin to modifying the the MDP $mdp = (S, s_0, A, P, R)$ with a new transition-  and reward function.
In addition to a shield $shield$, post-shielding requires a deterministic fallback policy 
#footnote[The symbol $fehu$ is the runic letter _fehu._]
$fehu : S → A$,
with $fehu(s) = a => a in shield(s)$. The shield $shield$ and fallback policy $fehu$ induce a post-shielded MDP $mdp^shield_fehu = (S, s_0, A, P^shield_(#h(1.5pt) fehu), R^shield_fehu)$.
The transition function will choose the fallback action, if the suggested action is unsafe:

$ P^shield_(#h(1.5pt) fehu)(s, a)(s') = cases(
  P(s, a)(s') &"if" a in shield(s), 
  P(s, fehu(s))(s') &"otherwise"
) $<eq:PostShieldedTransitionFunction>

And the reward function is updated to reflect this:

$ R^shield_fehu (s, a, s') = cases(
  R(s, a, s') & "if" a in shield(s),
  R(s, fehu(s), s')& "otherwise"
) $<eq:PostShieldedReward>

The fallback policy $fehu$ could pick actions from an ordering, choose according to a model-specific heuristic, or always select a universally safe action, if one exists.
A probabilistic fallback function may pick among safe actions according to a uniform distribution.

Note that the fallback policy must be static during the training phase, (when applicable) in order to preserve convergence guarantees.
Otherwise, $P^shield_(#h(1.5pt) fehu)$ will change during training, violating the assumption that the environment is static.

#remark(name: "Value Updates in Post-shielding")[
  The value updates for post-shielding are performed in the natural way, but subtle mistakes in the implementation can void the convergence guarantees.
  Consider Q-learning performed on a post-shielded MDP $mdp^shield_fehu = (S, s_0, A, P^shield_fehu, R^shield_fehu)$.
  Say that in state $s$,  the shield alters an unsafe action $a in.not shield(s)$ to the safe alternative $a' = fehu(s)$, reaching state $s'$.
  Then, the value update should be performed for $a$ and not $a'$.
  I.e. $Q(s, a)$ is updated with reward $R^shield_fehu (s, a, s')$
  #footnote[Equivalent to $R (s, a', s')$ cf. @eq:PostShieldedReward.]
   as in @alg:QLearning, @l:QUpdate.
  It would be unsound to only update $Q(s, a')$, or to use the unaltered reward $R(s, a, s')$ from the original MDP.

  When updated correctly, the model will learn the outcome of picking $a in.not shield(s)$ as $sum_(s' in S) P(s, a')(s')R(s, a', s')$.
  Other alterations to how value-updates are performed may be sound.
  For example, penalising unsafe actions can reduce the number of times the shield has to intervene #cl("DBLP:conf/ijcnn/SeurinPP20").
]

Both pre- and post-shielding preserve the assumptions necessary to guarantee convergence of a reinforcement learning algorithm to an optimal policy, but pre-shielding will likely converge faster than post-shielding in general:
If a model has a state $s$, with one safe action $a_1$ and unsafe actions $a_2$ and $a_3$, a post-shielded agent will have to explore actions $a_1, a_2$ and $a_3$ to estimate the expected reward attainable in $s$.
However, a pre-shielded agent will only explore $a_1$, since the other actions are masked.
Thus, it will gain a more precise estimate of the expected value of $s$ from the same amount of visits to the state.
A post-shielded agent may also choose to visit $s$ more often, if the RL method is configured to encourage exploration.

==== Training-only Shielding
When a shield is applied during the training phase, the resulting policy is often safe by construction. 
Thus, it is only necessary to represent the shield explicitly during training (@fig:TrainingOnly).

With a shield in place during training, the RL agent can avoid safety violations in all steps of the process.
This is a necessity if the RL agent is interacting with a real-life system where safety violations pose a danger to people or equipment.

Compared to the completely unshielded case, shielded training was seen in @AlshiekhBEKNT18 to lead to a higher expected reward when given the same number of episodes.
The authors speculate that the shield acts as a teacher guiding the agent away from undesirable behaviours.
The same tendency has been observed in other works #cl("DBLP:conf/aaai/Carr0JT23", "DBLP:conf/ijcai/YangMRR23", "DBLP:journals/corr/abs-2509-12085")@PaperA.
This is not a general rule however, and there are also examples of shielded policies yielding less reward than the unshielded one @bloem_its_2020#cl("DBLP:conf/aaai/CourtBG25"). These are cases where the shield prevents exploitation of risky but more rewarding behaviour.

Care must be taken when putting the trained policy into operation, in order to preserve safety guarantees.
Since the state-space $S$ is finite, a deterministic policy can be encoded as a set of state-action pairs $(s, a) in S times A$.
Shielded policies encoded in this way will naturally have $a in shield(s)$ for all encoded pairs $(s, a)$.
#footnote[The encoded policy is still shielded according to @def:Shielding, but the full shield is not kept.]
Such an encoding can save space on embedded hardware, which might not be able to accommodate an explicit representation of the shield.

Training-only shielding is not always an option. For e.g. neural networks working on continuous state-spaces, this $(s, a)$ representation is not possible.
Here, the shield needs to be kept during operation, as described in the next section.



==== End-to-end Shielding
When the shield is in place and explicitly represented during _both_ the learning  _and_ operational phases, this is called end-to-end shielding (@fig:EndToEnd).
This is a necessity for continuous state-spaces that cannot be represented as a state-action lookup table.
Instead, the shield must be kept along with the policy representation when put into operation, so it can preserve the safe behaviour.
Reductions can be applied to the shield before operation, to reduce its memory footprint significantly @PaperB@PaperD.

As stated earlier, an end-to-end setup can make use of either a pre- or post-shield.
However, alternating between the two with e.g. pre-shielded training and a post-shielded operation will negatively impact the expected reward.
The trained policy depends on how the shield is applied, and a change to the shield would disrupt it.

==== Operation-only Shielding

Shielding is not widely adopted in the industry, and many shield synthesis techniques require a detailed (safety-relevant) model of the system.
Therefore, policies that are "safe in practice" might be trained, tested and implemented at great expense.
Some time during operation, a shield may then be developed to provide formal safety guarantees, but it might not be cost effective or necessary to re-train the policy from scratch.

In these cases, the shield can be applied only in the operational phase.
If the policy did learn to avoid unsafe states perfectly, a maximally permissive shield would not interfere with its operation.
Otherwise, the shield will disrupt the optimized behaviour which the policy has learned.
It was found in #paperref(<paper:A>) @PaperA that applying an operation-only post-shield to a policy can lead to substantial drops in the expected reward.
Therefore, operation-only shielding should only be employed when re-training or (fine-tuning) the existing policy is not possible.

#example(name: "Staying safe in Grid World")[
  Recall the MDP $cal(W)=(S, s_0, A, P, R)$ from @ex:GridWorld.
  Let the safe set be $phi=S \\ {💀}$. 
  What is the most permissive shield for $cal(W)$?
  Certainly, taking $➡$ in state 14 is prohibited.
  Next, any action in state 11 carries a risk of slipping and ending up in  💀, so state 11 should never be entered.
  Lastly, any action in state 10 can cause the agent to slip onto state 11, so this state should be avoided as well. 
  
  @fig:GridWorldShield shows the resulting maximally permissive safe policy for @ex:GridWorld. 
  This policy was generated using a publicly available package @GridShielding.jl which implements the method described in #paperref(<paper:A>) (to be discussed in later sections).

#subpar.grid(columns: 3, align: bottom,
  [#figure(image("../Graphics/Intro/Shielded.png", width: 66.666%),
    caption: [A shield icon 🛡️ indicates the action is not permitted. A hatched area marks unreachable states.]
  )<fig:GridWorldShield>],
  [#figure(image("../Graphics/Intro/Shielded Q-learning 500.png", width: 66.666%),
    caption: [Cumulative reward for a shielded Q-learning agent. \ #hide("a")]
  )<fig:GridWorldShieldedTraining>],
  caption: [Most permissive shield for Grid World.]
)

  This can be applied as a pre-shield by 
  1. Initializing the Q-values as $Q(s, a) = cases(-infinity &"if" a in.not shield(s), 0  &"otherwise")$.
  2. Modifying the $epsilon$-greedy exploration strategy (@l:Explore in @alg:QLearning) to explore only safe actions $shield(s)$, instead of the full action space $A$.

  With this approach, the shield can be training-only since the greedy policy (Returned in @l:Return of @alg:QLearning) will be safe by construction. 

  The result of training-only pre-shielding of the Grid World example is shown in @fig:GridWorldShieldedTraining.
  Compared to @fig:QGraph, this shielded learning graph has no sudden drops in episode rewards.
  Such drops in @fig:QGraph indicate episodes where the agent is penalised for reaching state 15 💀.
  With the shield acting as a teacher, a reliable policy is quickly found, and no safety violations were encountered during training.

  An operation phase was simulated in the same manner as described in @ex:GridWorld: By generating 1000 traces each of length 100.
  As expected, the policy trained under a pre-shield was safe during operation, even without explicitly shielding the actions.
  This policy was found to yield a mean reward of exactly $-8$, the shortest amount of steps needed to circumnavigate the ice.

  Adding a shield to the policy from @ex:GridWorld  (operation-only shielding) also produced a safe policy with a mean reward of $-8$.
  This is because the policy had learned the correct route without crossing 🧊️.
  Re-running the example with different random seeds, the operation-only shielded policy was always safe, but would sometimes not reach 🏁️.
]<ex:GridWorldSafety>

== Finite- and Infinite-horizon Shielding <sec:ShieldingHorizon>

Note that @def:Shielding requires safety over all infinite traces that are outcomes of the shield.
This will require computing the shield offline, which can be computationally infeasible for some models or safety-relevant abstractions. 
Instead, a shield may only give guarantees $k$ steps into the future, computed on-line at each step.
(E.g. by searching for a policy safe for $k$ steps, starting at the current state.)

This avoids the initial (intractable) cost of computing the shield, instead incurring a smaller computational cost at each step.
When steps happen at a fixed frequency or has a maximum waiting period, it is important that the on-line computation of safe actions does not exceed these deadlines.

This outlook is sometimes called _receding horizon_ because the lookahead is always $k$ steps ahead from the current state. It has also been referred to as a _bounded prescience_  shield @giacobbe_shielding_2021, or _$k$-step lookahead_ shield #cl("DBLP:conf/ijcai/YangMRR23", "DBLP:conf/atal/XiaoLD23").

#definition(name: "Bounded Safety, bounded shielding")[
  Let $phi$ be a safe set for the MDP $mdp$.
  A trace $xi = s_0 a_0 s_1 a_1 ...$ is _safe in state $s in S$  for $k in NN$ steps_ if, for every $s_i = s$, the trace segment $xi_i^(k+i)$ is safe. I.e. $forall i in NN, s_i = s : xi_i^(k+i) models phi$.

  A policy  $pi$ is safe in state $s in S$ for $k$ steps if every outcome $xi$ of $pi$ is safe in $s$ for $k$ steps.

  A single state $s$ is safe for $k$ steps if there exists a policy $pi$ safe for $k$ steps in $s$.

  A nondeterministic policy is a _$k$-step lookahead shield_ $shield^k$ if  for every $s in S$ that is safe for $k$ steps, $shield^k$ is safe in $s$ for $k$ steps.
]<def:FiniteHorizon>



Finite-horizon shielding is also the standard formulation of probabilistic shielding, which will be introduced in the following section.

== Probabilistic Shielding <sec:ProbabilisticShielding>

Not every safe set is feasible (cf. @def:Feasibility), i.e. it is not always possible to ensure that a policy is safe 100% of the time from the initial state.
This can be due to uncertainty about behaviour of the underlying system -- which gets modelled as probabilistic behaviour -- or it can be a genuine reflection of a system where failure is always a possibility.
In such cases, methods like @AlshiekhBEKNT18@bloem_its_2020, that assume the worst-case outcome of any action, will fail.

When inherent uncertainty precludes methods that give absolute guarantees, there are still ways of improving the chances of staying safe.
This section is concerned with staying safe with high probability, rather than the absolute guarantees of #ref(<def:Safety>, supplement: "Definitions") #ref(<def:Shielding>, supplement: "and").
@ex:DoubleOrNothing is a case where an absolute shield is not feasible, but the risk varies depending on the choice of actions.

#example(name: "Double or Nothing")[
  A six-pack of cola is staked on a wager: A coin is flipped up to two times, where the second flip is for double or nothing.
  Choosing not to play is a losing move, so there is no way to guarantee the safety property "wager is not lost."

  #figure(image("../Graphics/Intro/DoubleOrNothing.drawio.pdf"),
  caption:[
    Double or nothing. The initial state is $⦾$.
  ])<fig:DoubleOrNothing>

  This wager is represented as an MDP $cal(D)$ shown in @fig:DoubleOrNothing. Let the safe set $phi = {⦾, ○, ☺}$.
  Transitions are omitted for $☺$ and $☹$, which are terminal states where all actions lead back to themselves at zero reward. 

  Clearly, there is no way to stay within the safe set with probability $1.0$.
  However the strategy $pi(s) = flip$ risks leaving the safe set~$phi$ with probability  $0.75$, while  $pi'(s) = cases(flip &"if" s = ⭗, stop &"otherwise") #v(2.2em)$ only has a risk of $0.5$.
]<ex:DoubleOrNothing>

In such cases, _probabilistic shielding_
#cl("DBLP:journals/cacm/KonighoferBJJP25")#cl("DBLP:conf/concur/0001KJSB20")#cl("DBLP:conf/ijcai/YangMRR23")#cl("DBLP:conf/atva/PrangerKPB21")
is a pragmatic alternative which increases the likelihood of staying safe.
Approaches to probabilistic shielding vary greatly by the types of guarantee they give.
The probabilistic guarantees are usually given over a finite horizon (Cf.~@sec:ShieldingHorizon) since the risk of failure over an infinite horizon often compounds to $1.0$.
Alternatively, the safety property can be formulated as _reach-avoid,_ stating that a goal-state has to be reached while avoiding a set of unsafe states.
Both are types of safety properties -- but they are not invariants. 
Instead, they can be specified using LTL #cl("DBLP:reference/mc/PitermanP18")#cl("DBLP:reference/mc/ClarkeHV18").
As noted previously, LTL safety properties can be expressed as safe sets (invariants) by modifying the model $mdp$.
This section continues to focus on safe sets $φ $.

#definition(name: "Probability of safety violation")[
  Let $mdp = (S, s_0, A, P, R)$ be an MDP, $phi$ a safe set, $pi$ a deterministic policy, and $s in S$ a state.
  The probability of leaving $phi$ starting from $s$ is written $PP_mdp^φ (pi, s)$. 
  It is the least fixed point in $[0, 1]$ for the equation

  $ PP_mdp^φ (pi, s) = cases(
      1 &"if" s modelsnot phi, 
      sum_(s' in S) P(s, pi(s))(s') PP_mdp^φ (pi, s') &"otherwise"
    )
  $

  For a state $s$, action $a$, and subsequent policy $pi$, the probability of leaving~$phi$ after taking action $a$ is $PP_mdp^φ (pi, s, a) =  sum_(s' in S) P(s, a)(s') PP_mdp^φ (pi, s')$.
]<def:ProbabilisticSafety>

For a safe set $phi$, the probabilistic guarantees can vary greatly.
Two such guarantees will be given here, dubbed respectively _$θ$-safe_ and _$θ$-recoverable_ shields.
These terms are not standard definitions but used here to distinguish two common types of guarantees that a probabilistic shield may give.
 
Firstly, given some safety threshold $theta$, a $θ$-shielded policy will leave $phi$ with probability at most $theta$.

#definition(name: [$theta$-safe shield])[
  For an MDP $mdp$ and safe set $phi$, a nondeterministic policy is a _$theta$-safe shield_ $shield_theta$ if for any policy~$pi$ that is permitted by $shield_theta$, it holds that $PP_mdp^φ (pi, s_0)  <= theta$.

  A policy or action is _permitted_ by $shield_θ$ analogously to @def:Shielding. For example a deterministic policy $pi$ is permitted by $shield_θ$ if $pi(s)=a => a in shield_theta (s)$.
]<def:ThetaSafe>

The next definition allows an action $a$ if it is possible to take $a$ while remaining within the safe set $phi$ with probability $1 - theta$.

#definition(name: [$theta$-recoverable shield])[
 For an MDP $mdp$ and safe set $phi$, a nondeterministic strategy is a _$theta$-recoverable  shield_ $tildeshield_theta$ if whenever $a in tildeshield_theta  (s)$, there exists a policy $pi'$ such that $PP_mdp^phi (pi', s, a) <= theta$.

 A policy or action is _permitted_ by $tildeshield_θ$ analogously to @def:ThetaSafe.
]<def:ThetaRecoverable>

The main distinction of recoverability is that it does not require the $θ$-safe policy to be followed. 
It *only* requires that a $θ$-safe policy exists -- starting with the current action -- and does not consider past risk when evaluating actions.
As such, recoverability merely bounds the risk of exiting $φ$ at _every_ step to $θ$.
This difference is illustrated in  @ex:ShieldingDoubleOrNothing.


#example(name: [Shielding "Double or Nothing"])[
  Consider the MDP $cal(D)$ from @ex:DoubleOrNothing with safe set $phi = {⦾, ○, ☺}$ and $theta=0.5$.

  A $theta$-safe shield $shield_0.5$ would permit $flip$ in the starting state, but not in the next state: $shield_0.5 (⦾) = {flip}, shield_0.5( ○) = {stop}$.
  Notice there exists only one policy $pi(s) = cases(flip "if" s = ⦾, stop) #v(2.2em)$ such that $pi models shield_0.5$ and that $pi models_0.5 phi$.

  Meanwhile, a $theta$-recoverable shield $tildeshield_0.5$ would permit $flip$ in both non-terminal states: 
  $tildeshield_0.5 (⦾) = {flip}, tildeshield_0.5( ○) = {flip, stop}$.

  This is because $flip$ in state $⦾$ has probability $0.5$ of reaching $○$, and from there $stop$ can reach $☺$ with probability~$1.0$.
  The $θ$-recoverable shield includes an additional policy:
  Besides $pi models tildeshield_0.5$ as above, the shield also permits $pi'(s) = flip$ which has probability $0.75$ of losing the bet.

  By expanding the MDP $cal(D)$ with more opportunities to flip the coin, the worst-case risk of failure for a $θ$-recoverable strategy could be arbitrarily close to $1.0$.
]<ex:ShieldingDoubleOrNothing>

#remark[
Any $θ$-safe action in $s_0$ is also $θ$-recoverable.
However, this is not true for all $s in S$, since a $θ$-safe shield may allow irrecoverable actions in states that are unreachable, or reachable with low probability.
]


Since $θ$-recoverable shields only bound the risk taken at each step, the probability of safety violation may compound to $1.0$ over an infinite horizon.
#footnote[The worst-case risk of a policy $pi$ permitted by $tildeshield_θ$ leaving $φ$ in $k$ steps is $1 - (1 - θ)^k$. This assumes that the initial state has at least one $θ$-safe action.]
This is illustrated in the following example.


#example(name: ["I can quit whenever I want"])[
  A smoker's lungs are modelled as the MDP $cal(L) = (S, s_0, A, R, P)$ with $S={lung, lungexplode}, s_0=lung, A={smoke, stop}$, and $P$ as shown in @fig:Smoker. State $lungexplode$ is terminal with $P(lungexplode, a)(lungexplode) = 1$ for $a in A$.
  Reward $R$ is left unspecified.

  #figure(image("../Graphics/Intro/Smoker.drawio.pdf", width: 80%),
    caption: [A simplified model of a smoker's lungs.]
  )<fig:Smoker>

  Let the safe set be $phi={lung}$ and threshold $θ=0.05$. The maximally permissive $0.05$-recoverable shield~$tildeshield_0.05$ permits both actions in the initial state, i.e. $tildeshield_0.05 (lung) = {smoke, stop}$.
  To see this, let the subsequent strategy be $pi_stop (s) = stop$ for $s in S$.
  Then, 

  $ PP^phi_cal(L) (pi_stop, lung, smoke) &= 
    &&P(lung, smoke)(lung) times PP^phi_cal(L) (pi_stop, lung) \
    &+ &&P(lung, smoke)(lungexplode) times PP^phi_cal(L) (pi_stop, lungexplode) \
    &= &&0.95 times 0 + 0.05 times 1 = 0.05 $
  
  Which satisfies @def:ThetaRecoverable.  
  The shield $tildeshield_0.5$ therefore permits the policy $pi_smoke (s) = smoke$, which will almost surely reach $lungexplode$, i.e.~$PP^phi_cal(L) (pi_smoke, lung) = 1$.
]<ex:Smoker>

Synthesis methods for $theta$-safe shields #cl("DBLP:conf/tacas/DragerFKPU14", "DBLP:conf/tacas/Junges0DTK16", "DBLP:conf/cav/HeckMACJ26") can be computationally expensive, and will be more conservative than approaches focusing on recoverability #cl("DBLP:conf/concur/0001KJSB20")#cl("DBLP:journals/corr/abs-2605-10293")#cl("DBLP:conf/atva/PrangerKPB21")#cl("DBLP:conf/tacas/Junges0DTK16").

=== Permissiveness of Probabilistic Shields

Recalling @def:Shielding, a shield $shield$ is maximally permissive for an MDP $mdp$ and property $phi$, if for every state $s in S$, and every other shield $shield'$ for the same $phi$ and $mdp$, $shield'(s) subset.eq shield(s)$.

As with absolute shields, an MDP $mdp$ has a unique maximally permissive $theta$-recoverable shield for every safety property $phi$. 
This shield is simply  the nondeterministic policy that, at every state $s$, includes every action $a$ which satisfies the condition in @def:ThetaRecoverable.

However, no $theta$-safe shield is maximally permissive #cl("DBLP:conf/tacas/Junges0DTK16") since allowing a risky action in one state may require restricting actions elsewhere to stay below the threshold $theta$. 
This dependency between actions at different states is complex to represent, and cannot be encoded as a nondeterministic policy.
An example and detailed proof of this point is given in #cl("DBLP:conf/cav/HeckMACJ26"). 
This paper also presents a formalism which is used to describe a wide range of probabilistic shield types with varying guarantees and representations.

=== Contingency Actions

For some states in a model, according to @def:Shielding shields must be constructed to completely avoid states where every action carries a risk of safety violation.
However, probabilistic shields have an inherent risk of reaching undesirable states, including ones where no actions are sufficiently safe to satisfy the safety threshold~$theta$.

Most systems cannot simply be halted when such an event occurs.
Instead the shield should make a best effort of steering the agent out of danger, regardless of the odds.
This can be as simple as only allowing the action with the highest probability of success, but can also include similarly safe actions.
A $θ$-recoverable shield is used in #cl("DBLP:journals/corr/abs-2605-10293"), i.e. it only allows actions that satisfy a constant threshold.
However, if no such action exists, the shield allows the safest action and all actions within a constant range of that action.
Alternatively, the probabilistic shield in #cl("DBLP:conf/concur/0001KJSB20") always allows the safest action, and other actions within some relative range.

== Research Hypothesis <sec:Hypothesis>

The previous sections have assumed finite environments, with a fully known safety-relevant abstraction.
Under these assumptions, there exist several shield synthesis methods to achieve policies optimized with RL that are verifiably safe.

#figure(image("../Graphics/Intro/CPS.drawio.pdf", width: 80%),
  caption: [A cyber-physical system with (discrete) digital hardware, (continuous) physical processes, and unknown components interacting -- shown as dotted lines.]
)<fig:cps>

However, cyber-physical systems -- pictured in @fig:cps -- are made up of several components interacting.
These components will be some combination of continuous dynamics, discrete state changes, and components with unknown behaviours.
Shielding has the potential to create safe and optimal policies for these systems, but that requires scalable shield synthesis methods for formalisms that can accurately model their behaviour.
This leads to the research hypothesis of this thesis, 

#hypothesis[

  Scalable shielding methods can be extended to formalisms that accurately model cyber-physical systems, to achieve safe and optimal performance.
]

The following sections will describe safety and shielding in such formalisms.
A~combination of continuous and discrete dynamics are modelled as a hybrid system, which is described in @sec:HybridShielding.
When an environment is unknown, its behaviour can be learned by (safely) interacting with it.
As more information about the system is revealed, the set of known safe behaviour changes, as described in @sec:AdaptiveShielding. 
As shown in @fig:cps, multiple digital components may interact in these cyber-physical systems, and these may sometimes be individual RL agents. Multi-agent systems pose unique challenges in terms of safety and optimality, which are discussed in @sec:MultiAgentShielding.
Lastly, @sec:Summary summarises the peer-reviewed papers that make up the remainder of this thesis, and which each contribute to addressing the hypothesis stated above.

== Hybrid MDPs <sec:HybridShielding>

So far, finite systems have been considered, building upon the finite MDP formalism given in @def:mdp. 
This discrete view fits well with the logic of electronic systems, being suited both for modelling their behaviour and for being simulated by them. 
However, the physical world is continuous, and can often be modelled accurately by differential equations.
To simulate cyber-physical systems, one needs to capture both the discrete states of the electronic components and the continuous behaviour of real-world objects.

Such hybrid systems contain both continuous dynamics, and discrete states that switch based on thresholds set for the continuous values.
There are also purely physical phenomena that hybrid systems are suitable for modelling.
A ball bouncing on the ground is one such example #cl("PaperA", "DBLP:conf/atva/JaegerJLLST19") which will be used in the following to illustrate the workings of a hybrid system.

#new[ \

#definition(name: "Euclidian MDP")[
  An _Euclidian MDP_ (EMDP) #cite(label("DBLP:conf/atva/JaegerJLLST19")) #cite(label("randomwalk")) is a tuple $emdp = (S, s_0, A, P, R)$ where 
  - $S subset RR^n$ is part of $n$-dimensional Euclidean space,
  - $s_0 in S$ is the initial state,
  - $A$ is a finite set of actions,
  - $P : S times A → (S → RR_(>= 0))$ with  $integral_(s' in S) P(s, a)(s') d s' = 1$ is the transition function, which gives the  probability density over states that can be reached from state $s$ as a result of  taking the action $a$, 
  - and $R : S times A times S -> RR$ gives the reward $R(s, a, s')$ for reaching $s'$ by taking $a$ in $s$.

]<def:emdp:I> // label exists in Paper A as well

Deterministic, probabilistic and nondeterministic policies for EMDPs are as in @def:policy.
With a policy, traces can be defined: 
#definition(name: "EMDP traces")[
  For an EMDP $emdp$, trace $xi = s_0 a_0 s_1 a_2 s_2 a_2 ...$ is an interleaved series of states and actions, starting in the initial state $s_0$.

  For a nondeterministic policy $pi : S -> (A -> [0; 1])$, a trace $xi$ is an outcome of the policy if $a_i in pi(s_i)$ and $P(s_i, a_i)(s_(i+1)) > 0$ for every $i>=0$. Outcomes are defined similarly for probabilistic and deterministic policies.
  Trace segments $xi_m^n = s_n a_n s_(n + 1) a_(n+1) ... s_m$ are as in @def:trace.
]

Safe sets $phi subset.eq S$, states $s in phi$, traces, and policies of an EMDP are as in @def:Safety.
By the definition of safe policies for EMDPs, the definition of shielding likewise extends naturally from @def:Shielding.
However, the expected reward are over probability densities provided by the euclidean transition function $P$.

#definition(name: "Expected reward of a policy on an EMDP")[
  For an EMDP $emdp$, discount factor $gamma$ and deterministic policy $pi$, the expected reward  in state $s in S$ is the unique fixed point of the equation

  $ EE_pi^emdp (s) = integral_(s' in S) P(s, pi(s))(s') (R(s, pi(s), s') + gamma EE_pi^emdp (s')) d s' $

  And similarly for probabilistic policies as in @def:expected-reward.
]

] // end new

Hybrid systems can be specified in the modelling tool #uppaal through the extension #uppaalsmc #cl("DBLP:journals/sttt/DavidLLMP15").
An informal description of key features will be given here.
Models are specified as systems of components interacting through #sync("synchronization") and shared #invariant("variables") or #invariant("clocks").
Components made up of #location("locations") which may have an #invariant("invariants"), and transitions between locations that contain #guard("guards"), #sync("synchronization channels") and #update("updates").

Transitions are shown as arrows between locations, and are controlled either stochastically by the environment (dashed) or chosen by the agent (solid). 
A transition is possible when the component is currently in the transition's outgoing location, and the predicate in the guard, e.g. #guard("p >= 4 && v >= 0"), is satisfied.
When a transition is taken, it moves the component from the outgoing to the incoming location, applying the specified update, e.g. #update("v = -4").

Invariants control the evolution of clocks over time, e.g. #invariant("x <= 0.1"), whenever the component is in the location which contains the invariant.
Time cannot progress if it would violate an active invariant, but taking a transition may allow the system to progress.
If no transition can be taken, a model deadlocks.
In addition to constraints, invariants may also specify generalized clock rates, e.g. #invariant("p' == v"), which allows modelling linear dynamics.

Synchronization between components happen through #sync("channels").
This may be initiated by transitions where the channel is suffixed by an exclamation point #sync("!"), i.e. #sync("hit!").
When a channel is initiated by a transition, all receiving channels suffixed with a question mark #sync("?") will fire at the same time, if their guards are enabled.
A~channel may be urgent, which prevents time from progressing whenever the guard on an initiating transition is satisfied.

#example(name: "Bouncing Ball")[
  A ball bounces on a flat surface, and can be struck by a piston whenever it is above a certain height #cl("PaperA", "PaperB", "PaperC", "JaegerJLLST19"), as shown in @fig:BBIllustration.
  The energy preserved is stochastic both when the ball bounces on the ground, and when hit.
  The ball experiences standard gravity $g = 9.81 skew("m"/"s"^2)$ and has a mass of $1$kg to simplify equations.
  
  #subpar.grid(columns: (0.4fr, 1fr), align: bottom,
    [#figure(image("../Graphics/Intro/BB Illustration.svg"), caption: [Illustration of the system @JaegerJLLST19.])<fig:BBIllustration>],
    [#figure(image("../Graphics/Intro/BB Ball.pdf"), caption: [#uppaal "Ball" template from @PaperD. \ #hide("a")])<fig:BBBall>],
    [#figure(image("../Graphics/Intro/BB Player.pdf"), caption: [#uppaal "Player" template from @PaperD. \ #hide("a")])<fig:BBPlayer>],
    [#figure(image("../Graphics/Intro/BB Random Trace.svg", height: 100pt), caption: [Example trace produced by random agent with 5% chance of choosing $hit$ when $p > 4$.] )<fig:BBRandomTrace>],
    caption: [Hitting bouncing ball.]
  )

  The behaviour of the system is shown as an #uppaal model in @fig:BBBall.
  The system has velocity $v$ (#skew($"m"/"s"$)) and position $p$ ($"m"$) measured as distance to the floor.
  In the #location("InAir") location, these  variables have the rate  #invariant("p' == v && v' == -9.81") which govern the trajectory of the ball while it is in the air.
  
  The urgent channel #sync("bounce!") forces the system to take an uncontrollable (dashed) edge whenever the ball touches the ground #guard("p <= 0 && v <= 0").
  For a sufficiently high speed, this causes the update $v ← -r v$ with $r ~ Unif([0.85; 0.97])$, where $Unif(X)$ represents the uniform distribution over some set $X$.
  If the speed of the ball is near zero #guard("v > -1e-5") as it touches the ground, the component may instead move to the location named #location("Stop").
  As its name implies, the velocity and position remain fixed at (near) zero in this location: #invariant("p' == 0 && v' == 0").

  A player component shown in @fig:BBPlayer is given the option to initiate the #sync("hit!") channel once every 0.1 seconds.
  A clock $x$ enforces a decision period of $0.1$, moving the player component into the location named #location("Choose").
  This location has two outgoing transitions that lead back to the #location("Wait") location, one of which initiates the #sync("hit!") synchronization and increments #update("c") variable.

  Two transitions on @fig:BBBall may synchronize on the channel #sync("hit"), subject to the guards on these transitions.
  These guards and transitions correspond to the following update rule with $r ~ Unif([0.9, 1])$:

  $ v ← cases(
    -4.0 &"if" p >= 4 and v < 0 and v >= -4, 
    -4 - r v &"if" p >= 4 and v > 0,
    v &"otherwise"
  ) $ 

  The behaviour of the system is shown in @fig:BBRandomTrace, which plots the position of the ball over time. 

]<ex:BB>

It is not possible to apply Q-learning as described in @alg:QLearning directly to continuous systems like @ex:BB.
It is not practical to represent a Q-table over uncountably infinite states, and most states will almost-surely never be visited twice.
However, you can discretize the Q-table @kaelbling1996reinforcement by grouping similar states according to some partitioning scheme.
A variant of discretized Q-learning with dynamic partitioning of the state-space is a feature of #uppaal @JaegerJLLST19, but for the next example a simple uniform partitioning scheme is used.

#example(name: "Q-learning on BB")[
  A Q-learning agent is set up to make a decision whenever the player is in the #location("Choose") location. 
  Thus, only variables $vec(v, p)$ will be tracked, resulting in the state space $S = RR^2$. The initial state is set to $s_0 = vec(0, 7)$ and the action set is called $A = {hit, nohit}$. 
  The reward $R$ is set up to give a penalty of $-1$ whenever the $hit$ action is chosen, and penalty $-50$ when the location #location("Stop") is entered.

  The Q-table was discretized with an axis-aligned uniform partitioning within the set $S' = [-15; 15[ #h(2pt) times [0; 10[ subset RR^2$.
  States in $S'$ are grouped into cells of size $0.2 times 0.2$ in the following manner: 
  ${ \[overline(v); underline(v)\[ #h(2pt) times \[underline(p); overline(p)\[ #h(2pt)  subset S' | underline(v) - overline(v) = overline(p) - underline(p) = 0.2 }$.
  For example, the state $vec(-4, 1)$ is contained in the cell $ [-4; -3.9[#h(2pt) times [1; 1.1[$.
  In total, the number of cells will be $|S'| = (15 - (-15))/0.2 times 10/0.2 = #{(15 - (-15))/0.2 * 10/0.2}$.
  Through experimentation, learning outcomes were found to be highly sensitive to the choice of cell size.
  Coarser cells required fewer training episodes to achieve a mean reward greater than $-50$, but the expected reward of the final policy would be lower.

  The Q-value of these states were initialized to zero: $Q(s', a) = 0$ for $s' in S'$ and $a in {hit, nohit}$.
  In remaining states, $s in.not S'$, the ball will never be hit: $Q(s, nohit) = 0$ and $Q(s, hit) = -infinity$.

  The results of raining are shown in @fig:BBUnshieldedTraining which plots  the reward obtained in each of  $50000$ episodes.
  Each episode was limited to a length of $1200$ actions, which corresponds to $120$ seconds.

  #subpar.grid(columns: 3, align: top,
    [#figure(image("../Graphics/Intro/BB Unshielded Training.png"), caption: [Training graph.])<fig:BBUnshieldedTraining>],
    [#figure(image("../Graphics/Intro/BB Unshielded Policy.svg"), caption: [Visualization of the resulting policy.])<fig:BBUnshieldedPolicy>],
    [#figure(image("../Graphics/Intro/BB Unshielded Trace.svg"), caption: [Safety violation \ during training.])<fig:BBUnshieldedTrace>],
    caption: [Unshielded training of the bouncing ball described in @ex:BB.]
  )

  Unsafe traces were encountered during simulated operation. The average reward during simulated operation was $-37.6$.

  A more advanced discretization scheme is available directly in the #uppaal tool, as part of the #uppaalstratego feature set #cl("DBLP:conf/atva/JaegerJLLST19").
  This reinforcement learning technique will dynamically partition the state-space to group states with similar Q-values as it learns.
  A policy was trained using the query `minE(c + Ball.Stop*50) [<=100] {} -> {v, p} : <> time>=100` which achieved an average reward of ?? during simulated operation.
  #todo[Run the numbers]
]<ex:BBUnshielded>

=== Shielding Hybrid Systems

The discretization method outlined in @ex:BBUnshielded may also be used to obtain a shield for hybrid systems, as shown in the following example.

#example(name: [Shielding the Bouncing Ball])[
  A shield is synthesized using the publicly available library @GridShielding.jl based on the formalism given in #paperref(<paper:A>).
  The abstraction used the same subset of the state space $S' subset S$, but with a smaller cell size of $0.02 times 0.02$.
  The package uses a sample-based method for approximating outcomes of actions from a given cell, and in this instance $3$ samples per axis were used.
  The resulting shield is visualized in @fig:BBShield.

  #subpar.grid(columns: 3,
    [#figure(image("../Graphics/Intro/BB Shield.svg"), caption: [Visualization of the shield with cell size 0.02])<fig:BBShield>],
    [#figure(image("../Graphics/Intro/BB Shielded Training.png"), caption: [Training graph when shield is applied.])<fig:BBShieldedTraining>],
    [#figure(image("../Graphics/Intro/BB Shielded Policy.svg"), caption: [Shielded policy.])<fig:BBShieldedPolicy>],
    caption: [Shielding the Bouncing Ball],
  )<fig:ShieldingBB>

  Training-only pre-shielding was used for Q-learning with parameters otherwise identical to @ex:BBUnshielded.
  Although the cell size of the Q-table does not match that of the shield, the safe-by-construction policy can be represented using the smallest cell-size.
  This is possible because the shield's cell size of $0.02$, is a divisor of the coarser Q-table which has size $0.1$.

  The training results under a pre-shield is shown in @fig:BBShieldedTraining. 
  During evaluation, the resulting policy achieved a a mean reward of $-37.8$.
  This policy is visualized in @fig:BBShieldedPolicy.

  Applying the pre-shield to the strategy from @ex:BBUnshielded for operation-only shielding yielded a similar reward, of $-38.5$.
]

== Adaptive Shielding <sec:AdaptiveShielding>

Safety guarantees in shielding are conditional on the model used being suitable abstractions of the true system, but accurate models are not straightforward to obtain in practice.
Let the MDP $mdp^star$ be the unknown, ideal, safety-relevant model of the underlying system.
Instead, an estimate $hat(mdp)$ can be created, with epistemic uncertainty about model behaviour captured as additional stochasticity, or as uncertainty-sets over the transition function #cl("DBLP:journals/sttt/BadingsSSJ23").
This approximation $hat(mdp)$ should ideally be a _conservative_ estimate, such that any shield for $hat(mdp)$ is also a (conservative) shield for $mdp^star$.

This section assumes that the estimate~$hat(mdp)$ and a safe set $phi$ will be used to synthesize a shield $shield$ by @def:Shielding.
However, any other form of shielding described in this thesis or in the literature could also be applied.

=== Initial Knowledge

From logs of the system's behaviour, trace segments $xi_0^n$ from $mdp^star$ can be obtained.
This information can be used by automated methods to obtain a model estimate~$hat(mdp)$.
Model estimation techniques include neural networks #cl("DBLP:conf/ecai/GoodallB23")#cl("DBLP:conf/ecai/BethellGCI25"), automata learning #cl("DBLP:conf/isola/TapplerPKMBL22"), interval MDPs #cl("DBLP:journals/corr/abs-2605-10293"), or model parameter estimation @senthilvelan_similarity-based_2023#cl("DBLP:journals/pacmpl/FengZPL25"). 

These automated methods presume some degree of initial knowledge about $mdp^star$, such as the action space, initial state, state space, or information about the structure of the transition function.
This initial knowledge can be provided by domain experts, or estimated using trace segments.
For example, model parameter estimation requires a _parameterized_ MDP, $hat(mdp)_p$ whose transition function depends on $k$ parameters given as the vector $p in RR^k$ such that $hat(mdp)_(p^star) = mdp^star$ for some $p^star in RR^k$.
Whether a shield for $hat(mdp)$ and  safe set $phi$, is also a shield for $mdp^star$ and $phi$, depends on the guarantees provided by the estimator.

=== Updating the Estimate

A shield $shield$ acquired from an estimate $hat(mdp)$ can then be applied (through any manner described in @sec:ApplyingTheShield) to an RL agent interacting with $mdp^star$. 
While the shield is in use, more traces are generated, and it is natural to use this additional experience to make $hat(mdp)$, and by extension the shield,  more precise.
Periodically updating the shield in this way can e.g. make a conservative estimate more permissive, while still ensuring that exploration is done safely  #cl("DBLP:conf/isola/TapplerPKMBL22").

Model estimation and shield synthesis is often computationally expensive.
Therefore, it is reasonable to update the shield every $u$ episodes of RL.
In keeping with the manner of @sec:QLearning, Q-learning is used here as an instructive example of RL:
It is extended in @alg:AdaptiveShielding to define an adaptive training-only pre-shielding RL loop.

The algorithm presumes initial knowledge encoded as a preliminary model estimate $hat(mdp)$, and records new traces using a transition database $D : S times A times S → NN$, which records how many times a transition $(s, a, s')$ is encountered during exploration.
An estimator function $E$ takes as arguments $hat(mdp)$ and $D$, and produces an updated model estimate.

In @sec:ApplyingTheShield, it was described how a pre-shield can be implemented by initializing the Q-table in such a way that unsafe actions will never be considered.
Note that the pre-shield in @alg:AdaptiveShielding instead restricts the actions under consideration as e.g. $max_(a in shield(s))$ rather than $max_(a in A)$.
This is to accommodate the adaptive shield, where actions permitted in a given state will change during execution.

#figure(kind: "algorithm", supplement: "Algorithm", 
  pseudocode-list(numbered-title: [Adaptive Shielding])[

    - *Input:* 
      Estimator~$E$, 
      initial knowledge~$hat(mdp)$,
      safe set~$phi$, 
      number of episodes $n$, and
      RL algorithm $L$
      
    - *Output:* Approximations of shield $hatshield$ and of optimal policy $hat(pi) : S -> A$.
    + *Initialize* observation database $D$
    + *Loop*  $i ← 0$ *up to* $n$
      + $hat(mdp) ← E(hat(mdp), D)$
      + $hatshield$ ← shield synthesized from $hat(mdp)$ and $φ$
      + *Perform* 1 episode of shielded RL with $L$ under $hatshield$, while collecting traces in $D$
    + *Return* $hatshield, hat(pi)$ learned from $L$
  ]
)<alg:AdaptiveShielding>

=== Safety Guarantees of Adaptive Shielding

By observing past traces, one may learn of new possible transitions, but never entirely eliminate the possibility that a transition $P(s, a)(s') > 0$ can occur.
The probability can become lower if it is never observed in data, but never reach zero. 

Thus, obtaining a shield which is safe according to @def:Shielding, requires that the initial estimate is already conservative.
If initially $hat(mdp)$ is not conservative, then a shield $hatshield$ for $hat(mdp)$ may not be safe for the underlying system.
If on the other hand $hat(mdp)$ is conservative from the beginning, then $hatshield$ will not adapt since the same transitions will always remain possible.
The same applies to absolute guarantees of $k$-step shields.

As such, probabilistic shielding is the natural choice in the adaptive setting.
Even so, the guarantees given by the adaptive probabilistic shield are contingent on and usually augmented by the guarantees given by the estimator.

=== Training and Operation <sec:AdaptiveTrainingAndOperation>

The training and operation phases described in @sec:TrainingAndOperation extends naturally to include adaptive shielding:
When the shield and policy are put into operation, they both become static.
In this way, adaptive shielding can be end-to-end or training-only, depending on whether the final shield is explicitly represented during operation.
If the shield must be static during operation, then the term _operation-only adaptive shielding_ is an oxymoron.

== Multi-agent Shielding <sec:MultiAgentShielding>

Many environments have multiple agents interacting.
These multi-agent settings present unique challenges.

#definition(name:[$n$-agent Markov Game])[
  A Markov Game (MG)~@zhang2021multi@busoniu_multi-agent_2010@marl-book with~$n$ agents is a tuple $mg = (S, s_0, N, A, P, R)$
  where
  - $S$ is a finite set of states,
  - $s_0 in S$ is the initial state,
  - $N = (1, 2, ..., n)$ represents the agents,
  - $A = A_1 times A_2 times ... times A_n$ is the joint action space,
  - $P : S times A -> (S -> [0; 1])$ gives the transition probability from one state to another by a joint action,
  - and $R : S times A times S -> RR^n$ is the reward function.

  $R$ induces individual reward functions $R_1, R_2, ..., R_n$ where each $R_i$ gives the $i^"th"$ value of the vector: If $R(s, a, s) = r$ then $R_i (s, a, s) = r_i$.
]<def:mg>

Note that $S$, $s_0$ and $P$ match those in @def:mdp, while the action space $A$ and reward function $R$ is changed to accommodate multiple agents.
The joint action $a$ is the combination of agents' individual choices $a = (a_1, a_2, ..., a_n)^top$.
When $a$ is taken in state $s$, the agent $i$ receives reward $R_i (s, a, s)$.

For an MG, there is one policy for each of the $n$ agents, $(pi_1, pi_2, ..., pi_n)$.
These are as in @def:policy, except that each policy $pi_i$ is over the agent's own action space $A_i$:

#definition(name:[Individual and joint policies])[
  In an MG $mg$, individual policies $pi_i$ represent one agent $i$ choosing from its own action space $A_i$.
  Deterministic, probabilistic and nondeterministic policies are respectively defined over $S -> A_i$,\
   $S -> (A_i  → [0; 1])$, and $S → powerset(A_i) \\ emptyset$ for each $i in N$.

   A full complement of individual policies $(pi_1, pi_2, ..., pi_n)$ induces a joint policy:
   - A _deterministic joint policy_ as $pi(s) = (pi_1 (s), pi_2 (s), ...,  pi_n (s))^top$,
   - a _probabilistic joint policy_ as $pi(s)(a) = product_(i in N) pi_i (s)(a)$, and
   - a _nondeterministic joint policy_ as $pi(s) = times.big_(i in N) pi_i (s)$
]<def:joint-policy>

Traces are defined from joint policies in the same manner as @def:trace.

The expected reward is not defined for an individual policy, since outcomes depend on the joint behaviour of all agents.
Reward is still recorded individually, in much the same way as @def:expected-reward.

#definition(name: [Expected individual reward])[
  Given an MG $mg$, a joint probabilistic policy $pi : S -> (A -> [0; 1])$ and a discount factor $gamma in #h(4pt) ]0; 1]$, the expected reward of agent $i in N$ starting in $s$ is the unique fixed point of the following equation

  $ EE_pi^(mg, i) (s) = sum_(a in A) pi(s)(a) sum_(s' in S) P(s, a)(s') (R_i (s, a, s') + gamma  EE_pi^(mg, i) (s')) $ 

  And similarly for deterministic policies.
]<def:individual-reward>


Recall that Q-learning assumes a static environment in order to prove convergence.
This assumption fails if multiple policies are being trained and interacting in the same environment.
Agents may change their policy to optimize reward based on the current joint policy, only for other agents to update their policies in turn.
This prompts further policy changes in a cycle that may continue _ad infinitum._

=== Reward Structure and Optimization Objectives
For an MDP, the goal is simply to maximise expected reward.
But since the rewards of an MG is individualized, the optimization objective can vary depending on how the game is structured.
An MG $mg$ can fall into one of three different categories which describe the reward structure @zhang2021multi@busoniu_multi-agent_2010@marl-book.
 - Cooperative, where the reward $R$ received by all agents is the same: $forall i, j in N : R_i (s, a) = R_j (s, a)$.
 - Competitive, in which the reward $R$ is zero-sum: $sum_(i = 0)^n R_i (s, a) = 0$.
 - Mixed, if the reward is neither competitive nor cooperative. 
 
For cooperative games, agents can work together to maximise their expected reward.
However with competitive games, the joint policy which gives the highest reward for agent $i$ is disadvantageous for at least one other agent.
Similarly for mixed reward structures, the set of policies which give the highest possible reward to agent $i$, is usually not the same as the set of policies that give the highest mean reward among all agents.
Rather than favouring a specific agent, optimization objectives are commonly formulated as a _Nash equilibrium_ or a _Pareto optimum._

Nash equilibria~@marl-book are concerned with changes to individual policies.
For a joint policy $pi$ induced by $(pi_1, pi_2, ...,  pi_n)$ and some individual policy $pi'_i$, let $(pi'_i, pi_(\-i))$ be the joint policy induced by $(pi_1, pi_2, ...,  pi_(i-1), pi'_i, pi_(i+1), ...,  pi_n)$.

#definition(name: [Nash equilibrium])[
  For an MG $mg$, a joint policy $pi$ is a Nash equilibrium @zhang2021multi if no agent $i$ can gain  a higher expected individual reward by changing its individual policy $pi_i$ to some other $pi'_i$. 
  That is to say, $pi$ is a Nash equilibrium if for every agent $i$ and every state $s$,

  $ EE^(mg, i)_(pi)(s) >= EE^(mg, i)_((pi'_i, pi_(\-i)))(s) " for any policy " pi'_i $
]

It may be that changing multiple policies can lead to higher reward, but no single agent can improve its policy.
Pareto optimality is a related, but stronger concept.

#definition(name: [Pareto optimal])[
   For an MG $mg = (S, s_0, N, A, P, R)$, the joint policy $pi$ is Pareto optimal~@marl-book if there is no other policy where every agent's reward is just as high or higher.

   Specifically, the policy $pi$ Pareto dominates $pi'$ if

   $ forall i in N, s in S : EE^(G, i)_pi (s) &>= EE^(G, i)_pi' (s) " and " \
   exists i in N, s in S : EE^(G, i)_pi (s) &> EE^(G, i)_pi' (s) $

   A policy $pi$ is Pareto optimal if it is not Pareto dominated by any other policy.

]

=== Multi-agent Safety and Shielding

Safety as given in @def:Safety (described by safe sets $phi subset.eq S$) can be extended directly to MGs for states, traces and joint policies.
An individual policy is safe, if it ensures the entire MG stays within the safe set, regardless of other agents' behaviour. 
Formally, given $mg$ and $φ$, an individual policy $pi_i$ is safe if -- for any non-deterministic joint policy $pi$ -- every outcome of $(pi_i, pi_(\-i))$ is safe.

Analogously to joint and individual policies, a shield is called either _global_ or _local._

#definition(name: "Global and local shields")[
  For an $n$-agent MG $mg = (S, s_0, N, A, P, R)$ and a safe set $phi subset.eq S$, a nondeterministic global policy is a global shield $shield : S → powerset(A) \\ emptyset$, if it is safe.

  A safe nondeterministic individual policy is called a local shield $shield_i : S -> powerset(A_i) \\ emptyset$.
]<def:GlobalAndLocalShields>

The concepts in @def:Shielding of maximally permissive shields, and permitted actions and policies (global and local) extend naturally from @def:GlobalAndLocalShields.

A safe set may be feasible (cf. @def:Feasibility) with a global shield, but not feasible for any of the agents with a local shield.
This is shown in @ex:2AgentGridWorld.

#example(name: "2-agent Grid World")[
  Recall the Grid World $cal(W) = (S, s_0, A, P, R)$ from @ex:GridWorld. 
  Let the two-agent version be $cal(W)^2 = (S^2, s'_0, N, A^2, P^2, R^2)$ with agents $🤖=1$, $👾=2$ so that $N = { 🤖, 👾 }$.
  Here, the state space $S^2$ is defined as $S times S$, the initial state $s_0 = (14, 2)$ and the action space likewise $A^2 = A times A $.
  The transition probability function $P^2 : S^2 times A^2 → (S^2 → [0, 1])$ extends movement to two agents in the natural way, while allowing both agents to occupy the same space.
  Similarly $R^2$ is defined by applying $R$ to the individual action and states of each agent (yielding a mixed reward structure).

  Notice how the state-space grows exponentially in the number of agents: From $|S| = 16$ to $|S^2| = 16 times 16 = 256$.



    #figure(
      {
        set text(size: 8pt)
        table(
          stroke: 0.4pt,
          columns: (auto, auto, auto, auto),
          align: left,
          inset: (bottom: 12pt),
          rows: 4,
          [ 1], [ 2 👾], [ 3], [ 4],
          [ 5], [ 6], [ 7], [ 8],
          [ 9], [ 10 🧊], [ 11 🧊], [12],
          [ 13 #hide([🧊])], [ 14 🤖], [ 15 💀], [ 16 🏁],
        )
      },
      caption: [Initial state of 2-agent Grid World with slippery tiles 🧊, an untimely end 💀, a goal state 🏁, and initial positions of agents 🤖 and 👾.]
    )<fig:2AgentGridWorld>

    Now consider the safe sets $#v(2.2em) phi_1 = { vec(s_1, s_2) | s_1 != 💀}$, $phi_2 = { vec(s_1, s_2) | s_2 != 💀}$, and $phi = phi_1 intersection phi_2$.
    Additionally, consider $psi = { vec(s_1, s_2) | s_1 != s_2 }$, which is the property that two agents cannot occupy the same space (including the goal).
    Clearly, all sets are feasible with global shields.

    The safe sets $phi_1$ and $phi_2$ are both feasible with local shields for the corresponding agent.
    But $phi$ is _not_ feasible with a local shield since neither agent has the ability to keep the other from entering 💀.

    Furthermore, $psi$ is feasible as a local shield $shield_👾$, since agent 👾 has enough space around it to avoid 🤖 indefinitely.
    However, no local shield $shield_🤖$ exists.
    To see this, note that states 💀 and 🏁 cannot be left once entered, so these should both be avoided. 
    Thus, the slippery states 11 and 12 must also be avoided as seen in @ex:GridWorld.
    Therefore, agent 🤖 has its initial movement constrained. In the worst case where agent 👾 chases the other, there is no safe strategy.

    Even if it is possible to enforce $psi$ through $shield_👾$, the shield has to assume worst-case behaviour from the other agent 🤖, which may be overly restrictive.
]<ex:2AgentGridWorld>

The assumption that all agents can act in concert following some centralized shield is often unrealistic.
Additionally, the synthesis of  a global shield is often not computationally feasible because of state-space explosion:
The size of the state-space increases with the number of agents, which in some parts of the literature can be in the hundreds or low thousands #cl("DBLP:conf/iclr/QinZCCF21")@marl-book.
A state-space of this size can strain many RL algorithms, and the behaviour and positions of other agents far away, may not have a substantial impact on individual reward.

This necessitates the use of local shields, but many important safe sets may not be feasible to enforce with purely local shields.
However, global shields may also be infeasible as previously noted.
Thus, the current literature on multi-agent shielding relies on additional assumptions, or variations on the MG.


=== Variations on Markov Games
It is common in multi-agent shielding to make additional assumptions about the model, to make multi-agent shielding feasible and sufficiently permissive.
Rather than observing the full state of the  system, it is more realistic to assume the MG is partially observable, which also reduces the size of the state-space (observation space).
Orthogonally, assuming that agents are able to communicate amongst themselves can make shields more permissive by reducing uncertainty. 
Besides explicit communication, agents may co-ordinate responsibilities before training starts, providing guarantees which can be relied on at runtime.

==== Partial Observability

The assumption of full observability is particularly strong in MGs, and may even be computationally infeasible for a large number of agents $n$.
The limits of on-board sensors makes this omniscience technically impractical as well, and thus it is a common #cl("DBLP:conf/iclr/QinZCCF21")#cl("DBLP:conf/atal/MelcerAT24")#cl("DBLP:journals/corr/abs-2509-12085") assumption that the game is _partially observable._

In general, the optimal policy for a partially observable game requires memory of all previous observations.
If the trace $zeta_1^n = o_1 a_1 o_2 a_2, ...,  o_n$ is an alternating sequence of observations and actions, a policy with memory would choose the next action as $pi(zeta_1^n) = a_n$, while a memoryless policy would as only rely on the last observation $pi(o_n) = a_n$.
The difference in performance between the optimal memoryless policy and the optimal policy with memory depends on the game $mg$.

Similarly, a shield in a partially observable system can use memory to maintain a "belief set" of states that are possible given current and previous observations~#cl("DBLP:conf/aaai/Carr0JT23").
A memoryless shield is instead limited to allowing only actions that are safe for any state that can yield the current observation.


==== Communication

Any global shield or joint policy assumes agents are able to communicate and agree on joint actions. 
Actions can also be broadcast when they are chosen @RajuBDT21 @busoniu_multi-agent_2010, i.e. agents choose their actions in a specific order, and each agent knows the choices of others if they are lower in the ordering.

By relying on guarantees that are established during shield synthesis, some shields may allow additional actions while ensuring the joint action is safe.

In a partially observable setting, sharing observations may also allow agents to achieve a more precise estimate of the underlying model state @10129007.

==== Co-ordination

Instead of assuming agents can communicate their intended actions during run-time, some methods use _off-line co-ordination_ #cl("DBLP:conf/atal/MelcerAT24")#cl("DBLP:conf/nips/MelcerAT22").

\
#new[
== Summary of Research Contributions <sec:Summary>

Based on the definitions of the previous sections, the research hypothesis from @sec:Hypothesis can be answered as a summary of contributions from the following papers.
Summaries are given below based on the abstracts of each paper, and research contributions are listed.

#infobox[
  ⚧ I changed my first name from Asger to Astrid between the publication of #paperref(<paper:D>) and #paperref(<paper:E>).
]

#grid(columns: 2, row-gutter: 1em, column-gutter: 1em,
  [#paperref(<paper:A>)], [  // This insane string is to make the brackets align regardless of kerning :3 
    Asger Horn Brorholt, Peter Gjøl Jensen, Kim Guldstrand Larsen, Florian~Lorber and Christian~Schilling
    "Shielded Reinforcement Learning for Hybrid Systems"
    _AISoLA,_ B.Steffen, Ed., in LNCS, vol. 14380. Springer, 2023,~pp.~33–54.
    @PaperA
  ],
  [#paperref(<paper:B>)], [
    Asger Horn Brorholt, Andreas Holck Høeg-Petersen, Kim Guldstrand Larsen and Christian~Schilling
    "Efficient Shield Synthesis via State-space Transformation" 
    _AISoLA,_ B. Steffen, Ed., in LNCS, vol. 15217. Springer, 2024, pp.~206–224. 
    @PaperB
  ],
  [#paperref(<paper:C>)], [
    Asger Horn Brorholt, Kim Guldstrand Larsen and Christian~Schilling
    "Compositional Shielding and Reinforcement Learning for Multi-agent Systems"
    _Proceedings of the 24th International Conference on Autonomous Agents and Multiagent Systems (AAMAS),_
     S. Das, A. Nowé, and Y. Vorobeychik, Eds.,  in ACM, 2025, pp.~399–407.
    @PaperC
  ],
  [#paperref(<paper:D>)], [
    Asger Horn Brorholt, Andreas Holck Høeg-Petersen, Peter Gjøl Jensen, Kim Guldstrand Larsen, Marius Mikučionis, Christian Schilling and Andrzej Wąsowski
    "#uppaalcoshy: Automatic Synthesis of Compact Shields for Hybrid Systems"
    _Reachability Problems - 19th International Conference (RP),_ P. Ganty and A. Mansutti, Eds., in LNCS, vol. 16230. Springer, 2025,~pp.~97–111.
    @PaperD
  ],
  [#paperref(<paper:E>)], [Astrid~Horn~Brorholt, Maris~F.~L.~Galesloot, Nils~Jansen, Kim~Guldstrand~Larsen and Christian~Schilling
    "Adaptive Probabilistic Shielding by Learning MDPs for Safe Reinforcement Learning"
    To appear in _Proceedings of the 26th International Conference on Runtime Verification (RV),_ October~6-9,2026.
    @PaperE
  ],
)


#figure(table(columns: 3,
  [*Paper*], [*Model*], [*Safety*],
  [A], [EMDP, @def:emdp:I], [Shield, @def:Shielding],
  [B], [EMDP, @def:emdp:I], [Shield, @def:Shielding],
  [C], [MG, @def:mg], [Multi-agent shield, @def:GlobalAndLocalShields],
  [D], [EMDP, @def:emdp:I], [Shield, @def:Shielding],
  [E], [(Unknown) MDP, @def:mdp], [$θ$-recoverable shield, @def:ThetaRecoverable]
  ),
  caption: [Formalism used in each paper.]
)

#[ #set heading(numbering: none, outlined: false)

=== #paperref(<paper:A>, with-title:true)

This paper builds upon a pervious Master's thesis @MastersThesis, providing a general framework which applies ideas that were developed in the thesis for specific case studies.
A code library based on this generalized model was released @GridShielding.jl for the programming language Julia.

Safe and optimal controller synthesis for switched-controlled hybrid systems, which combine differential equations and discrete changes of the system's state, is known to be intricately hard.
These systems have previously #cite(label("DBLP:conf/atva/JaegerJLLST19"))#cite(label("randomwalk"))  been described as EMDPs (@def:emdp), but this paper introduces a more precise definition.

#contribution[
  A formalism for describing hybrid systems, called the _hybrid Markov decision process._
]

Optimized policies can be trained using RL, but obtaining a shield for non-linear and hybrid environments is intractable.
The paper details the construction of a shield using the so-called _barbaric method_, where an approximate finite representation of an underlying partition-based two-player safety game is extracted via systematically picked samples of the true transition function.

#contribution[
  Formalization the approach investigated in @MastersThesis, providing a method of shielding to a hybrid setting using discretization.
]

#contribution[
  Generalization of a sample-based (_barbaric_) method of approximating reachability, to speed up shield synthesis.
]

While hard safety guarantees are out of reach, strong statistical safety guarantees are demonstrated experimentally with a prototype implementation and #uppaalstratego.
Furthermore, the impact of the synthesized shield is studied when applied as either training-only or operation-only.

#contribution[
  Comparison of training-only pre-shielding to operation-only post-shielding through five case studies, including two industrial examples.
]

Training-only shielding was found in all cases to yield better expected reward than operation-only shielding.

As described in @sec:ApplyingTheShield, #ref(<sec:postshielding>, form: "page"), post-shielding relies on a fallback policy $fehu$ to select an alternative safe action whenever the shield intervenes.
This paper investigated ways of obtaining $fehu$:

#contribution[
  Demonstrated post-optimization of operation-only shielding, by using RL to obtain a fallback policy.
]

Marginal improvement -- compared to a uniformly random choice of safe actions -- was found for either the expected reward (cost), or for the number of interventions, depending on the optimization criterion.

=== #paperref(<paper:B>, with-title:true)

This paper builds upon #paperref(<paper:A>), enhancing the scalability of the method by augmenting the axis-aligned partitioning scheme described in the previous paper. 

For many systems such a partitioning scheme does not align well with the safety property or the system dynamics. That is why a coarse partitioning is rarely sufficient, but a fine partitioning is typically computationally infeasible to obtain. 
This paper 

#contribution[
  State-space transformations can still allow to use a coarse partitioning, at almost no computational overhead.
]

In three case studies, transformation-based synthesis was faster than standard synthesis by several orders of magnitude. 

In the first two case studies, domain knowledge was used to select a suitable transformation. 
In the third case study, the dynamics did not point to any particular transformation that would be suitable.
Instead, a transformation was found by experimentation.

#contribution[
  Results in engineering a state-space transformation without domain knowledge.
]

The result is not presented as a general method, as it was not investigated if this could apply to other case studies.

=== #paperref(<paper:C>, with-title:true)

A method for multi-agent shielding is given for models where the interaction of agents have a set structure.
The shielding method uses offline coordination through an assume-guarantee framework.

Computing a shield scales exponentially in the number of state variables. 
As shown in @ex:2AgentGridWorld, this is a particular concern in multi-agent systems with many agents.
This paper introduces a novel approach for multi-agent shielding. 
Scalability is addressed by computing individual shields for each agent.
Typical safety specifications are global properties, but the shields of individual agents only ensure local properties. 
The key to overcome this challenge is to apply assume-guarantee reasoning. 
A sound proof rule is presented, that decomposes a (global, complex) safety specification into (local, simple) obligations for the shields of the individual agents.
This proof rule applies to systems where the interaction between agents is structures, such that each agent interacts with a limited number of other agents, as is illustrated in @fig:cps.

#contribution[
  The _compositional shielding_ method for synthesising local shields using offline-coordination through an assume-guarantee framework.
]

The effectiveness and scalability of this multi-agent shielding framework is demonstrated in two case studies, reducing the computation time from hours to seconds.

This same compositional structure was found to be useable for a novel approach to RL in multi-agent systems.
With the safety guarantees provided by compositional shielding,  a the structure of interactions

#contribution[
  The _cascading learning_ RL algorithm to approximate Pareto optimal policies by learning local policies in a fixed ordering.
]

The cascading learning under compositional shielding is compared to the state of the art (unshielded) multi-agent RL method MAPPO #cl("DBLP:conf/nips/YuVVGWBW22").
It is shown that this shielded RL approach significantly improves the safety and reward of the policies obtained for a given training budget.

=== #paperref(<paper:D>, with-title:true)


The modelling tool #uppaal is extended with the methodology presented in #paperref(<paper:A>). 

#contribution[
  The extension, #coshy, is a tool for automatic synthesis of shields for continuous state spaces and complex hybrid dynamics.
]

The implementation is fully automatic and supports the expressive formalism of #uppaal models, which encompass stochastic hybrid automata.
State-space transformations from #paperref(<paper:B>) are shown to be achievable using standard features of the #uppaal modelling language.

The precision of our partition-based approach benefits from using finer grids, which however are not efficient to store.
To integrate compact strategies into the workflow, #coshy is made compatible with a stand-alone application for reduction of strategy representations.

#contribution[
  The algorithm called  #smallcaps[caap] can efficiently compute a compact representation of a shield in the form of a decision tree.
]

The tool is applied to four case studies, and the integrated of #caap into the workflow shows significant reductions in represented size.


=== #paperref(<paper:E>, with-title:true)

Traditionally, the shield is computed from the transition probabilities of the underlying Markov decision process (MDP).
Thus, this technique is not applicable when the MDP model is not given a priori, which, unfortunately, is the case in typical RL applications. 

The paper studies the problem of computing a probabilistic shield in the setting where the transition graph of the MDP is known, but the transition probabilities are unknown. 
Maintaining a safe set through shielding (cf. @def:Shielding) is often not feasible, so the probabilistic $θ$-recoverable shielding approach from @def:ThetaRecoverable is chosen.

#contribution[
  Adaptive shielding with suitable estimators, based on an initial model estimate containing the transition structure but not probabilities.
]

This paradigm of #emph[adaptive probabilistic shielding] raises a number of challenges, such as when to recompute the shield and how to balance between exploration and safety during learning. 
These challenges are investigated through case studies.

#contribution[
  Multiple variants of this paradigm are empirically validated across five environments.
]

] // end set heading
] // end new

#[ #set heading(numbering: none) 
== References

#bibliography("../Bibliography.bib",
  title: none,
)
] // end set heading
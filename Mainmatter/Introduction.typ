#import "../Config/Macros.typ" : *
#import "@preview/cetz:0.4.2"
#import "@preview/subpar:0.2.2"
#import "@preview/lemmify:0.1.8": *
#import "@preview/lovelace:0.3.0": *

#import "@preview/alexandria:0.2.2": *
#show: alexandria(prefix: "I:", read: path => read(path))

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
Such cyber-physical systems @I:lee2006cyber @I:lee2008cyber are becoming more ubiquitous and more advanced.

With applications such as autonomous vehicles, water management systems, industrial hydraulics, and power controllers, great care must be taken to ensure the safety of people, equipment, and resources that are directly or indirectly affected by the system.

This can be achieved through the field of formal methods, which has a wide variety of approaches that can provide proof that a given system restricts itself ot a safe subset of behaviours. #citationneeded[handbook of model checking (?)]
This presumes an accurate model of the (cyber-physical) system under verification and techniques are most often subject to "state-space explosion," where the complexity of verification is highly sensitive to the size of the model.

Neural networks are notable for having achieved impressive performance in a wide variety of tasks #citationneeded[alphago, atari games, muzero, chatgpt].
This performance is achieved by controllers that use a high number of neurons, making direct formal verification infeasible.


== Reinforcement Learning

Reinforcement learning  #cl("I:DBLP:books/lib/SuttonB98") @I:kaelbling1996reinforcement @I:arulkumaran2017deep is a major class of machine learning techniques, separate from supervised and unsupervised learning @I:alloghani2020systematic.
In supervised learning, models learn from labelled data, to predict the labels of unseen data.
Unsupervised (or self-supervised) learning similarly trains the model on a set amount of unlabelled data, to discover relevant patterns and approximations.
In contrast, reinforcement learning _agents_ are actively interacting with a system, directing exploration and receiving observation data and rewards, as the system responds to actions taken by the agent.

The interaction between an agent and a system is illustrated in @fig:RL:
The agent observes its current state, and makes a decision on which action to take.
Taking the action yields a reward that the agent can use to update its policy, and an observation of the updated state which it will use to pick the next action.

#figure(include("../Graphics/Intro/Unshielded.typ"), caption: [The reinforcement learning loop.] )<fig:RL>

The reinforcement learning problem can be stated in many different ways, depending on the nature of the problem, but is perhaps most commonly defined in terms of a Markov decision process (MDP) #cl("I:DBLP:journals/siamrev/Feinberg96").
MDPs describe stochastic systems, where the outcomes of actions only depend on the current (observable) state of the system, and not on which actions or states were seen previously.

#definition(name: "MDP")[
An MDP can be described by a tuple $(S, s_0, Act, P, R)$ where
  - $S$ is a finite set of states,
  - $s_0 in S$ is an initial state,
  - $Act$ is a set of actions,
  - $P : S times Act times S -> [0; 1]$ with  $forall s in S, a in Act : sum_(s' in S) P(s, a, s') = 1$ is the transition function, which gives the  probability of reaching state $s'$ from state $s$ as a result of  taking the action $a$, 
  - and $R : S times Act times S -> RR$ gives the reward $R(s, a, s')$ for reaching $s'$ by taking $a$ in $s$.
]<def:mdp>

In this definition, the state-space is assumed to be finite, though it would be straightforward to generalize to a countably infinite state-space. 
If $S$ were instead to be uncountably infinite, the transition function $P$ should be modified to give a density function over a set of states, rather than giving probabilities for specific states. 
I.e. 
$P : S times Act -> (S -> RR_(>=0))$ such that $integral_(s' in S) P(s, a)(s') d s' = 1$.

The definition also requires every action $a in Act$ to be defined for every state in $S$. 
This assumption about the model is made w.l.o.g. to simplify notation.

A _policy,_  is a function that chooses the next action from a given state. 

Policies can either be 
 - _probabilistic_ $S times Act -> [0; 1]$, giving a probability distribution over actions, 
 - _deterministic_ $S -> Act$, uniquely selecting one specific action for each state, 
 - or _nondeterministic_ $S -> powerset(Act)$, giving a subset $A subset.eq Act$ of possible actions. 

Given an e.g. nondeterministic policy $pi : S -> powerset(Act)$, a trace $xi$ is an outcome of an MDP $mdp$ and policy $pi$ is an interleaved series of states and actions $xi = s_0 a_0 s_1 a_1 s_2 a_2 ...$ such that $a_i in pi(s_i)$ and $P(s_i, a_i, s_(i+1)) > 0$.
Traces are defined similarly for deterministic and probabilistic functions.
Since @def:mdp does not include a stopping condition, traces will be infinite.
A finite section of a trace $xi_m^n = s_m a_m ... a_(n-1) s_n$ contain the steps from state and action pairs from $s_m$ up to $s_n$.
Other types of model may produce finite traces, if they have a stopping criterion, e.g. a set of terminal states $T$, or a probability $1 - gamma$ that the system abruptly halts. 

For a finite trace, $xi_1^n = s_0 a_0 s_1 a_1 ... a_(n-1) s_n$ the (undiscounted) reward can be defined as $R(xi) = sum_(i=0)^(n - 1) R(s_i, a_i, s_(i+1))$.
This definition is less useful for infinite traces, as we will see in the following example:

#example[
  #grid(columns: 2, column-gutter: 3em,
    [
      #todo[Proper MDP to show the reader what it is.]
      #todo[Dotted outcomes, add rewards and percentages.]
      Consider an MDP with one state $s$ and two actions, $a$ and $b$.
    Let $R(s, a, s)=1$, $ R(s, b, s) = 100$, and $P(s, a, s) = P(s, b, s) = 1$. 
    This gives  $mdp= ({s}, s, {a, b}, P, R)$.],
    include("../Graphics/Intro/Simple MDP.typ"),
  )

  Let the policies $pi(s) = a$ and $pi'(s) = b$.
  Is the policy $pi'$ more useful than $pi$? We see that 
  $ R(xi) &= lim_(n -> infinity) sum_(i=0)^n 1 && = infinity  = 
   R(xi') &= lim_(n -> infinity) sum_(i=0)^n 100 $
]<ex:undiscounted>

To measure the relative usefulness of strategies over an infinite horizon, a  discount factor $gamma in ]0; 1]$ is applied to the reward, giving preference to more immediate gains.
This _discounted_ reward is defined as $R_gamma (xi) = sum_(i=0)^infinity gamma^i R(s_i)$. 
Note that in the special case where $gamma = 1$, $R_1$ is the same as the undiscounted reward $R$.
The discount factor $gamma$ may be interpreted as the probability of the trace continuing, while with probability $1 - gamma$ the trace may end in the next step, losing access to future rewards.

#example[
  With $mdp, pi$ and $pi'$ as in @ex:undiscounted, a discounted reward can be used to compare them.
  For example, $gamma = 0.99$ gives the geometric series
  $ R_0.99(xi) & = lim_(n -> infinity) sum_(i=0)^n 0.99^i 1 && = 1/(1-0.99) = 100  "and" \
  R_0.99(xi') & = lim_(n -> infinity) sum_(i=0)^n 0.99^i 100 && = 100/(1-0.99) = 10000 $
]<ex:discounted>

In contrast to the reward gained from just one trace, the expected discounted reward for a probabilistic policy is defined as:

#definition(name: "Expected reward")[
  Given an MDP $M = (S, s_0, Act, P, R)$, a probabilistic policy $pi$ and a discount factor $gamma in [0; 1[$, the expected reward of $pi$ on $mdp$ is the unique fixed point of the following equation

  $ EE_pi^mdp (s) = sum_(a in Act) pi(s, a) sum_(s' in S) P(s, a, s') (R(s') + gamma  EE_pi^mdp (s')) $ 
]<eq:ExpectedReward>

This is used in the definition of the optimization problem of finding the policy with the highest expected discounted reward for $mdp$.

#definition(name:"Optimization problem")[
  Given an MDP $mdp = (S, s_0, Act, P, R)$ and a discount factor $gamma$, find the policy $pi^star$ such that

  $ pi^star = argmax_(pi) EE_gamma^mdp (pi) $
]<def:Optimization>

It may be possible to compute $pi^star$ directly, through e.g. value- or policy iteration. #citationneeded[]
#strike[But these methods run into scalability issues on the size of the state-space $S$], and require full knowledge of the transition probabilities $P$ and rewards $R$.
#todo[It's not really scalability issues in the size of the state space. Rather, the issue is state-space explosion. Give more credit to these methods. Also, value iteration is another approximate method. It's linear programming that gives the true values.]
If the state-space is prohibitively large, or the MDP is not fully known but can be sampled from, the optimal policy may instead be approximated through learning. 

State of the art reinforcement learning techniques learn intricate behaviour through deep neural networks #citationneeded[] and decision trees #citationneeded[] such as PPO #citationneeded[] and MuZero #citationneeded[].
In the following, a description of the comparatively simple Q-learning approach will be given. The method serves to illustrate the core concepts of reinforcement learning, such as the difference between on-policy and off-policy learning, value estimation, and exploration strategies. 

=== Q-learning

#todo[Cite also Sutton and the 89 thesis. Write a sentence that mentions the citations explicitly.]
Q-learning @I:QLearning is a model-free, off-policy, reinforcement learning algorithm for models that have finite state-space.
The algorithm maintains a "Q-table"  that represents for every pair $(s, a)$ the estimated expected reward for taking action $a$ in state $s$.
It is the function $Q : S times Act -> RR$, which is updated in every step.

The table can be initialized arbitrarily,.#footnote[However if the model has terminal states $T subset S$, then $Q$ must be initialized such that $forall t in T, a in Act : Q (t, a) = 0$.] e.g. $Q (s, a) = 0.1$ for all $s in S, a in A$.
Although there is no theoretical requirement on the initialization of $Q$ it may be natural to use a random values, to use 0, or a small positive number.
If the initial value is greater in each state than the expected rewards, this will induce a breadth-first search as the Q-learning agent seeks out unexplored states, that appear to have higher rewards compared to known states.

The notational shorthand $Q (s, a) ← x$ is used to describe updates to the function where its value is changed to $x$ for $Q(s, a)$, while remaining unaltered for all other values in its domain.
The symbol $←$ is also  used for variable updates, e.g. $i ← 0$.

By gradual updates to $Q$, the function will approximate the expected value of taking action $a$ in state $s$, both in terms of immediate reward, and discounted future reward.
The method of approximation is given in @alg:QLearning, with the update rule in shown in @l:QUpdate.
Note the similarity of the update rule to @eq:ExpectedReward.
The algorithm has additional input parameters, which will be described in the following.

#figure(kind: "algorithm", supplement: "Algorithm", 
  pseudocode-list(numbered-title: [Q-learning])[
    - *Input:* MDP $mdp = (S, s_0, Act, P, R)$, 
      discount factor $gamma$,
      initial $Q : S times Act -> RR$,
      number of episodes $n$,
      episode length $m$,
      learning rate $alpha : NN -> [0; 1[$,
      and 
      exploration factor $epsilon : NN -> #h(0.3em)   ] 0; 1]$.
      
    - *Output:* Approximation $hat(pi)$ of optimal policy.
    + *Loop*  $i ← 0$ *up to* $n$
      + $s ← s_0$
      + *Loop* $m$                          #line-label(<l:EpisodeLoop>)
        + Flip a weighted coin that has probability $epsilon(i)$ of landing on heads.
        + *If* heads *then*  select $a$ according to a uniform distribution over $Act$
        + *Else* $a  ← argmax_(a' in Act) Q (s, a') $
        + $s' ~ P(s, a)$ #comment[Take action $a$ in state $s$, call the next state $s'$.]
        + #line-label(<l:QUpdate>) 
          $Q (s, a) ← Q (s, a) + alpha (i) (R(s, a, s') + gamma max_(a' in Act) Q (s', a') - Q (s, a))$
    + *Return* $hat(pi) (s) = argmax_(a in Act) Q (s, a)$
  ],
)<alg:QLearning>

The algorithm explores the model $mdp$ over a number of episodes $n$, which are finite traces that are cut off at length $m$.
This inner loop ensures, that $s_0$ will be visited at least $n$ times.
Setting $m$ too low may impact the estimate, since the policy will not be able to capitalize on future rewards beyond step $m$. 
Thus, $m$ should be picked according to $gamma$ such that $gamma^m$ is suitably low. 

Updates are performed according to a learning rate $alpha: NN -> [0; 1[$, a function over the learning steps.
This represents how much the new experience should influence the estimation of $Q(s,a)$.
As the number of episodes increases, so does the number of times $Q(s,a)$ is updated, and a decreasing learning rate reflects growing confidence in the estimate.

@alg:QLearning uses an $epsilon$-greedy exploration policy, to guarantee that every transition triple $(s, a, s')$  with $P(s, a, s') > 0)$  is seen infinitely often in an infinite number of episodes.
The guarantee holds since $epsilon : NN -> ]0;1]$ cannot go to 0. 
#todo[Write that Q-learning is off-policy because the Q-update does not factor in the $epsilon$ probability of taking another action.]
#todo[Name-drop other exploration policies.]

Q-learning is an early example of an algorithm which was proven @I:QLearning to almost surely converge as the number of episodes $n$ (and episode length $m$) goes to infinity.
The proof requires that the learning rate satisfies the assumption, $sum_i^infinity alpha(i) = infinity and sum_i^infinity alpha(i)^2 < infinity$.
The condition can be stated informally as "$alpha$ decreases towards zero, but not too fast."
The intuition behind the proof is, that the value update in @l:QUpdate requires that every transition triple $(s, a, s')$ occurs infinitely often.
This is ensured by the fact that $s_0$ is visited infinitely often as $n -> infinity$ and that there is always a non-zero chance (by $epsilon(i) > 0$) of eventually reaching state $s$ and taking action $a$ in $s$.

#example(name: "Grid World")[
  A robot 🤖 can move around along the cardinal directions on a $4 times 4$ grid, and must find an efficient path towards a goal 🏁 while avoiding a harmful tile 💀.  Movement is deterministic except for the ice tiles 🧊 where there is a chance of slipping in a different random direction. 
  The system is defined by the MDP $cal(G) = ({1, 2, ... 16}, 14, {←, ↑, →, ↓}, P, R)$. 
  The state-space is laid out in a $4 times 4$ grid as illustrated in @fig:GridWorld, with $s_0$ marked by 🤖.
  With the exception of states 10, 11, (🧊) 15 (💀) and 16(🏁), transitions deterministically follow the cardinal direction indicated by the action. If the action would cause the agent to leave the grid, it stays in the same state.
  
  For example, $P(1, →, 2)  = 1$ (0 for any other $(1, →, s)$), $P(2, ↓, 6) = 1$ and $P(5, ←, 5) = 1$.


  
  In states 10 and 11, there is a 0.625 probability of moving in the manner described above, while the remaining probability mass is distributed among the other directions, i.e. $P(11, →, 15) = 0.125$. States 15 and 16 are terminal, which is modelled as $P(15, a, 15) = 1$ and $P(16, a, 16) = 1$ for any $a$. 
  
    #figure(
      {
        set text(fill: alizarin)
        table(
          stroke: 0.4pt,
          columns: (auto, auto, auto, auto),
          align: left,
          rows: 4,
          [ 1], [ 2], [ 3], [ 4],
          [ 5], [ 6], [ 7], [ 8],
          [ 9], [ 10 🧊], [ 11 🧊], [12],
          [ 13 #hide([🧊])], [ 14 🤖], [ 15 💀], [ 16 🏁],
        )
      },
      caption: [A map showing the initial state of Grid World with 🧊 slippery tiles, 💀 an untimely end, 🏁 a goal state, and 🤖 agent.]
    )<fig:GridWorld>
  
  The reward is defined for any action $a$ as 
   - $R(15, a, 15) = 0$ and $R(16, a, 16) = 0$. (Terminate in 💀 and 🏁.)
   - $R(s, a, 15) = -50$ for $s != 15$. (💀)
   - $R(s, a, s') = -1$ otherwise.
  
  Consider a discount factor of  $gamma = 0.9$, episode length $m=100$, learning rate, and exploration factor $alpha(i) = epsilon(i) = cases(0.1 "if" i < n/2, 0.1/(1 + 0.01*(t - i/2)))$.

  Outcomes of Q-learning in Grid World $cal(G)$ with these parameters are shown in @fig:gridQ. The graph in @fig:QGraph100 shows the sum of rewards collected in each episode, up to $n=100$.
  The resulting policy is visualized in @fig:VTable100, which shows for every state $s$, the policy's action $a = argmax_a' Q(s, a')$, and the value $Q(s, a)$.
  Since the learning process is stochastic, the resulting policy will vary. 
  In this case, the policy traverses both states 10 and 11, taking a fast but risky route to the 🏁 goal. 
  Notice how the values have still not converged, and that the estimates are least accurate for the states furthest from the policy's route. 
  A better estimate is given in @fig:VTable10e6. For example the value of state 8 has converged to $Q(8, ↓) = R(8, ↓, 12) + gamma Q(12, ↓) = -1 + 0.99 times 10 = 8.9$. 
  This policy passes through state 10 but avoids state 11.

  #subpar.grid(columns: 3, 
    [#figure(image("../Graphics/Intro/Q-learning 500.png"),
      caption: [Cumulative reward up to 500 steps. \ #hide("empty")]
    )<fig:QGraph100>],
    [#figure(image("../Graphics/Intro/V-table 500.png"),
      caption: [Value $max_a Q(s, a)$ and best action \ after 500 steps.]
    )<fig:VTable100>],
    [#figure(image("../Graphics/Intro/V-table 1e6.png"),
      caption: [Value $max_a Q(s, a)$ and best action \ after 1 000 000 steps.]
    )<fig:VTable10e6>],
    label: <fig:gridQ>,
    caption: [Q-learning in the grid world.]
  )

  The final policy is not safe, in the sense that it has a non-zero chance of reaching the state 💀.
  This can be avoided by making changes to the reward function, giving a heavier penalty for reaching this state.
  However it is not straightforward to determine how the reward function should be structured in order to guarantee safety, or whether this is even possible for a given model.
]<ex:GridWorld>

#example(name: "Prism")[
  The same MDP can be modelled in the model-checking tool Prism @I:Prism, and the optimal strategy can be approximated precisely and quickly by its built-in value iteration method. #footnote[Prism does not support negative rewards, but since the model contains no positive rewards, the reward structure can be re-formulated as a minimization problem, `Rmin=? [F "goal"]`.]
   Prism does not support discounted reward, but since the optimal policy leads to a terminal state,  Q-learning with undiscounted reward ($gamma=1$) can be used as comparison.

  #subpar.grid(columns: 3, 
    [#figure(image("../Graphics/Intro/V-table γ=1 1e6.png"),
      caption: [Value $max_a Q(s, a)$ and best action after 1 000 000 steps, with $gamma=1$.]
    )<fig:VTableGamma1>],
    [#figure(image("../Graphics/Intro/V-table Prism.png"),
      caption: [Strategy and expected costs produced by Prism.]
    )<fig:VTablePrism>],
    label: <fig:GridPrism>,
    caption: [Grid World outcomes.]
  )
]

=== Training and Operation <sec:TrainingAndOperation>

It can sometimes be useful to view machine learning as consisting of two different phases: Initial _training,_ and subsequent _operation_ as part of a real-life system.
In the common view of reinforcement learning, the agent is continually exploring, learning, and improving, even when in operation.
However, this is not always the case in practice.
Legal requirements may warrant a costly re-certification every time changes are made to a policy, prohibiting the agent from adapting its behaviour during operation.
Technical limitations during operations may also preclude learning, such as reductions applied to the model, in order to deploy it to an embedded platform.

In Q-learning, the training phase would be exactly as @alg:QLearning, while the operation phase would not include @l:QUpdate of that algorithm.

#todo[Q-learning advanced example: Bouncing Ball.]

== Shielding <sec:Shielding>

Consider again an MDP $mdp = (S, s_0, Act, P, R)$. Besides optimizing for maximum reward, there may be other requirements for a policy $pi$ to be useful in practice. 

=== Safety

One such set of requirements are safety properties, stating that a state (or finite sequence of states) will never occur in the system.
#todo[Give examples that are based on _states_ and definitely not time. E.g. state 11 is visited at most 3 times.]
Examples could be statements like "orders are always processed within 10 minutes" or "all tests are taken before the sample is discarded," or in @ex:GridWorld: "The state 💀 is never reached."

Opposite to safety properties are liveness properties, which state that an event will eventually occur in the system, without a time bound. This could be e.g. "orders are eventually fulfilled" or "the state 🏁 is eventually reached."
The focus in this thesis is on safety:

Formally, a property is a safety property iff for every trace $xi = s_1 a_1 s_2 a_2 ...$ that violates the property, there exists an $i in NN$ such that the finite sub-trace $xi_1^i = s_1 a_1 ... a_(i-1) s_i$ is enough to show the property is violated #cl("I:DBLP:reference/mc/ClarkeHV18").
An important fragment of the safety properties is invariants, expressing that some proposition holds in every state.
The safety property for @ex:GridWorld, $forall s_i : s_i != 💀$, is an invariant.
These properties can be given as a set of states, $phi$, or as the LTL #cl("I:DBLP:reference/mc/ClarkeHV18") safety fragment "$#strong("G") psi$" where $psi$ is a predicate on $S$.

A safety property can be re-formulated as an invariant by modifying the MDP, so it includes a "monitor" that will move the model to a sink state if the property is violated. 
In the following, safety will be discussed in terms of invariants, given as a set of safe states.

#definition(name: "Safe states, traces and policies")[
  For an MDP $mdp$ and a safe set $phi subset.eq S$, a state $s in S$ is safe if $s in phi$. 
  Furthermore, a trace $xi$ is safe (with regards to $phi$) if for every $s_i$ in $xi$, $s_i in phi$.
  This extends to sections of traces $xi_n^m$ in the natural way.
  A policy $pi$ is safe wrt. $phi$ if every trace that is an outcome of $pi$ is safe.
 
 Safety with regards to $phi$ is indicated with $models$, as respectively $s models phi$, $xi models phi$ and $pi models phi$.
]

The optimization problem stated in @def:Optimization does not include a notion of safety, and it is not straightforward to define a reward function in such a way that the policy will converge to the desired safe behaviour.

=== Safety Through Shielding

Among the many approaches to enforcing safety in reinforcement learning, #citationneeded[Citations from Paper A and Alshiekh18], shielding @I:AlshiekhBEKNT18 @I:BloemKKW15 is a promising technique which restricts the actions available to the agent to ensure safe behaviour.
Since shields work by restricting actions, it can be applied to any existing reinforcement learning method, including deep learning, allowing it to work in concert with state of the art methods to achieve safe and optimized behaviour.

#definition(name: "Shield, maximally permissive shield, shielded policy")[
  For an MDP $mdp$ and safe set $phi$, a shield is a nondeterministic policy $shield : S -> powerset(Act)$ such that every trace $xi$ that is an outcome of $shield$ is safe.
  
  A shield $shield$ for a safe set $phi$, is maximally permissive if for all states $s in S$, there is no other shield $shield'$ for $phi$ such that $shield(s) subset shield'(s)$.

  A deterministic policy $pi$ is shielded by $shield$ if $forall s in S : pi(s) in shield(s)$. Similarly for a nondeterministic policy $pi$ if $forall s in S : pi(s) subset.eq shield(s)$. And for a probabilistic policy $pi(s, a) > 0 => a in shield(s)$.
]<def:Shielding>

The maximally permissive shield for an invariant of an MDP is unique @I:BernetJW02 @I:PaperB. 

=== Origin of the Term

In @I:DavidJLLLST14 it was shown how a safety property can be enforced through a maximally permissive, safe, non-deterministic strategy.
While acting within the constraints of this strategy, reinforcement learning was utilized to optimize for a second objective, achieving a near-optimal strategy within the safety constraints.

The term *shield* was coined in @I:BloemKKW15 to describe a component which would work in concert with a (mostly safe) policy, and intervene to prevent unsafe behaviour.
Thus, the behaviour of the shield and policy together is verifiably safe, as long as the shield is safe.
Contrary to runtime monitors #citationneeded[], which enforce a property by retroactively altering or halting a trace, the shield will intervene by altering the actions of the policy.
The authors proposed guarantees of minimal interference, and of $k$-stabilization, which states that the shield will at most intervene $k$ times before control is handed back to the policy.

This concept was extended to a framework of *shielded reinforcement learning* in @I:AlshiekhBEKNT18.
Here, a shield monitors and possibly corrects the actions of a learning agent, which enables safe exploration.
This enables the safe use of complex learning agents that can achieve cost optimal behaviour.
Approaches such as deep Q-learning or proximal policy optimization can be safely used in this framework, even though these methods cannot feasibly be verified directly.
The paper also points out that a shield can be synthesized from an *abstract model* of the system, one which only models behaviour relevant to the safety property being enforced.
Such an abstraction could be significantly simpler than the full system, allowing shielded reinforcement learning to scale to systems where other methods for safe and optimal control are infeasible.

Since this first article covering shielded reinforcement learning in finite MDPs, other shielding methods building upon the same framework have been described in the literature #citationneeded[Every shielded RL article I have on hand].

#example(name: "Safety in Grid World")[
  Recall the MDP $cal(G)=(S, s_0, Act, P, R)$ from @ex:GridWorld.
  Let the safe set be $phi=S \\ {💀}$. 
  What is the most permissive shield for $cal(G)$?
  Certainly, taking → in state 14 is prohibited.
  Next, any action in state 11 carries a risk of slipping and ending up in  💀, so state 11 should never be entered.
  Lastly, any action in state 10 can cause the agent to slip onto state 11, so this state should be avoided as well. 
  
  @fig:GridWorldShield shows the resulting maximally permissive safe strategy for @ex:GridWorld. 
  This strategy was generated using a publicly available package#footnote(link("https://github.com/AstridHornBrorholt/GridShielding.jl")) which implements the method described in Paper A (to be discussed in later sections).

  #figure(image("../Graphics/Intro/Shielded.png", width: 40%),
    caption: [Most permissive shield for Grid World. A shield icon 🛡️ indicates the action is not permitted.]
  )<fig:GridWorldShield>

]<ex:GridWorldSafety>



=== Shielding a Policy

How a policy is shielded can vary depending on the model and the application.
The terms pre-shielding and post-shielding have been used in the literature to describe a shield's relationship with the policy, but with two distinct sets of meaning:

 + In one part of the literature, pre- and post-shielding refer to *how* the shield ensures only safe actions reach environment #cl("I:DBLP:journals/corr/abs-1708-08611") #cl("I:DBLP:journals/cacm/KonighoferBJJP25") @I:MedicalShielding #cl("I:DBLP:conf/isola/TapplerPKMBL22") @I:bloem_its_2020.
 + Alternatively the terms can refer to *when* a shield is applied, in the process of obtaining a policy @I:jakobs_thesis @I:PaperA.

In the following, we shall use the terms pre- and post-shielding to mean the former, while we dub the latter meaning resp. end-to-end shielding and post-hoc shielding.

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
#subpar.grid(columns: 2,
  [#figure(include("../Graphics/Intro/End-to-end Shielding.typ"),
  caption: [End-to-end shielding]
  )<fig:EndToEnd>],
  [#figure(include("../Graphics/Intro/Post-hoc Shielding.typ"),
    caption:[Post-hoc shielding]
  )<fig:PostHoc>],
  caption: [*When* the shied is applied in the process of obtaining a policy.],
  label: <when_shielding>
)

#todo[Describe the need (or lack thereof) of keeping the shield after learning.]

==== Pre-shielding
Illustrated in @fig:PreShielding, this term refers to the shield restricting the behaviour of the the policy by providing a set of actions $A subset.eq Act$, that are permitted for the given state.
The learning must be set up in such a way as to only pick an action $a$ if it is included in the set $A$.

For Q-learning this would require modifying @alg:QLearning to maximize only over safe actions $max_(a in shield(s))$, rather than all of $Act$.  For example, in @l:QUpdate:
$ Q (s, a) = Q (s, a) + alpha (i) (R(s, a, s') + gamma max_(a' in shield(s')) Q (s', a') - Q (s, a)) $
A similar approach works for gradient methods @I:arulkumaran2017deep #cl("I:DBLP:journals/corr/abs-2006-14171").


==== Post-shielding
Contrary to pre-shielding, this configuration is transparent to the reinforcement learning algorithm.
As shown in @fig:PostShielding, the algorithm's actions are sent to the shield, which passes it on to the environment.

This is akin to modifying the the MDP $mdp = (S, s_0, Act, P, R)$ with a new transition function.
In addition to a shield $shield$, post-shielding requires a probabilistic fallback policy $fehu$, with $fehu(s, a) > 0 <=> a in shield(s)$. The shielded transition function used in place of $P$ in $mdp$, is $P'(s, a, s') = cases(P(s, a, s') "if" a in shield(s), P(s, fehu(s), s'))$.

The fallback policy $fehu$ has to remain static during learning, to preserve convergence guarantees. It could simply give a uniform distribution over safe actions, pick actions deterministically from an ordering, or according to a model-specific heuristic. It could also be a trained policy, as discussed in @post-shielding-optimization of Paper A.

#remark(name: "Value Updates in Post-shielding")[
  The value updates for post-shielding are done in the natural way, but there is a risk of making subtle mistakes.
  Some care must be taken when updating e.g. the Q-values for a post-shielded MDP with an altered transition function $P'$.
  Say that in state $s$,  the shield alters an unsafe action $a in.not shield(s)$ to the safe alternative $fehu(s) = a'$, reaching state $s'$.
  The update should be performed for $a$ and not $a'$, i.e. updating $Q(s, a)$ with reward $R(s, a, s')$ as in @alg:QLearning, @l:QUpdate.

  It would be unsound to only update $Q(s, a')$.
  However it was shown in  #cl("I:DBLP:conf/ijcnn/SeurinPP20"), that the number of interventions of a shield was reduced by updating $Q(s, a')$ with a penalty of e.g. $-50$ (set as a hyper-parameter).
]


Both pre- and post-shielding preserve the assumptions necessary to guarantee convergence to an optimal policy for e.g. Q-learning. 
Pre-shielding will likely converge faster than post-shielding in general. If a model has a state $s$, with one safe action $a_1$ and unsafe actions $a_2, a_3$, a post-shielded agent will have to explore actions $a_1, a_2$ and $a_3$ in order to learn the expected reward attainable in $s$. However, a post-shielded agent will only have to learn the expected reward of $a_1$, since the other actions are masked.
Thus, it will likely gain a more precise estimate of the expected value of $s$ from the same amount of visits to the state.


==== End-to-end Shielding
When the shield is in place during _both_ the learning  _and_ operational phases, this is called end-to-end shielding (@fig:PostHoc).
This is a necessity if the agent is interacting with a real-life system where safety violations should also be avoided during training.

In contexts other than reinforcement learning, end-to-end shielding describes the process of integrating the shield in the design process of the controller,  omitting unsafe actions from consideration.

Compared to the unshielded counterpart, end-to-end shielding was seen in @I:AlshiekhBEKNT18 to lead to a better policy when trained on the same number of traces. 
The authors speculate that the shield acts as a teacher guiding the agent away from undesirable behaviours.
Shielding leading to better policies has also been observed in other works @I:carr_compositional_2025 #cl("I:DBLP:conf/aaai/Carr0JT23") #cl("I:DBLP:conf/ijcai/YangMRR23") @I:PaperA, though there are examples where this is not the case @I:bloem_its_2020 @I:court_probabilistic_2025.
This is because the shield may prevent the agent from exploiting risky but rewarding behaviour.

==== Post-hoc Shielding
Alternatively, the shield can be applied only in the operational phase, allowing the agent to explore unsafe actions during learning.
This can lead to slower convergence, since the agent spends time exploring unsafe states and (ideally) learning to avoid them.
If the agent learns to avoid unsafe states perfectly, a maximally permissive shield would never interfere with its operation.
Otherwise, the shield will interfere with the policy, disrupting its optimized behaviour.

Outside the context of RL, the term describes applying the shield as a guardrail of a controller that has been designed to be mostly safe, but without using the shield as reference.
Thus, an existing controller can be upgraded to give formal safety guarantees by applying a post-hoc shield in cases where altering the controller itself would be costly.

#remark(name: "Terminology in Paper A")[
  Note that some terms used in Paper A @I:PaperA differ from the definitions in this section.
  What the paper calls _post-shielding,_ this section defines as _post-hoc shielding._ 
  Conversely, what it calls _pre-shielding_ is called _end-to-end shielding_  in this section.
]

=== Finite- and Infinite-horizon Shielding

Note that @def:Shielding requires safety over all infinite traces that are outcomes of the shield.
This generally requires computing a safety strategy offline, which can be computationally infeasible for some models. 
Instead, it can make sense to only give guarantees $k$ steps into the future, computed on-line at each step.
These finite horizon shields are often referred to as _bounded prescience_  shields @I:giacobbe_shielding_2021, or $k$-step lookahead shields @I:xiao_model-based_2023 @I:yang_safe_2023.

One example of such a safety guarantee @I:giacobbe_shielding_2021  was given for a deterministic MDP, but here extended to include probabilistic outcomes: 
For an MDP $mdp$, action $a_0$  is $k$-safe at state $s_0$, if there exists a deterministic strategy $pi$ such that for all traces $xi = s_0 a_0 ... s_k...$ with $pi(s_i) = a_i$ for $i > 0$, then $xi_0^k$ is safe.
This extends to other states $s$ by redefining the starting state of $mdp$ to $s$.

=== Probabilistic Shielding

#todo[Write this section]


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

#[
  #set heading(numbering: none) 
  == References

  #bibliographyx("../Bibliography.bib",
    prefix: "I:",
    title: none,
  )
]
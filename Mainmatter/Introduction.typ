#import "../Config/Macros.typ" : *
#import "@preview/cetz:0.4.2"
#import "@preview/subpar:0.2.2"
#import "@preview/lemmify:0.1.8": *
#import "@preview/lovelace:0.3.0": *

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

This can be achieved through the field of formal methods, which has a wide variety of approaches that can provide proof that a given system restricts itself ot a safe subset of behaviours #cl("HandbookOfModelChecking")@lewis2012optimal@doyle2013feedback.
This presumes an accurate model of the (cyber-physical) system under verification and techniques are most often subject to "state-space explosion," where the complexity of verification is highly sensitive to the size of the model.

When the state-space reaches a size that is prohibitive for these methods, _reinforcement learning_ (RL) #cl("DBLP:books/lib/SuttonB98") @kaelbling1996reinforcement @arulkumaran2017deep has proven useful at approximating the optimal policy through exploration even in complex systems.
Neural networks #cl("DBLP:journals/nature/LeCunBH15") are especially notable for having achieved impressive performance in a wide variety of tasks #cl("DBLP:journals/nature/SchrittwieserAH20").
This performance is achieved by controllers that use a high number of neurons, making direct formal verification infeasible.

#new[

*Shielding* @AlshiekhBEKNT18 @BloemKKW15 is a promising technique that restricts the behaviour of an RL policy in a way that formally guarantees a safety specification.
A _shield,_ tasked with enforcing this safety specification, acts as a guardrail to keep the RL policy within safe bounds.
Often, obtaining a shield which is safe by construction can be feasible, even when directly obtaining a policy that is both safe and (near-) optimal is not.
This shield can then be combined with an efficient policy, such as one obtained by RL, to achieve both safety and efficiency.
Therefore, shielding has been widely studied in the literature 
#cl("DBLP:conf/concur/0001KJSB20")@9196867@BastaniL21@PaperA@PaperC@PaperB#cl("DBLP:journals/corr/ZhangB19")#cl("DBLP:conf/amcc/BharadwajBDKT19")#cl("DBLP:conf/atal/Elsayed-AlyBAET21")#cl("DBLP:conf/atal/XiaoLD23")#cl("DBLP:conf/aaai/Carr0JT23")#cl("DBLP:conf/atva/PrangerKPB21")@PaperD@MedicalShielding#cl("DBLP:conf/isola/TapplerPKMBL22")@giacobbe_shielding_2021@xiao_model-based_2023@yang_safe_2023@bloem_its_2020@carr_compositional_2025 
but the ability of a shield to enforce safety depends on which assumptions can be made about the system, and there is no truly scalable "silver bullet" to ensure safety in all cases.

Therefore, this thesis will continue the work of developing scalable shielding methods that enforce safety under systems and assumptions that are realistic for real-world cyber-physical systems.
This thesis addresses shielding  hybrid systems, multi-agent settings and unknown environments, and describes efforts to enhance scalability, and accessibility through the development of user-friendly tools.

The remainder of this introduction will describe the basics of first RL, then the basics of shielding.
Beyond the fundamental definitions, alternative systems and shielding approaches are described, followed by a summary of each paper that make up the remainder of this thesis.
]

== Reinforcement Learning <sec:rl>

RL  #cl("DBLP:books/lib/SuttonB98") @kaelbling1996reinforcement @arulkumaran2017deep is a major class of machine learning techniques, separate from supervised and unsupervised learning @alloghani2020systematic.
In supervised learning, models learn from labelled data, to predict the labels of unseen data.
Unsupervised (or self-supervised) learning similarly trains the model on a set amount of unlabelled data, to discover relevant patterns and approximations.
In contrast, reinforcement learning _agents_ are actively interacting with a system, directing exploration and receiving observation data and rewards, as the system responds to actions taken by the agent.

The interaction between an agent and a system is illustrated in @fig:RL:
The agent observes its current state, and makes a decision on which action to take.
Taking the action yields a reward that the agent can use to update its policy, and an observation of the updated state which it will use to pick the next action.

#figure(include("../Graphics/Intro/Unshielded.typ"), caption: [The reinforcement learning loop.] )<fig:RL>

The reinforcement learning problem can be stated in many different ways, depending on the nature of the problem, but is perhaps most commonly defined in terms of a Markov decision process (MDP) #cl("DBLP:journals/siamrev/Feinberg96").
MDPs describe stochastic systems, where the outcomes of actions only depend on the current (observable) state of the system, and not on which actions or states were seen previously.

#definition(name: "MDP")[
An MDP can be described by a tuple $(S, s_0, A, P, R)$ where
  - $S$ is a finite set of states,
  - $s_0 in S$ is an initial state,
  - $A$ is a set of actions,
  - $P : S times A → (S → [0; 1])$ with  $forall s in S, a in A : sum_(s' in S) P(s, a)(s') = 1$ is the transition function, which gives the  probability of reaching state $s'$ from state $s$ as a result of  taking the action $a$, 
  - and $R : S times A times S -> RR$ gives the reward $R(s, a, s')$ for reaching $s'$ by taking $a$ in $s$.
]<def:mdp>

In this definition, the state-space is assumed to be finite, though it would be straightforward to generalize to a countably infinite state-space. 
If $S$ were instead to be uncountably infinite, the transition function $P$ should be modified to give a density function over a set of states, rather than giving probabilities for specific states. 
I.e. 
$P : S times A -> (S -> RR_(>=0))$ such that $integral_(s' in S) P(s, a)(s') d s' = 1$.

The definition also requires every action $a in A$ to be defined for every state in $S$. 
This assumption is made w.l.o.g. to simplify notation.

Sometimes models are defined as having a cost $C$ to be minimized, rather than reward $R$ to be maximised. These definitions are effectively interchangeable, as any cost can be re-defined as reward by flipping its sign: $R(s, a, s') = -C(s, a, s')$.

#definition(name: "Policy")[
  A policy  is a function that chooses the next action from a given state. 
  There are three different kinds of policy:
    - _deterministic_ $S -> A$, uniquely selecting one specific action for each state, 
    - _probabilistic_ $S -> (A -> [0; 1])$, giving a probability distribution over actions, 
    - or _nondeterministic_ $S -> powerset(A)$, giving a subset $A' subset.eq A$ of possible actions. 

]<def:policy>

#definition(name: "Traces, trace segments")[
  Given an e.g. nondeterministic policy $pi : S -> powerset(A)$, a trace $xi$ is an outcome of an MDP $mdp$ and policy $pi$.
  It is an interleaved series of states and actions $xi = s_0 a_0 s_1 a_1 s_2 a_2 ...$ such that $a_i in pi(s_i)$ and $P(s_i, a_i)(s_(i+1)) > 0$.
  Traces are defined similarly for deterministic and probabilistic functions.
  Since @def:mdp does not include a stopping condition, traces will be infinite.
  A finite section of a trace $xi_m^n = s_m a_m s_(m + 1) a_(m + 1) ... a_(n-1) s_n$ contain the steps from state and action pairs from $s_m$ up to $s_n$.
  Other types of model may produce finite traces, if they have a stopping criterion, e.g. a set of terminal states $T$, or a probability $1 - gamma$ that the system abruptly halts. 
]<def:trace>

For a finite trace, $xi_1^n = s_0 a_0 s_1 a_1 ... a_(n-1) s_n$ the (undiscounted) reward can be defined as $R(xi) = sum_(i=0)^(n - 1) R(s_i, a_i, s_(i+1))$.
This definition is less useful for infinite traces, as we will see in the following example:

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

To measure the relative usefulness of strategies over an infinite horizon, a  discount factor $gamma in ]0; 1]$ is applied to the reward, giving preference to more immediate gains.
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
  Given an MDP $M = (S, s_0, A, P, R)$, a probabilistic policy $pi : S -> (A -> [0; 1])$ and a discount factor $gamma in [0; 1[$, the expected reward of $pi$ on $mdp$ is the unique fixed point of the following equation

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
However, MDPs are often described using several variables or components. Known as the _curse of dimensionality,_ the size of the state-space is exponential in the number of these components or variables.  

If the state-space is prohibitively large, or the MDP is not fully known but can be sampled from, the optimal policy may instead be approximated through learning. 

State of the art reinforcement learning techniques learn intricate behaviour through deep neural networks such as PPO~#cl("DBLP:journals/corr/SchulmanWDRK17"), and decision trees such as random forests~#cl("DBLP:journals/ml/Breiman01"), or a combination of the two like MuZero~#cl("DBLP:journals/nature/SchrittwieserAH20").
In the following, a description of the comparatively simple Q-learning approach will be given. The method serves to illustrate the core concepts of reinforcement learning, such as the difference between on-policy and off-policy learning, value estimation, and exploration strategies. 

=== Q-learning

Q-learning @QLearning @Watkins89 #cl("DBLP:books/lib/SuttonB98") is a model-free, off-policy, reinforcement learning algorithm for models that have finite state-space.
The algorithm maintains a "Q-table"  that represents for every pair $(s, a)$ the estimated expected reward for taking action $a$ in state $s$.
It is the function $Q : S times A -> RR$, which is updated in every step.

The table can be initialized arbitrarily,
#footnote[However if the model has terminal states $T subset S$, then $Q$ must be initialized such that $forall t in T, a in A : Q (t, a) = 0$.]
e.g. $Q (s, a) = 0.1$ for all $s in S, a in A$.
Although there is no theoretical requirement on the initialization of $Q$ it may be natural to use random values, zeroes, a heuristic, or a relatively high ("optimistic") value to encourage exploration.
If the initial value is greater in each state than the expected rewards, this will induce a breadth-first search as the Q-learning agent seeks out unexplored states, that appear to have higher rewards compared to known states.

The notational shorthand $Q [(s, a) mapsto x]$ is used to describe updates to the function where its value is changed to $x$ for $Q(s, a)$, while remaining unaltered for all other values in its domain. I.e. $Q [(s, a) mapsto x](s', a') = cases(x " if " (s', a') = (s, a), Q(s', a'))$.

By gradual updates to $Q$, the function will approximate the expected value of taking action $a$ in state $s$, both in terms of immediate reward, and discounted future reward.
The method of approximation is given in @alg:QLearning, with the update rule in shown in @l:QUpdate.
Note the similarity of the update rule to @def:expected-reward.
The algorithm has additional input parameters, which will be described in the following.

#figure(kind: "algorithm", supplement: "Algorithm", 
  pseudocode-list(numbered-title: [Q-learning])[
    - *Input:* MDP $mdp = (S, s_0, A, P, R)$, 
      discount factor $gamma$,
      initial $Q : S times A -> RR$,
      number of episodes $n$,
      episode length $m$,
      learning rate $alpha : NN -> [0; 1[$,
      and 
      exploration factor $epsilon : NN -> #h(0.3em)   ] 0; 1]$.
      
    - *Output:* Approximation $hat(pi) : S -> A$ of the optimal deterministic policy.
    + *Loop*  $i ← 0$ *up to* $n$
      + $s ← s_0$
      + *Loop* $m$                          #line-label(<l:EpisodeLoop>)
        + Flip a weighted coin that has probability $epsilon(i)$ of landing on heads.
        + *If* heads *then*  select $a$ according to a uniform distribution over $A$ #line-label(<l:Explore>) 
        + *Else* $a  ← argmax_(a' in A) Q (s, a') $   #line-label(<l:Exploit>) 
        + $s' ~ P(s, a)$ #comment[Take action $a$ in state $s$, call the next state $s'$.]
        + #line-label(<l:QUpdate>) 
          $Q[(s, a) mapsto Q (s, a) + alpha (i) (R(s, a, s') + gamma max_(a' in A) Q (s', a') - Q (s, a)) ]$
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

@alg:QLearning uses an $epsilon$-greedy exploration strategy, to guarantee that every transition triple $(s, a, s')$  with $P(s, a)(s') > 0)$  is seen infinitely often in an infinite number of episodes.
The guarantee holds since $epsilon : NN -> ]0;1]$ cannot go to 0. 

#new[
The $epsilon$-greedy exploration strategy is conceptually simple, and therefore used in many textbooks and standard implementations.
Other exploration strategies exist that makes better use of existing knowledge to find out which actions are worth exploring.
These include upper confidence bound #cl("DBLP:books/lib/SuttonB98"), Boltzmann exploration @kaelbling1996reinforcement,  Thompson sampling @thompson1933likelihood@daniel2018tutorial or by adding a noise term to the loss function of deep learning RL @williams1991function@foster_entropy.
The use of Q-values that are relatively high compared to the actual expected reward is another way to encourage exploration  #cl("DBLP:books/lib/SuttonB98").
]

#new[
Notice how the Q-update in @l:QUpdate uses the current reward, and the Q-value of the best action in the next state.
As such, it estimates the expected reward obtained by greedily selecting the most rewarding action each step, as is the case for the policy~$hat(pi)$ returned in @l:Return.
It does _not_ take into account the chance  $epsilon(i)$ of picking a random action during learning.
This makes Q-learning an _off-policy_ algorithm, since it explores the environment with one policy ($epsilon$-greedy) but estimates the expected return of a different policy (entirely greedy).
The similar reinforcement learning method _SARSA_  @rummery1994line#cl("DBLP:books/lib/SuttonB98") is _on-policy_ because it uses Q-values of actions actually taken, rather than the ones estimated to be most rewarding.
]

Q-learning is an early example of an algorithm which was proven @QLearning to almost surely converge as the number of episodes $n$ (and episode length $m$) goes to infinity.
The proof requires that the environment remains static, i.e. $mdp$ does not change during learning.
It also requires the learning rate to satisfy the assumption, $sum_i^infinity alpha(i) = infinity and sum_i^infinity alpha(i)^2 < infinity$.
This condition can be stated informally as "$alpha$ decreases towards zero, but not too fast."
The intuition behind the proof is that the value update in @l:QUpdate requires that every transition triple $(s, a, s')$ occurs infinitely often.
This is ensured by the fact that $s_0$ is visited infinitely often as $n -> infinity$ and that there is always a non-zero chance (by $epsilon(i) > 0$) of eventually reaching state $s$ and taking action $a$ in $s$.

#example(name: "Grid World")[
  A robot 🤖 can move around along the cardinal directions on a $4 times 4$ grid, and must find an efficient path towards a goal 🏁 while avoiding a harmful tile 💀.  Movement is deterministic except for the ice tiles 🧊 where there is a chance of slipping in a different random direction. 
  The system is defined by the MDP $cal(W) = (S, s_0, A, P, R)$, with $S={1, 2, ... 16}$, $s_0=14$ and $A={⬅, ⬆, ➡, ⬇}$. $P$ and $R$ are described below:

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
        set text(fill: alizarin, size: 8pt)
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
  
  Consider a discount factor of  $gamma = 0.9$, episode length $m=100$, initial $Q(s) = 0$ for all $s in S$, and learning rate $alpha$ and exploration factor $epsilon$:

  $ alpha(i) = epsilon(i) = cases(0.1 "if" i < n/2, 0.1/(1 + 0.01*(t - i/2))) $

  Outcomes of Q-learning in Grid World $cal(W)$ with these parameters are shown in @fig:gridQ. The graph in @fig:QGraph shows the sum of rewards collected in each episode, up to $n=500$.
  The resulting policy is visualized in @fig:VTable, which shows for every state $s$, the policy's action $a = argmax_a' Q(s, a')$, and the value $Q(s, a)$.
  Since the learning process is stochastic, the resulting policy will vary. 
  In this case, the policy visits state 10 but not 11, taking a fast but somewhat risky route to the 🏁 goal. 

  Notice how the values have still not converged, and that the estimates are least accurate for the states furthest from the policy's route. 
  For example the value of state 8 has converged to $Q(8, ⬇) = R(8, ⬇, 12) + gamma Q(12, ⬇) = -1 + 0.99 times 10 = 8.9$. 
  However, the action suggested in state 1 is not helpful, and the estimated reward for following it is not low enough.

  #subpar.grid(columns: 3, align: top,
    [#figure(image("../Graphics/Intro/Q-learning 500.png"),
      caption: [Cumulative reward.]
    )<fig:QGraph>],
    [#figure(image("../Graphics/Intro/V-table 500.png"),
      caption: [Value $max_a Q(s, a)$ and best action \ after 500 episodes.]
    )<fig:VTable>],
    [#figure(image("../Graphics/Intro/V-table Prism.png"),
      caption: [Expected reward computed by Prism.]
    )<fig:VTablePrism>],
    label: <fig:gridQ>,
    caption: [Q-learning in the grid world.]
  )

  The same MDP can be modelled in the model-checking tool Prism @Prism, and the optimal policy can be approximated precisely and quickly by its built-in value iteration method.
  #footnote[A discounted reward was simulated using a variable `t` that increments each step, multiplying the reward with `gamma^t`. The query used was `Rmin=?[C<=100]`.]
  The resulting state values are shown in @fig:VTablePrism.

  The final policy is not safe, in the sense that it has a non-zero chance of reaching the state 💀.
  This can be avoided by making changes to the reward function, giving a heavier penalty for reaching this state.
  However it is not straightforward to determine how the reward function should be defined in order to guarantee convergence to a safe policy, or whether this is even possible for a given model.
]<ex:GridWorld>

=== Training and Operation Phases <sec:TrainingAndOperation>

It can sometimes be useful to view machine learning as consisting of two different phases: Initial training, and subsequent operation as part of a real-life system.
The *training phase* is defined as the period where the agent changes its policy to gradually improve expected reward, possibly in a controlled environment. 
This is in contrast to the *operation phase* where the policy is no longer mutable, always taking the best action according to the policy at the time when training ended.

In the common view of reinforcement learning, the agent is continually exploring, learning, and improving, even when in operation #cl("DBLP:books/lib/SuttonB98")@kaelbling1996reinforcement.
Importantly, this lets the policy respond to changes in the environment (which are not uncommon despite the theoretical assumption that the system is static).
However, continually training the agent is not always possible in practice.
Legal requirements may warrant a costly re-certification every time changes are made to a policy, prohibiting the agent from adapting its behaviour during operation.
Technical limitations during operations may also preclude learning, such as in embedded platforms. Reductions may have even been applied to the model, in order to stay within memory limits.
Such a reduction could be the transformation from a Q-table to a list of state-action pairs, discarding the exact Q-values and keeping only the optimal action for each state.

#todo[Q-learning advanced example: Bouncing Ball.]

== Shielding <sec:Shielding>

Complex physical systems may have multiple requirements placed upon them, which cannot always be combined into a single reward signal.
These requirements may be in tension with each other, and it could be that some concerns should always come first, such as the safety of people or equipment. 

=== Safety

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
These properties can be given as a set of states, $phi$, or as the LTL #cl("DBLP:reference/mc/ClarkeHV18") safety fragment "$#strong("AG") psi$" where $psi$ is a predicate on $S$.

A safety property can be re-formulated as an invariant by modifying the MDP, so it includes a "monitor" that will move the model to a specific state if the property is violated. 
In the following, safety will be discussed in terms of invariants, given as a set of safe states.

#definition(name: "Safe states, traces and policies")[
  For an MDP $mdp$ and a safe set $phi subset.eq S$, a state $s in S$ is safe if $s in phi$. 
  Given a safe set $phi$, a trace $xi$ is safe if for every $s_i$ in $xi$, $s_i in phi$.
  This extends to sections of traces $xi_n^m$ in the natural way.
  A policy $pi$ is safe with regard to $phi$ if every trace that is an outcome of $pi$ is safe.
 Safety according to $phi$ is indicated with $models$, as respectively $s models phi$, $xi models phi$ and $pi models phi$.
]<def:Safety>

The optimization problem stated in @def:Optimization does not include a notion of safety, and as noted in @ex:GridWorld, a policy might not converge to safe behaviour.
Even then, the convergence guarantee for Q-learning relies on an infinite number of traces, meaning that models trained in practice may not have learned fully safe behaviour even if the reward function is correctly designed to encourage it.

=== Safety Through Shielding

Among the many approaches to enforcing safety in reinforcement learning,  #cl("DBLP:conf/iros/WenET15") #cl("DBLP:conf/tacas/Junges0DTK16") #cl("DBLP:journals/jmlr/GarciaF15") #citationneeded[Citations from Paper A and Alshiekh18], shielding @AlshiekhBEKNT18 @BloemKKW15 is a promising technique which restricts the actions available to the agent, in order to ensure safe behaviour.
Since shields work by restricting actions, they can be applied to any existing reinforcement learning method, including deep learning, allowing it to work in concert with state of the art methods to achieve safe and optimized behaviour.

#definition(name: "Shield, maximally permissive shield, shielded policy")[
  For an MDP $mdp$ and safe set $phi$, a _shield_ is a safe nondeterministic policy $shield : S -> powerset(A)$.
  
  A shield $shield$ for a safe set $phi$, is maximally permissive if for all states $s in S$, there is no other shield $shield'$ for $phi$ such that $shield(s) subset shield'(s)$.

  A deterministic policy $pi$ is shielded by $shield$ if $forall s in S : pi(s) in shield(s)$.
  Similarly for a nondeterministic policy $pi$ if $forall s in S : pi(s) subset.eq shield(s)$.
  And for a probabilistic policy $pi(s, a) > 0 => a in shield(s)$.
  The application of a shield in a reinforcement learning setting is discussed in @sec:ApplyingTheShield.
]<def:Shielding>

The maximally permissive shield $shield$ for a safe set $phi$ of an MDP $mdp$ is unique @BernetJW02 @PaperB.

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
  Let $gamma = 0.9$. The expected reward for this policy as given by @def:expected-reward is:

  #let expectation = $EE^cal(I)_pi$
  $ expectation(○) = &P(○, p)(○)(R(○, p, ○) + gamma expectation(○)) \
    + &P(○, p)(◍)(R(○, p, ◍) + gamma expectation(◍)) \
    = &0.95(100 + 0.9 expectation(○)) + 0.05(100 + 0.9 expectation(◍)) \
  $
  Since $expectation(◍) = 1 + 0.9 expectation(○)$, the equation reduces to  \
  $expectation(○) = (100 + 0.05 times 0.9)/(1 - 0.95 times 0.9 - 0.05 times 0.9^2) approx 957.368$.
] <ex:QualityInjectionMoulding>

Some safe sets are not possible to enforce. For example, consider a Grid World $cal(W)' = (S, s_0, A, P, R)$ as described in @ex:GridWorld, except with $s_0 = 10$.
From this initial state, there is a nonzero probability of reaching 💀 regardless of which actions are taken.
The safe set $S \\ {💀}$ is said to be infeasible for $cal(W)'$.


#definition(name: "Feasibility")[
  A safe set $phi$ is said to be feasible for an MDP $mdp$ if there exists at least one shield $shield$ for $phi$ and $mdp$.
]<def:Feasibility>

However, some policies may be safe with higher probability than others. For a discussion of probabilistic safety and shielding, see @sec:ProbabilisticShielding.

=== Origin of the Term

In @DavidJLLLST14 it was shown how a safety property can be enforced through a maximally permissive, safe, non-deterministic policy.
While acting within the constraints of this policy, reinforcement learning was utilized to optimize for a second objective, achieving near-optimal behaviour within the safety constraints.

The term *shield* was coined in @BloemKKW15 to describe a component which would work in concert with a (mostly safe) policy, and intervene to prevent unsafe behaviour.
Thus, the behaviour of the shield and policy together is verifiably safe, as long as the shield is safe.
Contrary to runtime monitors #cl("DBLP:journals/csr/KhouryT12")#cl("DBLP:journals/tse/DelgadoGR04"), which enforce a property by retroactively altering or halting a trace, the shield will intervene by altering the actions of the policy.
The authors proposed guarantees of minimal interference, and of $k$-stabilization, which states that the shield will at most intervene $k$ times before control is handed back to the policy.

This concept was extended to a framework of *shielded reinforcement learning* in @AlshiekhBEKNT18.
Here, a shield monitors and possibly corrects the actions of a learning agent, which enables safe exploration.
This enables the safe use of complex learning agents that can achieve cost optimal behaviour.
Approaches such as deep Q-learning or proximal policy optimization can be safely used in this framework, even though these methods cannot feasibly be verified directly.
The paper also points out that a shield can be synthesized from an *abstract model* of the system, one which only models behaviour relevant to the safety property being enforced.
Such an abstraction could be significantly simpler than the full system, allowing shielded reinforcement learning to scale to systems where other methods for safe and optimal control are infeasible.

Since this first article covering shielded reinforcement learning in finite MDPs, other shielding methods building upon the same framework have been described in the literature #cl("DBLP:conf/concur/0001KJSB20")@9196867@BastaniL21@PaperA@PaperC@PaperB#cl("DBLP:journals/corr/ZhangB19")#cl("DBLP:conf/amcc/BharadwajBDKT19")#cl("DBLP:conf/atal/Elsayed-AlyBAET21")#cl("DBLP:conf/atal/XiaoLD23")#cl("DBLP:conf/aaai/Carr0JT23")#cl("DBLP:conf/atva/PrangerKPB21")@PaperD@MedicalShielding#cl("DBLP:conf/isola/TapplerPKMBL22")@giacobbe_shielding_2021@xiao_model-based_2023@yang_safe_2023@bloem_its_2020@carr_compositional_2025.

=== Shielding a Policy: Pre- and Post-shielding <sec:ApplyingTheShield>

Specific implementation details of how a shield is applied to a reinforcement learning agent can vary.
The terms _pre-shielding_ and _post-shielding_ (sometimes referred to as _post-posed shielding_) have been used to describe the relationship between the agent and the shield, but the terms have been used in the literature to describe two distinct concepts:

+ In one part of the literature, pre- and post-shielding refer to *how* the shield ensures only safe actions reach the environment #cl("DBLP:journals/corr/abs-1708-08611") #cl("DBLP:journals/cacm/KonighoferBJJP25") @MedicalShielding #cl("DBLP:conf/isola/TapplerPKMBL22") @bloem_its_2020.
+ Alternatively the terms can refer to *when* a shield is applied, i.e. whether the shield is in place during the training- and/or operation phases (see @sec:TrainingAndOperation) @jakobs_thesis @PaperA.

This section will coin an additional set of terms, to disambiguate these meanings.
The terms pre- and post-shielding will be taken to mean the first and more widely used definition, i.e. *how* the shield is integrated into the reinforcement learning loop.
The second set of terms, to describe *when* the shield is in place, will be dubbed _training-only, operation-only,_ and  _end-to-end shielding._
A brief description of the terms is given here, with definitions following in the sections below.

In short, pre-shielding (@fig:PreShielding) provides a set of safe actions to the agent, which it then chooses from.
With post-shielding,  (@fig:PostShielding) the agent may choose any action, but if the shield deems that action unsafe, it will exchange the unsafe action with a different, safe action.

The aforementioned terms describing *how* the shield is applied, can be combined with any of the terms for *when* it is in place:
End-to-end shielding, (@fig:EndToEnd) has a shield in place during both training and operation. 
With training-only shielding, the shield is in place during the training phase, and the resulting policy is safe by construction (@fig:TrainingOnly).
For operation-only shielding, (@fig:OperationOnly) a policy was trained without access to a shield, but one is later constructed as an additional safeguard while the policy is in operation.

When and how the shield is employed are orthogonal properties, and the terms can be freely combined.
For example, a training-only shielding setup can use either a pre- or post-shield.

#remark[
  The terminology introduced in this section does not align with Paper A.
  This section distinguishes two sets of concepts which are described by the paper as linked, as shown in @tab:NamingDiscrepancy.
  The paper uses _post-shielding_ to mean operation-only post-shielding.
  Conversely, the paper uses _pre-shielding_ to mean end-to-end pre-shielding.

  #figure(table(columns: 2, align: center,
      table.header( [*Term used in Paper A*], [*Corresponding terms in this section*] ),
      [Pre-shielding], [End-to-end Pre-shielding ],
      table.hline(),
      [Post-shielding], [Operation-only Post-shielding]
    ),
    caption: [This section uses different terms compared to Paper A.]
  )<tab:NamingDiscrepancy>
]

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
  [#figure(include("../Graphics/Intro/End-to-end Shielding.typ"),
  caption: [End-to-end shielding.]
  )<fig:EndToEnd>],
  [#figure(include("../Graphics/Intro/Training Only.typ"),
  caption: [Training only.]
  )<fig:TrainingOnly>],
  [#figure(include("../Graphics/Intro/Operation Only.typ"),
    caption:[Operation only.]
  )<fig:OperationOnly>],
  caption: [*When* the shied is applied in the process of obtaining a policy.],
  label: <when_shielding>
)

==== Pre-shielding
Illustrated in @fig:PreShielding, this term refers to the shield $shield$ restricting the behaviour of the the policy by providing a set of actions $shield(s) subset.eq A$, that are permitted for the given state $s$.
The learning must be set up in such a way as to only pick an action $a$ if it is included in the set $shield(s)$.

For Q-learning, this can be implemented by modifying @alg:QLearning to maximize only over safe actions $max_(a in shield(s))$, rather than all of $A$.  For example, in @l:QUpdate:

$ Q (s, a) = Q (s, a) + alpha (i) (R(s, a, s') + gamma max_(a' in shield(s')) Q (s', a') - Q (s, a)) $

A similar approach works for gradient methods @arulkumaran2017deep #cl("DBLP:journals/corr/abs-2006-14171").

Alternatively, unsafe actions can be excluded from consideration as follows: 
For some default value $q_0$ and bottom element $-infinity$, the Q-values can be initialized as $Q(s, a) = cases(-infinity " if " a in.not shield(s), q_0)$.
If $epsilon$-greedy exploration is used, the exploratory actions should picked from just $shield(s)$ and not the full action space $A$.

Directly applying the shield to the Q-table is possible because the learning method works on a finite number of states.
A similar approach is not possible for e.g. decision trees, or continuous methods such as Deep Q-learning, PPO, etc. where states in the system are not explicitly represented. 

==== Post-shielding
Contrary to pre-shielding, this configuration is transparent to the reinforcement learning algorithm.
As shown in @fig:PostShielding, the algorithm can choose any action $a in A$, which would normally be enacted upon the environment, but is instead intercepted by the shield.
If the action is safe, the shield passes it on to the environment unaltered.
Otherwise an alternative, safe, action is chosen.

This is akin to modifying the the MDP $mdp = (S, s_0, A, P, R)$ with a new transition function $P^shield_(#h(1.5pt) fehu)$ and reward function $R^shield_fehu$.
In addition to a shield $shield$, post-shielding requires a (deterministic) fallback policy 
#footnote[The symbol $fehu$ is the runic letter _fehu._]
$fehu : S → A$,
with $fehu(s) = a => a in shield(s)$. The shield $shield$ and fallback policy $fehu$ induce functions $P^shield_(#h(1.5pt) fehu)$ and $R^shield_fehu$ for a post-shielded MDP $mdp^shield_fehu = (S, s_0, A, P^shield_(#h(1.5pt) fehu), R^shield_fehu)$.
The transition function will choose the fallback action, if the suggested action is unsafe

$ P^shield_(#h(1.5pt) fehu)(s, a)(s') = cases(
  P(s, a)(s') & " if " a in shield(s), 
  P(s, fehu(s))(s') &
) $<eq:PostShieldedTransitionFunction>

And the reward function is updated to reflect this

$ R^shield_fehu (s, a, s') = cases(
  R(s, a, s') & " if " a in shield(s),
  R(s, fehu(s), s')& 
) $<eq:PostShieldedReward>

The fallback policy $fehu$ could pick actions from an ordering, choose according to a model-specific heuristic, or always select a universally safe action, if one exists.
By re-defining $fehu$ to be probabilistic, the fallback policy could pick among safe actions according to a uniform distribution.
It could also be obtained using machine learning, as discussed in @post-shielding-optimization of Paper A.

Note that the fallback policy must be static during the training phase, (when applicable) in order to preserve convergence guarantees.
Otherwise $P^shield_(#h(1.5pt) fehu)$ will change during training, violating the assumption that $mdp$ is static.

#remark(name: "Value Updates in Post-shielding")[
  The value updates for post-shielding are performed in the natural way, but subtle mistakes in the implementation can void the convergence guarantees.
  Consider Q-learning performed on a post-shielded MDP $mdp^shield_fehu = (S, s_0, A, P', R^shield_fehu)$.
  Say that in state $s$,  the shield alters an unsafe action $a in.not shield(s)$ to the safe alternative $a' = fehu(s)$, reaching state $s'$.
  Then, the value update should be performed for $a$ and not $a'$.
  I.e. $Q(s, a)$ is updated with reward $R^shield_fehu (s, a, s')$
  #footnote[Equivalent to $R (s, a', s')$ cf. @eq:PostShieldedReward.]
   as in @alg:QLearning, @l:QUpdate.
  It would be unsound to only update $Q(s, a')$, or to use the unaltered reward $R(s, a, s')$ from the original MDP.

  When updated correctly, the model will learn the outcome of picking $a in.not shield(s)$ as $sum_(s') P(s, a')(s')R(s, a', s')$.
  Other alterations to how value-updates are performed, such as penalising unsafe actions, may reduce the number of times the shield has to intervene #cl("DBLP:conf/ijcnn/SeurinPP20").
]

Both pre- and post-shielding preserve the assumptions necessary to guarantee convergence of a reinforcement learning algorithm to an optimal policy, but pre-shielding will likely converge faster than post-shielding in general:
If a model has a state $s$, with one safe action $a_1$ and unsafe actions $a_2$ and $a_3$, a post-shielded agent will have to explore actions $a_1, a_2$ and $a_3$ to estimate the expected reward attainable in $s$.
However, a pre-shielded agent will only explore $a_1$, since the other actions are masked.
Thus, it will gain a more precise estimate of the expected value of $s$ from the same amount of visits to the state.
A post-shielded agent may also choose to visit $s$ more often, if the RL method is configured to encourage exploration.

==== End-to-end Shielding
When the shield is in place and explicitly represented during _both_ the learning  _and_ operational phases, this is called end-to-end shielding (@fig:EndToEnd).

With a shield in place during training, the RL agent can avoid safety violations in all steps of the process.
This is a necessity if the RL agent is interacting with a real-life system where safety violations pose a danger to people or equipment.

As stated earlier, an end-to-end setup can make use of either a pre- or post-shield.
However, alternating between the two with e.g. pre-shielded training and a post-shielded operation is not sound.
The trained policy depends on how the shield is applied, and a change to the shield would disrupt it.

Compared to the completely unshielded case, end-to-end shielding was seen in @AlshiekhBEKNT18 to lead to a higher expected reward when trained on the same number of traces. 
The authors speculate that the shield acts as a teacher guiding the agent away from undesirable behaviours.
The same tendency has been observed in other works @carr_compositional_2025 #cl("DBLP:conf/aaai/Carr0JT23") #cl("DBLP:conf/ijcai/YangMRR23") @PaperA.
This is not a general rule, and there are also examples of shielded policies yielding less reward than the unshielded one @bloem_its_2020 @court_probabilistic_2025. These are cases where the shield prevents the exploitation of risky but more rewarding behaviour.

==== Training-only Shielding
When training finishes and the policy is taken into operation, the shield may not need to be explicitly represented (@fig:TrainingOnly).
This special case is called training-only shielding, and has the same benefits as end-to-end shielding. 

For example if the state-space $S$ is finite, a deterministic policy can be encoded as a set of state-action pairs $(s, a) in S times A$.
Shielded policies encoded in this way will naturally have $a in shield(s)$ for all encoded pairs $(s, a)$.
#footnote[The encoded policy is still shielded according to @def:Shielding, but the full shield is not kept.]
Such an encoding can save space on embedded hardware, which might not be able to accommodate an explicit representation of the shield.

Training-only shielding is not always an option. For e.g. neural networks working on continuous state-spaces, this $(s, a)$ representation is not possible.
Here, the shielded policy can only be represented as the weights of the neurons and an explicit representation of the shield.
However, reductions can be applied to the shield to reduce its memory footprint significantly @PaperD.

==== Operation-only Shielding

Shielding is not widely adopted in the industry, and many shield synthesis techniques require a detailed (safety-relevant) model of the system.
Therefore, policies that are "safe in practice" might be trained, tested and implemented at great expense.
Some time during operation, a shield may then be developed to provide formal safety guarantees, but it might not be cost effective or necessary to re-train the policy from scratch.
In these cases, the shield can be applied only in the operational phase.
If the policy did learn to avoid unsafe states perfectly, a maximally permissive shield would not interfere with its operation.
Otherwise, the shield will disrupt the optimized behaviour which the policy has learned.
It was found in Paper A @PaperA that applying a post-hoc post-shield to a policy can lead to substantial drops in the expected reward.
Therefore, post-hoc shielding should only be employed when end-to-end shielding is not possible.
One way to mitigate this might be fine-tuning the existing policy with the new shield in place.

#example(name: "Staying safe in Grid World")[
  Recall the MDP $cal(W)=(S, s_0, A, P, R)$ from @ex:GridWorld.
  Let the safe set be $phi=S \\ {💀}$. 
  What is the most permissive shield for $cal(W)$?
  Certainly, taking $➡$ in state 14 is prohibited.
  Next, any action in state 11 carries a risk of slipping and ending up in  💀, so state 11 should never be entered.
  Lastly, any action in state 10 can cause the agent to slip onto state 11, so this state should be avoided as well. 
  
  @fig:GridWorldShield shows the resulting maximally permissive safe policy for @ex:GridWorld. 
  This policy was generated using a publicly available package#footnote(link("https://github.com/AstridHornBrorholt/GridShielding.jl")) which implements the method described in Paper A (to be discussed in later sections).

#subpar.grid(columns: 3, align: bottom,
  [#figure(image("../Graphics/Intro/Shielded.png", width: 66.666%),
    caption: [A shield icon 🛡️ indicates the action is not permitted.]
  )<fig:GridWorldShield>],
  [#figure(image("../Graphics/Intro/Shielded Q-learning 500.png", width: 66.666%),
    caption: [A shield icon 🛡️ indicates the action is not permitted.]
  )<fig:GridWorldShieldedTraining>],
  caption: [Most permissive shield for Grid World.]
)

  This can be applied as a pre-shield by 
  1. Initializing the Q-values as $Q(s, a) = cases(-infinity " if " a in.not shield(s), 0  )$.
  2. Modifying the $epsilon$-greedy exploration strategy (@l:Explore in @alg:QLearning) to explore only safe actions $shield(s)$, instead of the full action space $A$.

  The result of end-to-end pre-shielding of the Grid World example is shown in @fig:GridWorldShieldedTraining.
  Compared to @fig:QGraph, this shielded learning graph has no sudden drops in episode rewards.
  Such drops in @fig:QGraph are present and indicate episodes where the agent is penalised for reaching state 15 💀.
  With the shield acting as a teacher, a reliable policy is quickly found, and no safety violations were encountered during training.

]<ex:GridWorldSafety>

=== Finite- and Infinite-horizon Shielding

Note that @def:Shielding requires safety over all infinite traces that are outcomes of the shield.
This generally requires computing the shield offline, which can be computationally infeasible for some models. 
Instead, it can make sense to only give guarantees $k$ steps into the future, computed on-line at each step.
These finite horizon shields are often referred to as _bounded prescience_  shields @giacobbe_shielding_2021, or $k$-step lookahead shields @xiao_model-based_2023 @yang_safe_2023.

One example of such a safety guarantee @giacobbe_shielding_2021  was given for a deterministic MDP, but here extended to include probabilistic outcomes: 
For an MDP $mdp$, action $a_0$  is $k$-safe at state $s_0$, if there exists a deterministic policy $pi$ such that for all traces $xi = s_0 a_0 ... s_k...$ with $pi(s_i) = a_i$ for $i > 0$, then $xi_0^k$ is safe.
This extends to other states $s$ by redefining the starting state of $mdp$ to $s$.

== Probabilistic Shielding <sec:ProbabilisticShielding>
...

== Adaptive Shielding <sec:AdaptiveShielding>
...

(pre- or post-)

=== Training and Operation <sec:AdaptiveTrainingAndOperation>

The training and operation phases described in @sec:TrainingAndOperation apply to an adaptive shield in the same way.
When the shield and policy are put into operation, they both become static.
In this way, adaptive shielding can be either end-to-end or training-only, depending on whether the final shield is explicitly represented during operation.

However,  an operation-only adaptive shield is a contradiction, since both shield and policy are static during operation.
With an alternative definition of the operation phase that allows an adaptive shield (while keeping the policy static) the data acquired might make the adaptive shield more permissive over time.
This appears to be an open research question, but it is difficult to imagine a case where the technical and legal limitations outlined in @sec:TrainingAndOperation require a fixed policy but not a fixed shield.

#new[
== Multi-agent Shielding <sec:MultiAgentShielding>

Many environments have multiple agents -- or _players_ -- interacting.
These multi-agent settings present unique challenges.

#definition(name:[$n$-player Markov Game])[
  A Markov Game (MG)~@zhang2021multi@busoniu_multi-agent_2010@marl-book with~$n$ players is a tuple $mg = (S, s_0, N, A, P, R)$
  where
  - $S$ is a finite set of states,
  - $s_0 in S$ is an initial state,
  - $N = (1, 2, ... n)$ represents the players,
  - $A = A_1 times A_2 times ... A_n$ is the joint action space,
  - $P : S times A -> (S -> [0; 1])$ gives the transition probability from one state to another by a joint action,
  - and $R : S times A times S -> RR^n$ is the reward function.

  $R$ induces individual reward functions $R_1, R_2, ...R_n$ where each $R_i$ gives the $i^"th"$ value of the vector: If $R(s, a, s) = r$ then $R_i (s, a, s) = r_i$.
]<def:mg>

Note that $S$, $s_0$ and $P$ are as in @def:mdp while the action space $A$ and reward function $R$ is changed to accommodate multiple players.
The joint action $a$ is the combination of players' individual choices $a = (a_1, a_2, ...a_n)^top$.
When $a$ is taken in state $s$, the player $i$ receives reward $R_i (s, a, s) = (R(s, a, s))_i$.

For an MG, there is one policy for each of the $n$ players, $(pi_1, pi_2, ...pi_n)$.
These are as in @def:policy, except that each policy $pi_i$ is over the player's own action space $A_i$.

#definition(name:[Individual and joint policies])[
  In an MG $mg$, individual policies $pi_i$ represent one player $i$ choosing from its own action space $A_i$.
  Deterministic, probabilistic and nondeterministic policies are respectively $S -> A_i$,\
   $S -> (A_i  → [0; 1])$, and $S → powerset(A_i)$ for each $i in N$. 

   A full complement of individual policies $(pi_1, pi_2, ...pi_n)$ induce a joint policy:
   - A _deterministic joint policy_ as $pi(s) = (pi_1 (s), pi_2 (s), ... pi_n (s))^top$,
   - a _probabilistic joint policy_ as $pi(s)(a) = product_(i in N) pi_i (s)(a)$, and
   - a _nondeterministic joint policy_ as $pi(s) = times.big_(i in N) pi_i (s)$
]<def:joint-policy>

Traces are defined from joint policies in the same manner as @def:trace.
Likewise, the definition of a joint policy can be used to describe the expected reward of a player:

#definition(name: [Expected individual reward])[
  Given an MG $mg$, a joint probabilistic policy $pi : S -> (A -> [0; 1])$ and a discount factor $gamma in [0; 1[$, the expected reward of player $i in N$ from $mg$, is the unique fixed point of the following equation

  $ EE_pi^(mg, i) (s) = sum_(a in A) pi(s)(a) sum_(s' in S) P(s, a)(s') (R_i (s, a, s') + gamma  EE_pi^(mg, i) (s')) $ 
]<def:individual-reward>


Recall that Q-learning assumes a static environment in order to prove convergence.
This assumption fails if multiple policies are acting upon the same environment while being continually updated.
Players can change their policy to optimize reward based on the current policy of all others, only for other players to update their policies in turn.
This prompts further policy changes in a cycle that may continue _ad infinitum._

It may not even be clear what the joint policy should converge to, depending on how the reward is defined.
An MG can fall into one of three different categories which describe the reward structure @zhang2021multi@busoniu_multi-agent_2010@marl-book.
 - Cooperative, where reward values are identical for all players: For $1 <= i < j <= n$ then $R_i (s, a) = R_j (s, a)$.
 - Competitive, in which the reward is zero-sum: $sum_(i = 0)^n R_i (s, a) = 0$.
 - Mixed, if the reward $R$ is neither competitive or cooperative. 
 
For mixed reward structures, the set of policies which give the highest possible reward to player $i$, is usually not the same as the set of policies that give the highest mean reward among all players.
Optimization objectives are often formulated instead a _Nash equilibrium_ or a _Pareto optimum._

Nash equilibria are concerned with changes to individual policies.
For a joint policy $pi$ induced by $(pi_1, pi_2, ... pi_n)$ and some individual policy $pi'_i$, let $(pi'_i, pi_(-i))$ be the joint policy induced by $(pi_1, pi_2, ... pi'_i, ... pi_n)$.

#definition(name: [Nash equilibrium])[
  For an MG $mg$, a joint policy $pi$ is a Nash equilibrium @zhang2021multi if no player $i$ can gain  a higher reward by changing its individual policy $pi_i$ to some other $pi'_i$. 
  That is to say, $pi$ is a Nash equilibrium if for every player $i$ and every state $s$,

  $ EE^(mg, i)_(pi)(s) >= EE^(mg, i)_((pi'_i, pi_(-i)))(s) " for any policy " pi'_i $
]
#question[ Should this ↑ just be from the initial state? I.e. $EE^(G, i)_pi (s_0)$ ? ]

It may be that changing multiple policies can lead to higher reward, but no single player can improve its policy.
Pareto optimality is a related, but stronger concept.

#definition(name: [Pareto optimal])[
   For an MG $mg = (S, s_0, N, A, P, R)$, the joint policy $pi$ is Pareto optimal~@marl-book if there is no other policy where the players' reward is just as high or higher.

   Specifically, a policy $pi'$ is Pareto dominated by $pi$ if 

   $ forall i in N, s in S : EE^(G, i)_pi (s) &>= EE^(G, i)_pi' (s) " and " \
   exists i in N, s in S : EE^(G, i)_pi (s) &> EE^(G, i)_pi' (s) $

   A policy $pi$ is Pareto optimal if it is not Pareto dominated by any other policy.

]

=== Safety

Safety as given in @def:Safety, described by safe sets $phi subset.eq S$, can be extended directly to MGs for states, traces and joint policies.
An individual policy is safe if it ensures the entire MG stays within the safe set, regardless of the behaviour of other agents. 
Formally, an individual policy $pi_i$ is safe if -- for any joint policy $pi$ -- every trace $xi$ that is an outcome of $(shield_i, pi_(-i))$ is safe.

Analogously to joint and individual policies, a shield is called either _global_ or _local._

#definition(name: "Global and local shields")[
  For an MG $mg = (S, s_0, N, A, P, R)$ and a safe set $phi subset.eq S$, a nondeterministic global policy is a global shield $shield : S → A$ if it is safe.

  A safe nondeterministic individual policy is called a local shield $shield_i : S -> A_i$.
]<def:GlobalAndLocalShields>

The concepts of maximally permissive shields and shielded global/local policies extend naturally from @def:Shielding.

A safe set may be feasible (@def:Feasibility) with a global shield, but not feasible for any of the players as a local shield.
This is shown in @ex:2PlayerGridWorld.


#example(name: "2-player Grid World")[
  Recall the Grid World $cal(W) = (S, s_0, A, P, R)$ from @ex:GridWorld. 
  Let the two-player version be $cal(W)^2 = (S^2, s'_0, N, A^2, P^2, R^2)$ with agents $N = { 🤖, 👾 }$.
  Here, the state space $S^2$ is $S times S$, the initial state $s_0 = (14, 2)$ and the action space $A^2 = A times A $.
  The transition probability function $P^2 : S^2 times A^2 → (S^2 → [0, 1])$ extends movement to two players in the natural way, while allowing both players to occupy the same space.
  A mixed reward structure is given by the function $R^2$ where $R_🤖(vec(s_1, s_2), a, vec(s'_1, s'_2)) = R(s_1, a_1, s'_1)$ and $R_👾(vec(s_1, s_2), a, vec(s'_1, s'_2)) = R(s_2, a_2, s'_2)$.


    #figure(
      {
        set text(fill: alizarin, size: 8pt)
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
      caption: [Initial state of 2-player Grid World with slippery tiles 🧊, an untimely end 💀, a goal state 🏁, and initial positions of players 🤖 and 👾.]
    )<fig:2PlayerGridWorld>

    Now consider the safe sets $phi_1 = { vec(s_1, s_2) | s_1 != 💀}$, $phi_2 = { vec(s_1, s_2) | s_2 != 💀}$, $phi = phi_1 intersection phi_2$ and $psi = phi intersection { vec(s_1, s_2) | s_1 != s_2 }$.
    Clearly, all sets are feasible as global shields.

    The safe set, $phi$ is not feasible with a local shield, since neither player has the ability to keep the other from entering 💀.
    But the safe set's components $phi_1$ and $phi_2$ both are feasible with local shields.

    Furthermore, $psi$ is feasible as a local shield $shield_👾$, since player 👾 has enough space around it to avoid 🤖 indefinitely.
    However, no local shield $shield_🤖$ exists.
    To see this, note that states 💀 and 🏁 cannot be left once entered, so these should both be avoided. 
    Thus, the slippery states 11 and 12 must also be avoided as seen in @ex:GridWorld.
    Therefore, player 🤖 has its initial movement constrained. In the worst case where player 👾 chases the other, there is no safe strategy.

    Even if it is possible to enforce $psi$ through $shield_👾$, the shield has to assume worst-case behaviour from the other player 🤖, which may be overly restrictive.
]<ex:2PlayerGridWorld>

The assumption that all agents can act in concert following some centralized shield is often unrealistic.
Additionally, the synthesis of  a global shield is often not computationally feasible because of state-space explosion. 

This necessitates the use of local shields, but many important safe sets may not be feasible to enforce in the default setting.
Even when a safe set can be feasibly enforced locally, even the most permissive shield may be too conservative.

=== Partial Observability

The assumption of full observability is particularly strong in MGs, and may even be computationally infeasible for a large number of players $n$.
The size of the state-space increases with the number of agents, which in some parts of the literature can be in the hundreds or low thousands #cl("DBLP:conf/iclr/QinZCCF21")@marl-book.
A state-space of this size can strain many RL algorithms, and the behaviour and positions of other agents far away, may not have a substantial impact on individual reward.

The limits of on-board sensors makes this omniscience technically impractical as well, and thus it is a common assumption that the game is _partially observable._
Agents may only be able to perceive the state of the game locally, or based on line of sight. 

In general, the optimal policy for a partially observable game requires memory of all previous observations.
If the trace $zeta_1^n = o_1 a_1 o_2 a_2, ... o_n$ is an alternating sequence of observations and actions, a policy with memory would choose the next action as $pi(zeta_1^n) = a_n$, while a memoryless policy would as only rely on the last observation $pi(o_n) = a_n$.
The difference in performance between the optimal memoryless policy and the optimal policy with memory depends on the game $mg$.

=== Communication

While players can directly interact through their choice of actions, additional communication is sometimes assumed.
For example #citationneeded[] assumes players choose their actions in a specific order, and that each player knows the choices of others if they are lower in the order.
In a partially observable setting, #citationneeded[] assumes that players are able to share their observations with other players within a certain range.
]

== Hybrid MDPs
...

=== Shielding of Hybrid Systems
...

== Tools for Shielding
#citationneeded[uppaal] #citationneeded[tempest]

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

  #bibliography("../Bibliography.bib",
    title: none,
  )
]
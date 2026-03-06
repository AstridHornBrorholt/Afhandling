### A Pluto.jl notebook ###
# v0.20.21

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    #! format: off
    return quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
    #! format: on
end

# ╔═╡ 6ec6d858-6ae7-47f7-bca1-94addc5677fa
begin
	using Pkg
	Pkg.activate(".", io=devnull)
	using Plots
	using PlutoUI
	using PlutoTest
	using Distributions
	using StatsBase
	using ProgressLogging
	using GridShielding
end

# ╔═╡ 486fa7ef-cc79-4b3c-a739-8af9b5cae326
md"""
# Q-learning of the gridworld
"""

# ╔═╡ 7e25d6a5-e945-4e75-8a17-48235cd230a0
TableOfContents()

# ╔═╡ e7416c3b-7969-42da-b897-9c6397737ccb
md"""
## Model
A robot 🤖 can move around along the cardinal directions on a $4 times 4$ grid, and must find an efficient path towards a goal 🏁 while avoiding a harmful tile 💀.  Movement is deterministic except for the ice tiles 🧊 where there is a chance of slipping in a different random direction. 
  The system is defined by the MDP $\cal G = ({1, 2, ... 16}, 14, {←, ↑, →, ↓}, P, R)$. 
  The state-space is laid out in a $4 \times 4$ grid as illustrated in the plot below, with $s_0$ marked by 🤖.
  With the exception of states 10, 11, (🧊) 15 (💀) and 16(🏁), transitions deterministically follow the cardinal direction indicated by the action. If the action would cause the agent to leave the grid, it stays in the same state.
  
  For example, $P(1, →, 2)  = 1$ (0 for any other $(1, →, s)$), $P(2, ↓, 6) = 1$ and $P(5, ←, 5) = 1$.


  
  In states 10 and 11, there is a 0.625 probability of moving in the manner described above, while the remaining probability mass is distributed among the other directions, i.e. $P(11, →, 15) = 0.125$. States 15 and 16 are terminal, which is modelled as $P(15, a, 15) = 1$ and $P(16, a, 16) = 1$ for any $a$. 
"""

# ╔═╡ f89282bf-4a86-483c-b34c-cac30525ca8e
S = [
	 1  2  3  4
	 5  6  7  8
	 9 10 11  12
	13 14 15  16
]

# ╔═╡ 05e698fa-9cdd-4ef9-a2b3-be29e6d53eff
begin
	🧊 = Set([10, 11])
	🤖 = 14
	💀 = 15
	🏁 = 16
end;

# ╔═╡ e7550ae3-5f15-4d47-af77-69ce441e30f5
function is_terminal(s)
	s == 🏁 || s == 💀
end

# ╔═╡ ecbe3620-f071-4ce4-a2c0-e6b7d201f509
A = [:↑, :↓, :→, :←]

# ╔═╡ 449cb2aa-c097-4d65-89fe-abce707e0a82
# Get x, y index from s
function indexof(s)
	index = findfirst(s′ -> s′ == s, S)
	@assert index != nothing "Could not find state $s"
	return Tuple(index) # cast to tuple from cartesianindex
end

# ╔═╡ c05f019d-3b02-43d3-9a06-32f0e3edfb30
let
	plot(xticks=nothing,
		 yticks=nothing,
		 xlim=(0, 4),
		 ylim=(0, 4),
		 yflip=true,
		 aspectratio=:equal,
		 axis=([], false))

	hline!(0:4, width=1, color=:gray, label=nothing)
	vline!(0:4, width=1, color=:gray, label=nothing)
	
	for x in 1:4, y in 1:4
		annotate!(y - 0.90, x - 0.90, text(S[x, y], 10))
	end

	for 🧊′ in 🧊
		x, y = indexof(🧊′)
		annotate!(y - 0.50, x - 0.50, text("⁣🧊", 30, "Fira sans"))
	end

	x, y = indexof(🤖)
	annotate!(y - 0.50, x - 0.50, text("⁣🤖", 30, "Fira sans"))

	x, y = indexof(💀)
	annotate!(y - 0.50, x - 0.50, text("⁣💀", 30, "Fira sans"))

	x, y = indexof(🏁)
	annotate!(y - 0.50, x - 0.50, text("⁣🏁", 30, "Fira sans"))

	plot!()
end

# ╔═╡ 18385c3f-8be1-4190-b831-2cfbffdd4760
S[4, 1]

# ╔═╡ e21084bc-480c-43b6-a714-49dd9465a98d
begin
	# Simulation function
	# State s, action A and random variable r.
	# Call as f(s, a) to sample an appropriate r.
	function f(s, a, r)
		if is_terminal(s) 
			return s
		end
	
		# Chance to slip
		if s ∈ 🧊 && r[1] <= 0.5
			a = A[ceil(Int, r[2]*length(A))]
		end
	
		# Apply action
		x, y = Tuple(indexof(s))
		if a == :↑
			x, y = x - 1, y
		elseif a == :↓
			x, y = x + 1, y
		elseif a == :→
			x, y = x, y + 1
		elseif a == :←
			x, y = x, y - 1
		else
			error()
		end
	
		# Bump into walls
		x, y = clamp(x, 1, 4), clamp(y, 1, 4)
	
		return S[x, y]
	end
	function f(s, a)
		r = [rand(Float64), rand(Float64)]
		f(s, a, r)
	end
end

# ╔═╡ ad495597-474d-4a77-936e-200900182cf0
# reward
function r(s)
	# Actually, moving to the terminal state also has a cost
	if s == 💀
		return -50
	else
		return -1
	end
end

# ╔═╡ 3b4b72a6-e2cb-42fd-943e-1ecfe83007aa
@bind s Select([S...], default=4) # Needs a list not a matrix

# ╔═╡ 25742c1b-2577-42ff-85b9-7a1271f8ae38
[f(10, :→) for _ in 1:20]

# ╔═╡ ac71275d-18b4-4e8c-aa94-220f4a6f5bee
@test f(1, :→) == 2

# ╔═╡ 0251135a-5f62-4628-a640-52459007fc4e
@test f(2, :↓) == 6

# ╔═╡ 9b5d9d5f-7840-4b1a-b7f0-6c6e2d33559b
@test f(5, :←) == 5

# ╔═╡ 7fb3f565-9005-4759-a0a6-10fb8fbec5b9
@test f(9, :→) == 10

# ╔═╡ 0a1e6927-5e45-430c-848f-cdd68e4321f0
@test f(12, :↓) == 🏁

# ╔═╡ a58cc125-a624-47e5-8a87-ded8bbdd1400
@test f(1, :↑) == 1

# ╔═╡ 6a18cd77-9373-4883-a474-9edcd73612db
md"""
## Mainmatter
"""

# ╔═╡ 824959db-709c-4981-b41f-21cd84534a7e
@bind ϵ_base NumberField(0.0001:0.0001:1, default=0.1)

# ╔═╡ b38a2695-8674-4cb2-aa64-19e036dba201
@bind α_base NumberField(0.0001:0.0001:1, default=0.1)

# ╔═╡ 031ee7b6-924d-48ba-82ea-d8c0ccf7ad48
@bind γ NumberField(0.0001:0.0001:1, default=0.99)

# ╔═╡ 65ce31d7-3efc-45f0-8aa7-e635aa5138c9
# It's important for the Q-updates that the terminal states are zero
Q_init = Dict{Tuple{Int64, Symbol}, Float64}(
	(s, a) => 0 
	for s in S, a in A
)

# ╔═╡ 2a60f299-1284-49ab-b06f-9cd1a9865d05
begin
	epsilon_proc = Ref(0)
	steps = Ref(0)
end

# ╔═╡ 9e578974-ba8d-4df9-95c4-b312f6020e35
# ϵ-greedy choice from Q.
function ϵ_greedy(ϵ::Number, Q, s)
	steps[] += 1
	if rand(Uniform(0, 1)) < ϵ
		epsilon_proc[] += 1
		return rand(A)
	else
		return argmax((a) -> Q[s, a], A)
	end
end

# ╔═╡ e84716bf-f49f-460d-96e8-2e68aec1077d
[ϵ_greedy(0.2, Q_init, 1) for _ in 1:10]

# ╔═╡ 1794648d-5d7c-4e9e-b402-6d7a352f3d32
epsilon_proc[]/steps[]

# ╔═╡ 3b4e1eec-f41f-4fe2-9332-f550f58b6cb3
md"""
### This is Where Training Happens
"""

# ╔═╡ db5cfccc-600d-43cd-9273-44eb2abc0ab6
@bind example_trace_button CounterButton("Example Trace")

# ╔═╡ 1aacbba5-faf8-4c11-8637-5d5ca6548e9b
best_a(Q, s) = argmax(a -> Q[s, a], A)

# ╔═╡ 1bc2ba1a-9634-4b92-95ce-38b79c571f55
0.5*0.25

# ╔═╡ 6e0a220d-4ce6-4762-89c5-c7036b5e1624
r(💀)*γ^2*(0.5*0.25)*(0.5*0.25)

# ╔═╡ ebb73e9d-4547-43c9-8d9b-a58fc772e355
md"""
# Shielded Q-learning
"""

# ╔═╡ 95fd9831-cd53-4abe-9170-81ae9045d088
is_safe(s) = s != 💀

# ╔═╡ c08be429-70a9-4f9e-a296-de6dfb8e7a77
is_safe(bounds::Bounds) = is_safe(bounds.lower[1])

# ╔═╡ f6855967-ce1f-4cfe-a69d-734310537445
@enum action up down left right

# ╔═╡ ab7ee3f2-79f0-4f92-b98f-95ea8758d4cd
# Episode max length
@bind T NumberField(1:typemax(Int64), default=1000)

# ╔═╡ 7aa16fa3-4473-400d-9dac-278994fa2952
@bind episodes NumberField(0:typemax(Int64), default=5)

# ╔═╡ ce77f7fd-f877-40a2-b463-da2932f42fe6
function ϵ(t; episodes=episodes)
	#return ϵ_base
	if t < episodes/2
		ϵ_base
	else
		ϵ_base/(1 + 0.01*(t - episodes/2))
	end
end

# ╔═╡ cc8676e4-57fd-4bcc-bd82-b0fe05f3faaa
function α(t; episodes=episodes)
	if t < episodes/2
		α_base
	else
		α_base/(1 + 0.01*(t - episodes/2))
	end
end

# ╔═╡ fca65903-1802-4829-a3a6-649cf150bf1d
let
	episodes = 1000
	p1 = plot(xlabel="t", size=(300, 300))
	plot!(y -> ϵ(y; episodes), xlim=(0, episodes), label="ϵ")
	hline!([0], line=:black, label=nothing)
	p2 = plot(xlabel="t", size=(300, 300))
	plot!(y -> α(y; episodes), xlim=(0, episodes), label="α", color=:orange)
	hline!([0], line=:black, label=nothing)
	plot(p1, p2, size=(600, 300))
end

# ╔═╡ 2f9c55d9-afb8-440b-98c5-17321ce58d36
function Q_episode!(Q, i)
	Σr =  0
	Sₜ = 🤖
	Aₜ = ϵ_greedy(ϵ(i), Q, Sₜ)
	ξ = []
	for t ∈ 1:T
		Sₜ₊₁ = f(Sₜ, Aₜ)
		rₜ₊₁ = r(Sₜ₊₁)
		Σr += rₜ₊₁
		
		Q[Sₜ, Aₜ] = 
			Q[Sₜ, Aₜ] + 
			α(i)*(rₜ₊₁ + γ*max([Q[Sₜ₊₁, a′] for a′ in A]...) -  Q[Sₜ, Aₜ])
		
		Aₜ₊₁ = ϵ_greedy(ϵ(i), Q, Sₜ₊₁)
		
		# @info "" Sₜ Aₜ Sₜ₊₁ r(Sₜ₊₁) Q[Sₜ, Aₜ]
		push!(ξ, (Sₜ, Aₜ, rₜ₊₁))

		if is_terminal(Sₜ₊₁)
			return Σr, ξ
		end
		
		Sₜ, Aₜ = Sₜ₊₁, Aₜ₊₁
	end
	return Σr, ξ
end

# ╔═╡ 14b48ff2-a8a5-4750-a66a-91e86aa5754e
function Q_learn!(Q)
	rewards = []
	
	@progress for i ∈ 1:episodes
		R, ξ = Q_episode!(Q, i)
		push!(rewards, R)
	end

	return rewards
end

# ╔═╡ db10ce55-cf88-4caf-8b18-913be69687a1
begin
	episodes
	Q = copy(Q_init)
	rewards = Q_learn!(Q)
end

# ╔═╡ e5185211-21f8-4918-93b5-5e221baa7487
V = [max([Q[s, a] for a in A]...) for s in S]

# ╔═╡ cf2299a3-6533-4f24-8e44-7d42fd51a2cb
let
	example_trace_button # This button updates the weights by one episode
	
	mm = Plots.Measures.mm
	heatmap(V,
		fontfamily="times",
		color=cgrad([:white, :wheat]),
		xlabel="x",
		ylabel="y",
		yflip=true,
		ticks=nothing,
		clim=(-10, 1),
		#title="heatmap of V and strategy π",
		#title="$episodes episodes",
		margin=2mm,
		size=(400, 400))

	for 🧊′ in 🧊
		x, y = indexof(🧊′)
		annotate!(y + 0.05, x - 0.30, text("⁣🧊", 15, "Fira sans"))
	end

	x, y = indexof(🤖)
	annotate!(y + 0.05, x - 0.30, text("⁣🤖", 15, "Fira sans"))

	x, y = indexof(💀)
	annotate!(y + 0.05, x - 0.30, text("⁣💀", 15, "Fira sans"))

	x, y = indexof(🏁)
	annotate!(y + 0.05, x - 0.30, text("⁣🏁", 15, "Fira sans"))
	
	for x in 1:4, y in 1:4
		annotate!(y - 0.30, x - 0.30, text(S[x, y], :crimson, 10))
		is_terminal(S[x, y]) && continue
		annotate!(y, x + 0.00, text(best_a(Q, S[x, y]), :gray))
		annotate!(y, x + 0.30, text(round(V[x, y], digits=2), "times"), :black)
	end
	plot!()
end

# ╔═╡ ce581d0e-a772-4c15-ae96-3eba9ff79a3f
Q[10, :→]

# ╔═╡ b72996b7-0f3c-43ae-8141-1d907d26bb13
if episodes < 100000
	plot(rewards, 
		 fontfamily="times",
		 label=nothing, 
		 xlabel="Episode",
		 ylabel="Reward",
		 ylim=(-70, 1), 
		 #yticks=[-150, -100, -50, 0, 10],
		 size=(400, 400))
else
	"too much to plot"
end

# ╔═╡ ca4a816e-6de6-4395-80ee-b2b332e56e43
if example_trace_button > 0
	Q_episode!(Q, episodes)
end

# ╔═╡ def7620e-3170-4542-8098-22edfd4f91f4
ϵ(episodes)

# ╔═╡ cbf6e5f5-6949-4315-8d41-46f1e8869e96
any_action, no_action = actions_to_int(instances(action)), actions_to_int([])

# ╔═╡ 69e8dd6b-939a-4e62-a66f-14e4e5cf8741
begin
	grid = Grid(1.0, [1], [17])
	initialize!(grid, state -> is_safe(state) ? any_action : no_action)
end

# ╔═╡ b6f240ef-7bb4-4e7a-b713-47fd49d102c7
samples_per_axis = [1]

# ╔═╡ 7ef4031a-41a3-4068-831f-e6bf163f2f95
samples_per_axis_random = [2, 4]

# ╔═╡ 1489d048-36cf-460d-8936-4e912dab1174
randomness_space = Bounds([eps(), eps()], [1., 1.])

# ╔═╡ f61d1749-6140-423f-80ca-ac4b0f015d93
enum_to_action = Dict(up => :↑, down => :↓, left => :←, right => :→)

# ╔═╡ 8af24b46-9846-428e-94d2-3b122abac3fe
simulation_function(s, a, r) = f(s[1], enum_to_action[a], r)

# ╔═╡ ece6bab4-c43c-4937-87c8-a8d7b87d2ce7
simulation_function(10, up, [0.1, 0.8])

# ╔═╡ 2fa81685-85f8-495c-9951-6b177ae08a13
model = SimulationModel(simulation_function, randomness_space, samples_per_axis, samples_per_axis_random)

# ╔═╡ 51ef81a3-ca59-4d15-a7a1-dfe4b922da94
reachability_function = get_barbaric_reachability_function(model)

# ╔═╡ 339de6c7-7fce-41b6-8994-afbc8b5ddc06
action_to_enum = Dict(v => k for (k, v) in enum_to_action)

# ╔═╡ 9a223369-e24a-467d-987c-a66048a7889f
shield, max_steps_reached = make_shield(reachability_function, action, grid)

# ╔═╡ 6d30e508-ac43-4f4a-9c65-be6472b65e2f
shield.array

# ╔═╡ de3cda12-156d-4da1-aa14-866448493611
let
	mm = Plots.Measures.mm
	heatmap(zeros(4, 4),
		fontfamily="times",
		color=cgrad([:white, :wheat]),
		xlabel="x",
		ylabel="y",
		yflip=true,
		ticks=nothing,
		clim=(0, 1),
		cbar=nothing,
		#title="heatmap of V and strategy π",
		#title="$episodes episodes",
		margin=2mm,
		size=(400, 400))
	hline!(0.5:4.5, color=:gray, label=nothing)
	vline!(0.5:4.5, color=:gray, label=nothing)

	for 🧊′ in 🧊
		x, y = indexof(🧊′)
		annotate!(y + 0.05, x - 0.30, text("⁣🧊", 15, "Fira sans"))
	end

	x, y = indexof(🤖)
	annotate!(y + 0.05, x - 0.30, text("⁣🤖", 15, "Fira sans"))

	x, y = indexof(💀)
	annotate!(y + 0.05, x - 0.30, text("⁣💀", 15, "Fira sans"))

	x, y = indexof(🏁)
	annotate!(y + 0.05, x - 0.30, text("⁣🏁", 15, "Fira sans"))
	
	for x in 1:4, y in 1:4
		annotate!(y - 0.30, x - 0.30, text(S[x, y], :crimson, 10))
	end
	
	for (s, allowed) in enumerate(shield.array)
		x, y = indexof(s)
		allowed = [enum_to_action[a] for a in int_to_actions(action, allowed)]
		
		annotate!(y - 0.00, x - 0.0, 
				  :↑ in allowed ? text("↑", :green, 12) : text("⁣🛡️", :red, 12, "sans"))
		
		annotate!(y + 0.00, x + 0.3, 
				  :↓ in allowed ? text("↓", :green, 12) : text("⁣🛡️", :red, 12, "sans"))
		
		annotate!(y - 0.15, x + 0.15, 
				  :← in allowed ? text("←", :green, 12) : text("⁣🛡️", :red, 12, "sans"))
		
		annotate!(y + 0.15, x + 0.15, 
				  :→ in allowed ? text("→", :green, 12) : text("⁣🛡️", :red, 12, "sans"))
	end
	plot!()
end

# ╔═╡ 6d7e2b34-a4b0-4ccd-990f-563ddb263839
md"""
## Try it out! -- Test the shield
Using the power of Pluto Notebooks reactivity, you can play the Grid World example yourself.

Optionally (checkbox below) you can explore the grid-world safely by having the shield override unsafe actions.
"""

# ╔═╡ 7dbba168-a3d3-43fc-9a5e-b024c07fd308
function shield_action(shield::Grid, state, a)
	a = action_to_enum[a]
	partition = box(shield, state)
	allowed = int_to_actions(action, get_value(partition))
	if a in allowed || length(allowed) == 0
		return a
	else
		return rand(allowed)
	end
end

# ╔═╡ e5de6151-854b-4f7e-ab02-d90d53f8a648
shield_action(shield, 4, :→)

# ╔═╡ 3829efdf-a83f-453d-85d2-7acb9fa73e5d
@bind enable_shield CheckBox(default=true)

# ╔═╡ 5a875169-2352-48f7-84cd-be08e057a27b
@bind reset_button CounterButton("Reset")

# ╔═╡ 02bec057-1a49-4277-9cb9-3d84774702ea
begin
	# This cell is run every time the reset_button is pressed.
	reset_button 
	
	# Reactive variable! Values in this array change as the notebook is updated.
	state = Ref(🤖)
end;

# ╔═╡ cfae881c-5f82-440a-8eec-a91585093a47
f(s, a)

# ╔═╡ ac30af3f-cd12-4919-b878-5eeb3a395e5b
a

# ╔═╡ eb635396-f228-465c-ba53-92ca480802d5
begin
	a, enable_shield, reset_button # reactivity
	
	@bind step_button CounterButton("Step")
end

# ╔═╡ 9ba29fe8-c0f2-49b8-bb33-37ad4968e639
stepped = if step_button > 0 let
	if enable_shield
		a = shield_action(shield, state[], a)
	end
	new_state = f(state[], enum_to_action[a])
	old_state = state[]
	state[] = new_state
	"Taking a step... ($old_state, $a, $new_state)"
end  end

# ╔═╡ 95030030-616b-41a4-bc8a-31e1d756e46e
reset_button, stepped; state

# ╔═╡ 3f99c83f-6c5a-44af-b874-eaba79774c91
let
	stepped
	plot(xticks=nothing,
		 yticks=nothing,
		 xlim=(0, 4),
		 ylim=(0, 4),
		 yflip=true,
		 aspectratio=:equal,
		 axis=([], false))

	hline!(0:4, width=1, color=:gray, label=nothing)
	vline!(0:4, width=1, color=:gray, label=nothing)
	
	for x in 1:4, y in 1:4
		annotate!(y - 0.80, x - 0.90, text("$x, $y", 10))
	end

	for 🧊′ in 🧊
		x, y = indexof(🧊′)
		annotate!(y - 0.50, x - 0.50, text("⁣🧊", 30, "Fira sans"))
	end

	x, y = indexof(💀)
	annotate!(y - 0.50, x - 0.50, text("⁣💀", 30, "Fira sans"))

	x, y = indexof(🏁)
	annotate!(y - 0.50, x - 0.50, text("⁣🏁", 30, "Fira sans"))

	x, y = indexof(state[])
	annotate!(y - 0.50, x - 0.50, text("⁣🤖", 30, "Fira sans"))

	plot!()
end

# ╔═╡ ddc96755-f381-48d6-83ce-41504bd6145e
# ╠═╡ disabled = true
#=╠═╡
@bind a Select(A)
  ╠═╡ =#

# ╔═╡ 010a459c-a960-48ef-b8f1-a3ab16bd557a
@bind a Radio(A, default=A[1])

# ╔═╡ Cell order:
# ╠═6ec6d858-6ae7-47f7-bca1-94addc5677fa
# ╟─486fa7ef-cc79-4b3c-a739-8af9b5cae326
# ╠═7e25d6a5-e945-4e75-8a17-48235cd230a0
# ╟─e7416c3b-7969-42da-b897-9c6397737ccb
# ╠═e7550ae3-5f15-4d47-af77-69ce441e30f5
# ╠═f89282bf-4a86-483c-b34c-cac30525ca8e
# ╠═05e698fa-9cdd-4ef9-a2b3-be29e6d53eff
# ╠═c05f019d-3b02-43d3-9a06-32f0e3edfb30
# ╠═ecbe3620-f071-4ce4-a2c0-e6b7d201f509
# ╠═449cb2aa-c097-4d65-89fe-abce707e0a82
# ╠═18385c3f-8be1-4190-b831-2cfbffdd4760
# ╠═e21084bc-480c-43b6-a714-49dd9465a98d
# ╠═ad495597-474d-4a77-936e-200900182cf0
# ╠═ddc96755-f381-48d6-83ce-41504bd6145e
# ╠═3b4b72a6-e2cb-42fd-943e-1ecfe83007aa
# ╠═cfae881c-5f82-440a-8eec-a91585093a47
# ╠═25742c1b-2577-42ff-85b9-7a1271f8ae38
# ╠═ac71275d-18b4-4e8c-aa94-220f4a6f5bee
# ╠═0251135a-5f62-4628-a640-52459007fc4e
# ╠═9b5d9d5f-7840-4b1a-b7f0-6c6e2d33559b
# ╠═7fb3f565-9005-4759-a0a6-10fb8fbec5b9
# ╠═0a1e6927-5e45-430c-848f-cdd68e4321f0
# ╠═a58cc125-a624-47e5-8a87-ded8bbdd1400
# ╟─6a18cd77-9373-4883-a474-9edcd73612db
# ╠═824959db-709c-4981-b41f-21cd84534a7e
# ╠═b38a2695-8674-4cb2-aa64-19e036dba201
# ╠═ab7ee3f2-79f0-4f92-b98f-95ea8758d4cd
# ╠═031ee7b6-924d-48ba-82ea-d8c0ccf7ad48
# ╠═9e578974-ba8d-4df9-95c4-b312f6020e35
# ╠═65ce31d7-3efc-45f0-8aa7-e635aa5138c9
# ╠═e84716bf-f49f-460d-96e8-2e68aec1077d
# ╠═ce77f7fd-f877-40a2-b463-da2932f42fe6
# ╠═cc8676e4-57fd-4bcc-bd82-b0fe05f3faaa
# ╠═fca65903-1802-4829-a3a6-649cf150bf1d
# ╠═14b48ff2-a8a5-4750-a66a-91e86aa5754e
# ╠═2f9c55d9-afb8-440b-98c5-17321ce58d36
# ╠═2a60f299-1284-49ab-b06f-9cd1a9865d05
# ╠═1794648d-5d7c-4e9e-b402-6d7a352f3d32
# ╟─3b4e1eec-f41f-4fe2-9332-f550f58b6cb3
# ╠═7aa16fa3-4473-400d-9dac-278994fa2952
# ╠═db10ce55-cf88-4caf-8b18-913be69687a1
# ╠═b72996b7-0f3c-43ae-8141-1d907d26bb13
# ╠═db5cfccc-600d-43cd-9273-44eb2abc0ab6
# ╠═ca4a816e-6de6-4395-80ee-b2b332e56e43
# ╠═def7620e-3170-4542-8098-22edfd4f91f4
# ╠═e5185211-21f8-4918-93b5-5e221baa7487
# ╠═1aacbba5-faf8-4c11-8637-5d5ca6548e9b
# ╠═cf2299a3-6533-4f24-8e44-7d42fd51a2cb
# ╠═ce581d0e-a772-4c15-ae96-3eba9ff79a3f
# ╠═1bc2ba1a-9634-4b92-95ce-38b79c571f55
# ╠═6e0a220d-4ce6-4762-89c5-c7036b5e1624
# ╟─ebb73e9d-4547-43c9-8d9b-a58fc772e355
# ╠═95fd9831-cd53-4abe-9170-81ae9045d088
# ╠═c08be429-70a9-4f9e-a296-de6dfb8e7a77
# ╠═cbf6e5f5-6949-4315-8d41-46f1e8869e96
# ╠═f6855967-ce1f-4cfe-a69d-734310537445
# ╠═69e8dd6b-939a-4e62-a66f-14e4e5cf8741
# ╠═b6f240ef-7bb4-4e7a-b713-47fd49d102c7
# ╠═7ef4031a-41a3-4068-831f-e6bf163f2f95
# ╠═1489d048-36cf-460d-8936-4e912dab1174
# ╠═8af24b46-9846-428e-94d2-3b122abac3fe
# ╠═ece6bab4-c43c-4937-87c8-a8d7b87d2ce7
# ╠═2fa81685-85f8-495c-9951-6b177ae08a13
# ╠═51ef81a3-ca59-4d15-a7a1-dfe4b922da94
# ╠═f61d1749-6140-423f-80ca-ac4b0f015d93
# ╠═339de6c7-7fce-41b6-8994-afbc8b5ddc06
# ╠═9a223369-e24a-467d-987c-a66048a7889f
# ╠═6d30e508-ac43-4f4a-9c65-be6472b65e2f
# ╠═de3cda12-156d-4da1-aa14-866448493611
# ╠═6d7e2b34-a4b0-4ccd-990f-563ddb263839
# ╠═7dbba168-a3d3-43fc-9a5e-b024c07fd308
# ╠═e5de6151-854b-4f7e-ab02-d90d53f8a648
# ╠═3829efdf-a83f-453d-85d2-7acb9fa73e5d
# ╠═5a875169-2352-48f7-84cd-be08e057a27b
# ╠═95030030-616b-41a4-bc8a-31e1d756e46e
# ╠═02bec057-1a49-4277-9cb9-3d84774702ea
# ╠═010a459c-a960-48ef-b8f1-a3ab16bd557a
# ╠═ac30af3f-cd12-4919-b878-5eeb3a395e5b
# ╠═eb635396-f228-465c-ba53-92ca480802d5
# ╠═9ba29fe8-c0f2-49b8-bb33-37ad4968e639
# ╠═3f99c83f-6c5a-44af-b874-eaba79774c91

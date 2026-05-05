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

# ╔═╡ 42548379-376c-45fc-b2e2-fd3b4fc51872
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

# ╔═╡ c6f38301-5eb7-4e98-bafd-6a0bcd2fb1b6
md"""
# Shielding Grid World
"""

# ╔═╡ 0f6f658f-56a3-4de3-b1ef-0c3de76a2d37
TableOfContents()

# ╔═╡ 8ab142ac-2bb9-42fd-bb52-781a3bdee3f9
md"""
## Model
A robot 🤖 can move around along the cardinal directions on a $4 times 4$ grid, and must find an efficient path towards a goal 🏁 while avoiding a harmful tile 💀.  Movement is deterministic except for the ice tiles 🧊 where there is a chance of slipping in a different random direction. 
  The system is defined by the MDP ${\cal G} = ({1, 2, ... 16}, 14, {←, ↑, →, ↓}, P, R)$. 
  The state-space is laid out in a $4 \times 4$ grid as illustrated in the plot below, with $s_0$ marked by 🤖.
  With the exception of states 10, 11, (🧊) 15 (💀) and 16(🏁), transitions deterministically follow the cardinal direction indicated by the action. If the action would cause the agent to leave the grid, it stays in the same state.
  
  For example, $P(1, →, 2)  = 1$ ($0$ for any other $(1, →, s)$), $P(2, ↓, 6) = 1$ and $P(5, ←, 5) = 1$.


  
  In states 10 and 11, there is a 0.625 probability of moving in the manner described above, while the remaining probability mass is distributed among the other directions, i.e. $P(11, →, 15) = 0.125$. States 15 and 16 are terminal, which is modelled as $P(15, a, 15) = 1$ and $P(16, a, 16) = 1$ for any $a$. 
"""

# ╔═╡ a5bba2c0-d04d-4995-b55a-3e1928b7da62
S = [
	 1  2  3  4
	 5  6  7  8
	 9 10 11  12
	13 14 15  16
]

# ╔═╡ aeb428b9-0727-4a21-b4ec-91c3972ff0cf
begin
	🧊 = Set([10, 11])
	🤖 = 14
	💀 = 15
	🏁 = 16
end;

# ╔═╡ 7c634330-d307-4f32-9649-a79c849c12af
function is_terminal(s)
	s == 🏁 || s == 💀
end

# ╔═╡ cd7ae301-9eec-4921-9d08-dd809093cc8e
A = [:↑, :↓, :→, :←]

# ╔═╡ 22363ada-9450-449f-90c5-4abba2a3e7b1
# Get x, y index from s
function indexof(s)
	index = findfirst(s′ -> s′ == s, S)
	@assert index != nothing "Could not find state $s"
	return Tuple(index) # cast to tuple from cartesianindex
end

# ╔═╡ 4de87d0d-b485-4e2c-afd9-137bde99e79c
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
		annotate!(y - 0.50, x - 0.50, text("⁣🧊", 30, "Helvetica"))
	end

	x, y = indexof(🤖)
	annotate!(y - 0.50, x - 0.50, text("⁣🤖", 30, "Helvetica"))

	x, y = indexof(💀)
	annotate!(y - 0.50, x - 0.50, text("⁣💀", 30, "Helvetica"))

	x, y = indexof(🏁)
	annotate!(y - 0.50, x - 0.50, text("⁣🏁", 30, "Helvetica"))

	plot!()
end

# ╔═╡ aa81e27a-b248-45bb-ab1c-9c6e3ac1aa24
S[4, 1]

# ╔═╡ a832de86-2f9f-43b8-b379-f17a6109b50b
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

# ╔═╡ 5468e72e-bf32-4ca8-a9b7-579aaef265e0
# reward
function r(s)
	# Actually, moving to the terminal state also has a cost
	if s == 💀
		return -50
	else
		return -1
	end
end

# ╔═╡ a4fc59ad-af31-4644-b716-868ac21b996a
@bind a Select(A)

# ╔═╡ 54fbe43e-eb61-4630-82e7-9c4c0c5c8b86
@bind s Select([S...], default=4) # Needs a list not a matrix

# ╔═╡ 39872b3f-ffe0-4bce-9686-e4bd142da607
f(s, a)

# ╔═╡ 3115ec67-977f-495a-a55c-9be13129dbfd
[f(10, :→) for _ in 1:20]

# ╔═╡ 73030552-c725-4829-9583-23a89b592a9a
@test f(1, :→) == 2

# ╔═╡ 2342191b-1d65-4f3c-b118-e38085fbcab7
@test f(2, :↓) == 6

# ╔═╡ c93b9adf-b4df-4755-94c6-4eade5c75b2e
@test f(5, :←) == 5

# ╔═╡ 1799ddea-cf99-4736-9008-80fe4b621145
@test f(9, :→) == 10

# ╔═╡ 95c8ce15-7a1e-4060-a418-0ece089e66aa
@test f(12, :↓) == 🏁

# ╔═╡ 713e8cdb-1d9f-4e8e-8b05-71d14c047f73
@test f(1, :↑) == 1

# ╔═╡ 2a754cfb-a824-4fbb-999b-27e2b1439e1f
md"""
## Synthesizing a Shield

This is done using the [GridShielding.jl](https://github.com/AstridHornBrorholt/GridShielding.jl) package
"""

# ╔═╡ 6455a04a-3729-44cd-a9c9-2109706f794a
begin
	# Defining the is_safe(bounds) function
	
	is_safe(s) = s != 💀

	is_safe(bounds::Bounds) = is_safe(bounds.lower[1])
end

# ╔═╡ d5eedc70-c808-474d-b8e2-98f87bb21d7f
#actions must be enums
@enum Action up down left right

# ╔═╡ 30e8d819-fbc2-4e60-90fc-6882925fc833
any_action, no_action = actions_to_int(instances(Action)), actions_to_int([])

# ╔═╡ 0ce51653-1f4b-451f-b8b3-d5b0480707af
enum_to_action = Dict(up => :↑, down => :↓, left => :←, right => :→)

# ╔═╡ 3fb26ecf-d11e-404a-ab16-08676b81d124
action_to_enum = Dict(v => k for (k, v) in enum_to_action)

# ╔═╡ 952a7f42-364a-460f-bbde-c13239d55459
md"""
### Configuring Parameters & Setting Everyting Up
"""

# ╔═╡ eac046eb-392d-4a84-bc6a-837480a76765
begin
	grid = Grid(1.0, [1], [17])
	initialize!(grid, state -> is_safe(state) ? any_action : no_action)
end

# ╔═╡ fa05187e-3f6a-437a-853d-93b29c352782
samples_per_axis = [1]

# ╔═╡ 9c61cada-df4a-49d0-93d4-45d3a7bae866
samples_per_axis_random = [2, 4]

# ╔═╡ d37c80b0-0cef-42aa-a878-ade06954f442
randomness_space = Bounds([eps(), eps()], [1., 1.])

# ╔═╡ 060c4170-aba1-4b1b-9710-86beb904a602
simulation_function(s, a, r) = f(s[1], enum_to_action[a], r)

# ╔═╡ 0af99598-9e2a-494e-b2e9-0d3911670900
simulation_function(10, up, [0.1, 0.8])

# ╔═╡ d48f7d1c-3aee-4f96-92cd-34925bd8abf8
model = SimulationModel(simulation_function, randomness_space, samples_per_axis, samples_per_axis_random)

# ╔═╡ 0ae4c6af-cfa1-4a4e-abb7-7e7db97698a5
reachability_function = get_barbaric_reachability_function(model)

# ╔═╡ fc61b87d-9097-44cb-ab8b-8d3b3db98a43
md"""
### Synthesis
"""

# ╔═╡ 57cd2a0d-3462-4924-8198-af907c763074
shield, max_steps_reached = make_shield(reachability_function, Action, grid)

# ╔═╡ ec0c414f-1c6a-4a2d-99cf-468fa617f36b
shield.array

# ╔═╡ 403a5a86-1fb8-498b-bd83-a418f9165fa3
let
	mm = Plots.Measures.mm
	heatmap(zeros(4, 4),
		title="Resulting Shield",
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
		annotate!(y + 0.05, x - 0.30, text("⁣🧊", 15, "Helvetica"))
	end

	x, y = indexof(🤖)
	annotate!(y + 0.05, x - 0.30, text("⁣🤖", 15, "Helvetica"))

	x, y = indexof(💀)
	annotate!(y + 0.05, x - 0.30, text("⁣💀", 15, "Helvetica"))

	x, y = indexof(🏁)
	annotate!(y + 0.05, x - 0.30, text("⁣🏁", 15, "Helvetica"))
	
	for x in 1:4, y in 1:4
		annotate!(y - 0.30, x - 0.30, text(S[x, y], :crimson, 10))
	end
	
	for (s, allowed) in enumerate(shield.array)
		x, y = indexof(s)
		allowed = [enum_to_action[a] for a in int_to_actions(Action, allowed)]
		
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

# ╔═╡ b7c00112-ebe4-454e-a35a-7ba4e19ba9ea
md"""
### Shielding Functions
"""

# ╔═╡ cc49eb4b-7393-49e8-84ad-167f3853f4f3
function allowed(shield::Grid, state)
	partition = box(shield, state)
	allowed = int_to_actions(Action, get_value(partition))
	if length(allowed) == 0 
		allowed = instances(Action)
	end
	allowed = [enum_to_action[a] for a in allowed]
	return allowed
end

# ╔═╡ 312adb87-4ad8-4d98-b751-b49a1dfde418
allowed(shield, 14)

# ╔═╡ 20328a59-110e-4cd9-a02e-f5eb197d5ae7
allowed(shield, 15)

# ╔═╡ 3ac3936c-c011-42f2-a8d3-f2b590b60a82
begin
	function allows(shield::Grid, state, a::Action)
		enum_to_action[a] in allowed(shield, state)
	end
	
	function allows(shield::Grid, state, a::Symbol)
		return a in allowed(shield, state)
	end
end

# ╔═╡ ea419be2-1b1e-40f2-b823-673a4c38f543
allows(shield, 14, :↑)

# ╔═╡ 8a78e939-8005-4eb1-b072-5d4c427cbc3a
md"""
## Try it out! 🎈 Test the shield
Using the power of Pluto Notebooks reactivity, you can play the Grid World example yourself.

Optionally (checkbox below) you can explore the grid-world safely by having the shield override unsafe actions.
"""

# ╔═╡ ba1aad2e-2928-483d-a3cd-4c2da6aa8d94
md"""
**Enable Shield**
$(@bind enable_shield CheckBox(default=false))
"""

# ╔═╡ c5e1c1bc-f127-42a7-bb63-ca6c83d126c3
@bind reset_button CounterButton("Reset")

# ╔═╡ ac78e8c6-202a-42e9-88c7-aa4a3bacbb4b
begin
	enable_shield, reset_button
	md"""
	Controls:
	
	               $(@bind up_button CounterButton("⬆️"))
	
	  
	$(@bind left_button CounterButton("⬅️"))
	              
	$(@bind right_button CounterButton("➡️"))
	
	               $(@bind down_button CounterButton("⬇️"))
	"""
end

# ╔═╡ bfbb7e69-96aa-4c45-8401-61e9e3044d86
begin
	reset_button # This cell is run every time the reset_button is pressed.
	
	# Reactive variable! Values in this array change as the notebook is updated.
	state = Ref(🤖)
end;

# ╔═╡ b984a1f7-309f-47d2-b45d-43e32793419c
reset_button; message = Ref("Use the arrow buttons to move");

# ╔═╡ e34dd05b-6335-400a-98d5-a5ec53ff6fef
function step(a)
	if enable_shield && !allows(shield, state[], a)
		message[] = "🛡️ Not allowed! 🛡️"
		return
	end
	new_state = f(state[], a)
	old_state = state[]
	state[] = new_state
	message[] = "Taking a step... ($old_state, $a, $new_state)"
	nothing
end;

# ╔═╡ 227044c6-7688-4286-ab29-5a78b1f1ad9e
if up_button > 0
	step(:↑)
end; 🎈1 = "🎈";

# ╔═╡ fa319c0e-7730-445c-8cdb-7df500a41a48
if down_button > 0
	step(:↓)
end; 🎈2 = "🎈";

# ╔═╡ 123b7ba1-38af-4915-b1b7-4c91a8136b61
if left_button > 0
	step(:←)
end; 🎈3 = "🎈";

# ╔═╡ 4c9bce7f-a55d-4315-b128-aef21acf15bc
if right_button > 0
	step(:→)
end; 🎈4 = "🎈";

# ╔═╡ 13770f69-5f0c-4655-b639-e563c4274294
🎈1, 🎈2, 🎈3, 🎈4; md"Current state: **$(state[])**"

# ╔═╡ b6c02da8-4147-4600-8683-422b114d7ebb
let
	🎈1, 🎈2, 🎈3, 🎈4
	
	plot(title=message[],
		 titlefont="Helvetica",
		 xticks=nothing,
		 yticks=nothing,
		 xlim=(0, 4),
		 ylim=(0, 4),
		 yflip=true,
		 aspectratio=:equal,
		 axis=([], false))

	hline!(0:4, width=1, color=:gray, label=nothing)
	vline!(0:4, width=1, color=:gray, label=nothing)
	
	for x in 1:4, y in 1:4
		annotate!(y - 0.80, x - 0.90, text("$(S[x, y])", 10))
	end

	for 🧊′ in 🧊
		x, y = indexof(🧊′)
		annotate!(y - 0.50, x - 0.50, text("⁣🧊", 30, "Helvetica"))
	end

	x, y = indexof(💀)
	if state[] == 💀
		annotate!(y - 0.75, x - 0.70, text("⁣💀", 20, "Helvetica"))
	else
		annotate!(y - 0.50, x - 0.50, text("⁣💀", 30, "Helvetica"))
	end

	x, y = indexof(🏁)
	if state[] == 🏁
		annotate!(y - 0.70, x - 0.70, text("⁣🏁", 20, "Helvetica"))
	else
		annotate!(y - 0.50, x - 0.50, text("⁣🏁", 30, "Helvetica"))
	end

	x, y = indexof(state[])
	annotate!(y - 0.50, x - 0.50, text("⁣🤖", 30, "Helvetica"))

	plot!()
end

# ╔═╡ 66dd9d38-7ef7-4b4c-805b-d26f21f2859f
md"""
## Shielded Q-learning
Re-visiting the Q-learning code from our other notebook.

Instead of considering the full action space, we only choose from allowed actions `🛡️(s)`.

This is achieved by two modifications to the algorithm.

1. Modifying the function `ϵ_greedy` to choose only from `🛡️(s)` during exploration.
2. Modifying the initial $Q(s, a)$ values such that 
$Q(s, a) = \begin{cases}
	0.0 ~\text{ if }~ a \in 🛡️(s)\\
	-\infty
\end{cases}$
"""

# ╔═╡ 36a8f83d-20fd-450d-bbae-aae7fc909580
md"""
**Shielded Learning** $(@bind shielded_learning CheckBox(default = true))
"""

# ╔═╡ f7e8d34a-a02b-4f91-9b1e-8785ecb52768
if shielded_learning
	🛡️(s) = allowed(shield, s) # Shielded actions
else
	🛡️(s) = A
end

# ╔═╡ 7fa924a2-e89b-488c-8f46-c6067eede854
# ϵ-greedy choice from Q.
function ϵ_greedy(ϵ::Number, Q, s)
	if rand(Uniform(0, 1)) < ϵ
		return rand(🛡️(s))
	else
		return argmax((a) -> Q[s, a], A)
	end
end

# ╔═╡ 99f0398d-2e8f-4835-be1d-b0f4bbd7ebdf
∞ = Inf

# ╔═╡ 218cbaf2-175e-477e-815e-706d95cbfec2
# Initializing Q-values using the shield. 
# Unsafe actions have an expected reward of -∞.
# Note also that it's important for the Q-updates that the terminal states are zero
Q_init = Dict{Tuple{Int64, Symbol}, Float64}(
	(s, a) => a ∈ 🛡️(s) ? 0.0 : -∞
	for s in S, a in A
)

# ╔═╡ fbce7689-eb9d-4120-8d3d-6a01e66cb4fe
@bind ϵ_base NumberField(0.0001:0.0001:1, default=0.1)

# ╔═╡ 073098a8-0ee4-4817-ae8b-0a6a8ba3804f
@bind α_base NumberField(0.0001:0.0001:1, default=0.1)

# ╔═╡ 4883874d-c0e8-4984-be4d-a4c082367f74
# Episode max length
@bind T NumberField(1:typemax(Int64), default=1000)

# ╔═╡ 5eda40c9-f10c-4a12-a458-e76d844e7419
@bind γ NumberField(0.0001:0.0001:1, default=0.99)

# ╔═╡ 135a5791-f61d-48a9-9e31-fabfb72c0e69
[ϵ_greedy(0.2, Q_init, 1) for _ in 1:10]

# ╔═╡ 466621e0-9448-46d6-bff5-de76ff0e25e5
md"""
### This is Where Training Happens
"""

# ╔═╡ d2f6ea71-2b10-4816-bade-d66565cdd73a
@bind episodes NumberField(0:typemax(Int64), default=5)

# ╔═╡ f6345e37-c257-491c-9a35-820c62a18c86
function ϵ(t; episodes=episodes)
	#return ϵ_base
	if t < episodes/2
		ϵ_base
	else
		ϵ_base/(1 + 0.01*(t - episodes/2))
	end
end

# ╔═╡ 2641f88e-d3a6-4cc1-b9a9-dd651c850a16
function α(t; episodes=episodes)
	if t < episodes/2
		α_base
	else
		α_base/(1 + 0.01*(t - episodes/2))
	end
end

# ╔═╡ 1170955f-c3fe-47fd-8e01-af6bccd7a6a5
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

# ╔═╡ 167769f4-024b-44ce-b3bf-a94b3d2a5006
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
			push!(ξ, (Sₜ₊₁, A[1], 0))
			return Σr, ξ
		end
		
		Sₜ, Aₜ = Sₜ₊₁, Aₜ₊₁
	end
	return Σr, ξ
end

# ╔═╡ c6c020d2-3f0e-4764-9d86-d6d8a202113a
function Q_learn!(Q)
	rewards = []
	traces = []
	
	@progress for i ∈ 1:episodes
		R, ξ = Q_episode!(Q, i)
		push!(rewards, R)
		push!(traces, ξ)
	end

	return rewards, traces
end

# ╔═╡ b430b41a-23e4-4bc1-afd9-5fe08f8bd52b
ϵ(episodes)

# ╔═╡ 525f5979-c0e4-46ef-aa35-1232d1d2c17b
begin
	Q = copy(Q_init)
	rewards, traces = Q_learn!(Q)
end

# ╔═╡ c53ca4b4-4d7d-4ee2-b86b-fbd696f98547
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

# ╔═╡ 58e6adbf-e43b-4352-b3f6-3128bf89c573
md"""
### Evaluating safety
The following loop checks every training episodes, to see if state 15 💀 is entered. (This will be the last state in the trace but all states are checked for good measure.)

It prints out erros when an unsafe episode was produced during training, and outputs "👍" otherwise. Try un-checking the [Shielded Learning](#Shielded-Q-learning) option to see some unsafe episodes.
"""

# ╔═╡ 76249b97-8022-482a-be78-930b9fc22aa0
let
	any_unsafe = false
	for ξ in traces
		for (S, a, S′) in ξ
			if !is_safe(S)
				@error "Unsafe state reached!" S ξ
				any_unsafe = true
			end
		end
	end
	if !any_unsafe
		"All episodes were safe 👍"
	end
end

# ╔═╡ e8c15e5a-1282-4f6a-927f-fd00e19e200d
md"""
### V-table
Visualization showing the best value V for every state, and the corresponding actions.
"""

# ╔═╡ 9cde860e-9aa8-4a9f-90d1-5932928878ea
best_a(Q, s) = argmax(a -> Q[s, a], A)

# ╔═╡ 8eb6eca4-2ae5-41ae-9796-09dc7c25a8be
V = [Q[s, best_a(Q, s)] for s in S]

# ╔═╡ 3e17f889-ffc5-4fd1-8853-940a3dd64d86
let
	
	
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

# ╔═╡ Cell order:
# ╠═42548379-376c-45fc-b2e2-fd3b4fc51872
# ╟─c6f38301-5eb7-4e98-bafd-6a0bcd2fb1b6
# ╠═0f6f658f-56a3-4de3-b1ef-0c3de76a2d37
# ╟─8ab142ac-2bb9-42fd-bb52-781a3bdee3f9
# ╠═7c634330-d307-4f32-9649-a79c849c12af
# ╠═a5bba2c0-d04d-4995-b55a-3e1928b7da62
# ╠═aeb428b9-0727-4a21-b4ec-91c3972ff0cf
# ╟─4de87d0d-b485-4e2c-afd9-137bde99e79c
# ╠═cd7ae301-9eec-4921-9d08-dd809093cc8e
# ╠═22363ada-9450-449f-90c5-4abba2a3e7b1
# ╠═aa81e27a-b248-45bb-ab1c-9c6e3ac1aa24
# ╠═a832de86-2f9f-43b8-b379-f17a6109b50b
# ╠═5468e72e-bf32-4ca8-a9b7-579aaef265e0
# ╠═a4fc59ad-af31-4644-b716-868ac21b996a
# ╠═54fbe43e-eb61-4630-82e7-9c4c0c5c8b86
# ╠═39872b3f-ffe0-4bce-9686-e4bd142da607
# ╠═3115ec67-977f-495a-a55c-9be13129dbfd
# ╠═73030552-c725-4829-9583-23a89b592a9a
# ╠═2342191b-1d65-4f3c-b118-e38085fbcab7
# ╠═c93b9adf-b4df-4755-94c6-4eade5c75b2e
# ╠═1799ddea-cf99-4736-9008-80fe4b621145
# ╠═95c8ce15-7a1e-4060-a418-0ece089e66aa
# ╠═713e8cdb-1d9f-4e8e-8b05-71d14c047f73
# ╟─2a754cfb-a824-4fbb-999b-27e2b1439e1f
# ╠═6455a04a-3729-44cd-a9c9-2109706f794a
# ╠═d5eedc70-c808-474d-b8e2-98f87bb21d7f
# ╠═30e8d819-fbc2-4e60-90fc-6882925fc833
# ╠═0ce51653-1f4b-451f-b8b3-d5b0480707af
# ╠═3fb26ecf-d11e-404a-ab16-08676b81d124
# ╟─952a7f42-364a-460f-bbde-c13239d55459
# ╠═eac046eb-392d-4a84-bc6a-837480a76765
# ╠═fa05187e-3f6a-437a-853d-93b29c352782
# ╠═9c61cada-df4a-49d0-93d4-45d3a7bae866
# ╠═d37c80b0-0cef-42aa-a878-ade06954f442
# ╠═060c4170-aba1-4b1b-9710-86beb904a602
# ╠═0af99598-9e2a-494e-b2e9-0d3911670900
# ╠═d48f7d1c-3aee-4f96-92cd-34925bd8abf8
# ╠═0ae4c6af-cfa1-4a4e-abb7-7e7db97698a5
# ╟─fc61b87d-9097-44cb-ab8b-8d3b3db98a43
# ╠═57cd2a0d-3462-4924-8198-af907c763074
# ╠═ec0c414f-1c6a-4a2d-99cf-468fa617f36b
# ╟─403a5a86-1fb8-498b-bd83-a418f9165fa3
# ╟─b7c00112-ebe4-454e-a35a-7ba4e19ba9ea
# ╠═cc49eb4b-7393-49e8-84ad-167f3853f4f3
# ╠═312adb87-4ad8-4d98-b751-b49a1dfde418
# ╠═20328a59-110e-4cd9-a02e-f5eb197d5ae7
# ╠═3ac3936c-c011-42f2-a8d3-f2b590b60a82
# ╠═ea419be2-1b1e-40f2-b823-673a4c38f543
# ╟─8a78e939-8005-4eb1-b072-5d4c427cbc3a
# ╟─ba1aad2e-2928-483d-a3cd-4c2da6aa8d94
# ╟─c5e1c1bc-f127-42a7-bb63-ca6c83d126c3
# ╟─13770f69-5f0c-4655-b639-e563c4274294
# ╟─ac78e8c6-202a-42e9-88c7-aa4a3bacbb4b
# ╟─b6c02da8-4147-4600-8683-422b114d7ebb
# ╟─e34dd05b-6335-400a-98d5-a5ec53ff6fef
# ╟─bfbb7e69-96aa-4c45-8401-61e9e3044d86
# ╟─227044c6-7688-4286-ab29-5a78b1f1ad9e
# ╟─fa319c0e-7730-445c-8cdb-7df500a41a48
# ╟─123b7ba1-38af-4915-b1b7-4c91a8136b61
# ╟─4c9bce7f-a55d-4315-b128-aef21acf15bc
# ╟─b984a1f7-309f-47d2-b45d-43e32793419c
# ╟─66dd9d38-7ef7-4b4c-805b-d26f21f2859f
# ╟─36a8f83d-20fd-450d-bbae-aae7fc909580
# ╠═f7e8d34a-a02b-4f91-9b1e-8785ecb52768
# ╠═7fa924a2-e89b-488c-8f46-c6067eede854
# ╠═99f0398d-2e8f-4835-be1d-b0f4bbd7ebdf
# ╠═218cbaf2-175e-477e-815e-706d95cbfec2
# ╠═fbce7689-eb9d-4120-8d3d-6a01e66cb4fe
# ╠═073098a8-0ee4-4817-ae8b-0a6a8ba3804f
# ╠═4883874d-c0e8-4984-be4d-a4c082367f74
# ╠═5eda40c9-f10c-4a12-a458-e76d844e7419
# ╠═135a5791-f61d-48a9-9e31-fabfb72c0e69
# ╠═f6345e37-c257-491c-9a35-820c62a18c86
# ╠═2641f88e-d3a6-4cc1-b9a9-dd651c850a16
# ╠═1170955f-c3fe-47fd-8e01-af6bccd7a6a5
# ╠═c6c020d2-3f0e-4764-9d86-d6d8a202113a
# ╠═167769f4-024b-44ce-b3bf-a94b3d2a5006
# ╟─466621e0-9448-46d6-bff5-de76ff0e25e5
# ╠═d2f6ea71-2b10-4816-bade-d66565cdd73a
# ╠═b430b41a-23e4-4bc1-afd9-5fe08f8bd52b
# ╠═525f5979-c0e4-46ef-aa35-1232d1d2c17b
# ╟─c53ca4b4-4d7d-4ee2-b86b-fbd696f98547
# ╟─58e6adbf-e43b-4352-b3f6-3128bf89c573
# ╠═76249b97-8022-482a-be78-930b9fc22aa0
# ╟─e8c15e5a-1282-4f6a-927f-fd00e19e200d
# ╠═9cde860e-9aa8-4a9f-90d1-5932928878ea
# ╠═8eb6eca4-2ae5-41ae-9796-09dc7c25a8be
# ╟─3e17f889-ffc5-4fd1-8853-940a3dd64d86

### A Pluto.jl notebook ###
# v0.17.1

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
end

# ╔═╡ 67ee00e0-3eb0-11ec-1402-c947ac4f59c9
begin
	import Pkg
	Pkg.activate(".")
end

# ╔═╡ f61a8e84-9c65-4df8-a630-7a1a3982fb02
begin
	using Unitful
	using DifferentialEquations
	using Plots
	using XLSX
	using DataFrames
	using LinearAlgebra
	using PlutoUI
end

# ╔═╡ 016c1497-d159-4c74-9a8e-344d5b18cee3
md"""
# Analyzing OR sims
We want to take the simulation table of our rocket's simulation with no airbrake deployment (should be exported to a .xlsx file for ease) and run various tests on them.

For example, an important goal for our airbrakes is to be able to predict the projected apogee of the rocket while it is flying. Open Rocket gives us a really good idea of how we will be recieving data mid-flight, so we can test out various altitude models. We can also try to verify $C_f$ coefficients found from CFD simulation analysis for rocket with no airbrakes.

When we get actual flight data, we might even be able to use code snippets from this notebook to analyze that data to find the $C_f$ of the airbrakes as a function of angle of deployment and various other factors needed to predict airbrake usage.
"""

# ╔═╡ 21acb136-8faa-439c-b217-e3f3083c9a6b
md"""
## Predicting Projected Altitude

The simplest differential I can come up with for projected altitude is as follows:

$$\ddot{x}_z = -u_zC_f \cdot \begin{bmatrix} 1 \\ \lVert\dot{x}\rVert \\ \lVert\dot{x}\rVert^2 \end{bmatrix} - g$$

$C_f = C_{fr} + C_{fa}(\theta)$
where $\vec{u}$ is the unit vector of the rocket's orientation in space from the reference point of a straight launch rod (we should define a common coordinate system), $C_f$ is a column vector of the coefficients found in our CFD analysis. As you can see, the $C_f$ of the rocket (denoted by $C_{fr}$) is a constant while the $C_f$ of the airbrakes (denoted by $C_{fa}$) is a function of $\theta$, the angle that the airbrakes are deployed at.

We can try this out, but I suspect some shortcomings. Here's one: as the rocket slows down, the air continues rotating the rocket to keep it in parallel with the relative velocity of the air from the reference frame of the rocket *(why this happens is explained in detail in the OR master's thesis at the beginning. If this becomes a problem, we might be able to reference it)*.

### Predicting acceleration
Before using differential equation solver, we need to make sure that the $\ddot{x}_z$ our equation gives us matches up with what the Open Rocket simulation sees. Of course, we don't have $C_f$ of the rocket yet, but all we need to see for now is that we can play around with the $C_f$ coefficients in some way that will line up our preditcted acceleration and the actual acceleration in the simulation

"""

# ╔═╡ 97d71bb2-adf5-4ce2-8f22-f4e2d8ee3db9
drag_force(u_z, C_f, total_vel, g) = -u_z * dot(C_f, [1, total_vel, total_vel^2]) - g;
# The formula

# ╔═╡ 0ee2bfa6-a231-4afc-9794-cdfc7fc2537d
md"""
 $C_f$ works like this: It is a vector of the coefficients of the quadratic function describing the relationship between velocity and the drag force*.

$m\ddot{x} = C_{f1} + C_{f2}\lVert{\dot{x}}\rVert + C_{f3}\lVert{\ddot{x}}\rVert^2$

$C_f = \begin{bmatrix} C_{f1} \\ C_{f2} \\ C_{f3} \end{bmatrix}$


*Though we are solving for acceleration here, there shouldn't be much of a difference since we are only looking for the shape to match up. We will need to switch over to solving for force once we get actual $C_f$ coefficients (or you can change that now if you wanted).
"""

# ╔═╡ ca0fc408-3a8a-45b3-af5d-cc5730e4563a
@bind C_f1 Slider(-1:.01:1, default=0, show_value=true)

# ╔═╡ 2a1cafca-f24c-4532-a7c8-7df629d129bb
@bind C_f2 Slider(-1:.01:1, default=0, show_value=true)

# ╔═╡ 619f04ac-b911-40a0-b876-a7485b9f77f7
@bind C_f3 Slider(-1:.01:1, default=0, show_value=true)

# ╔═╡ 75445115-cdb7-4e10-a966-715700261654
begin
	C_f = [C_f1, C_f2, C_f3]
	burnout_t = 2.6265 # Will need to detect
	apogee_t = 8.315 # Will need to detect

	C_f
end;

# ╔═╡ 4c00a2fb-0be4-43d7-a150-29ae188b6724
md"""
The simulation we will be using has been exported to `sim-(F26FJ-6)-304m.xlsx`. The default sheet contains the data as Open Rocket exported it, while the `raw-data` sheet is simply the default sheet without any of the "comments".
"""

# ╔═╡ 69aadc27-2894-4a27-8e22-ebc8f544dd5a
flight_data = DataFrame(XLSX.readtable("sim-(F26FJ-6)-304m.xlsx", "raw-data")...);

# creates a dataframe from the table in raw-data sheet

# ╔═╡ 21c7d27c-9ef7-4a4f-a4a3-9ceb31a72ca6
begin
	drag_frame = DataFrame(Time = Float64[], Vertical_Acceleration = Float64[])
	
	for (index, t) in enumerate(flight_data[!, "Time (s)"])
		if t >= burnout_t && t <= apogee_t
			u_z = sin(flight_data[index, "Vertical orientation (zenith) (°)"] * π/180)
			total_vel = flight_data[index, "Total velocity (m/s)"]
			g = total_vel = flight_data[index, "Gravitational acceleration (m/s²)"]
			push!(drag_frame, (t, drag_force(u_z, C_f, total_vel, g)))
		end
	end
end

# drag_frame
# Builds dataframe of our predicted acceleration for each point in time of the simulation

# ╔═╡ c1a8aef6-8d82-4491-a22e-b98331536175
begin
	gr()
	plot(flight_data[!, "Time (s)"], flight_data[!, "Vertical acceleration (m/s²)"])
	plot!(drag_frame[!, "Time"], drag_frame[!, "Vertical_Acceleration"])

	# If the code works, we should see the orange line match up with the blue line
	
	#= 
	Clearly, it's not, but it should. I know this because on the excel file,
	I graphed velocity vs drag force. And it gave me a quadratic curve-- exactly
	what we are expecting. And when I graphed drag force vs vertical acceleration,
	it gave me a linear curve for the part of the data we are concerned with--
	also in line with what we expect.

	So there must be a bug somewhere in the code because it seems that no matter how
	I alter the coefficients, I can never get it to fit simulation data.
	=#
end

# ╔═╡ Cell order:
# ╟─67ee00e0-3eb0-11ec-1402-c947ac4f59c9
# ╟─f61a8e84-9c65-4df8-a630-7a1a3982fb02
# ╟─016c1497-d159-4c74-9a8e-344d5b18cee3
# ╟─21acb136-8faa-439c-b217-e3f3083c9a6b
# ╠═97d71bb2-adf5-4ce2-8f22-f4e2d8ee3db9
# ╟─0ee2bfa6-a231-4afc-9794-cdfc7fc2537d
# ╠═ca0fc408-3a8a-45b3-af5d-cc5730e4563a
# ╠═2a1cafca-f24c-4532-a7c8-7df629d129bb
# ╠═619f04ac-b911-40a0-b876-a7485b9f77f7
# ╠═75445115-cdb7-4e10-a966-715700261654
# ╟─4c00a2fb-0be4-43d7-a150-29ae188b6724
# ╠═69aadc27-2894-4a27-8e22-ebc8f544dd5a
# ╠═21c7d27c-9ef7-4a4f-a4a3-9ceb31a72ca6
# ╠═c1a8aef6-8d82-4491-a22e-b98331536175

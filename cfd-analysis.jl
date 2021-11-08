### A Pluto.jl notebook ###
# v0.17.1

using Markdown
using InteractiveUtils

# ╔═╡ 21c84770-3fef-11ec-2af4-235119fd56e7
begin
	import Pkg
	Pkg.activate(".")
end

# ╔═╡ 7ab69e8c-048c-4c44-ada7-693c3d58ab99
begin
	using XLSX
	using DataFrames
	using Plots
	using Polynomials
	using GLM
end

# ╔═╡ 99382399-4311-44f7-b636-609832b2e4bb
md"""

# CFD Analysis

The point of this notebook is to be able to analyze CFD data to determine the $C_f$. In this particular example, we are determining the $C_f$ of fully deployed airbrakes. As you will see $C_f$ will be expressed as a quadratic with velocity as the input. This should match our data very closely.

This is obtained in a very intuitive manner. This method can be expanded to finding the $C_d$ of other things including our rocket itself as well as the $C_d$ of various angles of airbrake deployments (although the CFD will be very computationally intensive if we need to run simulations for each angle, so this shold be a last resort)

"""

# ╔═╡ d1acb72a-a833-41cf-8a37-c0efc9086e43
md"""
## Sample Calculations

Here are some sample values velocity v.s. total force values that I wrote in `vel-drag_sample.xlsx`. When we are analyzing our real data, make sure to express the numbers as floats so that XLSX can automatically infer types. (have decimals)

"""

# ╔═╡ 0034e1a8-f727-4409-b14b-29e0c3950759
vel_drag = DataFrame(XLSX.readtable("vel-drag_sample.xlsx", 1; infer_eltypes=true)...);

# ╔═╡ ee790fb1-5465-438a-aebd-af02201f9ca6
md"""

Here is the plot of added\_force v.s. velocity. You can already see a quadratic relationship which is a good sign that we will be able to determine $C_f$ . Looking at the Open Rocket data for some of our simulations, I also saw a relationship like this, so hopefully we can expect to see this within our CFD simulations and test-flights

"""

# ╔═╡ 74427133-9cd3-49e6-bc22-e5075279e548
begin
	x = vel_drag[!, "velocity"]
	y = vel_drag[!, "added_force"]
	
	plot(x, y)
	plot!(xlabel="velocity", ylabel="added_force")
end

# ╔═╡ 71570653-4866-418b-bb96-78af83a7efbf
md"""
Here is the quadratic equation that best fits our data. We might be able to ignore the y-intercept as it doesn't have much real-world significance.
"""

# ╔═╡ 96d6823c-5612-4bd6-aa91-4017bf290e56
f = Polynomials.fit(x, y, 2)

# ╔═╡ d3cee260-47a1-40bf-882a-57480e321751
md"""
Plotting the polynomial over our data, we can see that there is a very close match. This is obviously what we want to see with our data.
"""

# ╔═╡ db7f51dd-43ce-4ae2-9baf-e545aa1de137
begin
	scatter(x, y, markerstrokewidth=0, label="Data")
	plot!(f, extrema(x)..., label="Fit")
	plot!(xlabel="velocity", ylabel="added_force")
end

# ╔═╡ 3049354f-25b3-444a-a7a3-ffb6db39c337
md"""
#### Details for stats nerds
---
"""

# ╔═╡ d690b30b-73a4-4cb8-bb6a-6bbfec6bd87f
regression = lm(@formula(f(velocity) ~ added_force), vel_drag)

# ╔═╡ 4505c927-2d37-4582-965d-1415df01496f
r2(regression)

# ╔═╡ Cell order:
# ╟─21c84770-3fef-11ec-2af4-235119fd56e7
# ╟─7ab69e8c-048c-4c44-ada7-693c3d58ab99
# ╟─99382399-4311-44f7-b636-609832b2e4bb
# ╟─d1acb72a-a833-41cf-8a37-c0efc9086e43
# ╠═0034e1a8-f727-4409-b14b-29e0c3950759
# ╟─ee790fb1-5465-438a-aebd-af02201f9ca6
# ╠═74427133-9cd3-49e6-bc22-e5075279e548
# ╟─71570653-4866-418b-bb96-78af83a7efbf
# ╠═96d6823c-5612-4bd6-aa91-4017bf290e56
# ╟─d3cee260-47a1-40bf-882a-57480e321751
# ╠═db7f51dd-43ce-4ae2-9baf-e545aa1de137
# ╟─3049354f-25b3-444a-a7a3-ffb6db39c337
# ╠═d690b30b-73a4-4cb8-bb6a-6bbfec6bd87f
# ╠═4505c927-2d37-4582-965d-1415df01496f

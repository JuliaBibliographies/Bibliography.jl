### A Pluto.jl notebook ###
# v1.0.0

# ╔═╡ 41dbb952-51ff-4edb-bb60-5b75a58da62d
begin
    include(joinpath(@__DIR__, "bootstrap.jl"))
    using JSON
    using PerfChecker
end

# ╔═╡ 4531fb5a-74fd-45b7-867a-94447193d561
result_path = joinpath(@__DIR__, "results", "quick", "suite-result.json")

# ╔═╡ 97a4d99b-afc1-4c64-8d58-0dbe9e02fe25
run_suite_now = false

# ╔═╡ 32a629a1-e320-4025-b47a-f131149ddc1e
job = run_suite_now ?
      launch_suite(
    load_software_suite(joinpath(@__DIR__, "entrypoint.jl")); profile = :quick) : nothing

# ╔═╡ e65d45fb-3452-42b7-919e-f999f0dc3ccc
job_progress = job === nothing ? nothing : suite_job_progress(job)

# ╔═╡ e91b2020-4eb7-40a8-a3f5-165aa7a195ad
progress_bar = if job_progress === nothing
    "No job running"
else
    width = 30
    filled = round(Int, width * job_progress["fraction"])
    "[" * repeat("█", filled) * repeat("░", width - filled) * "] " *
    "$(job_progress["completed"])/$(job_progress["total"])"
end

# ╔═╡ 028d8c89-440d-4716-bd43-37590b0be870
job_result = job === nothing || suite_job_status(job) ∉ (:complete, :failed) ?
             nothing : wait_suite(job; strict = false)

# ╔═╡ fa2e2a77-d688-43fd-bc2a-d85732c0318e
report = job_result !== nothing ? suite_dict(job_result) :
         isfile(result_path) ? JSON.parsefile(result_path) :
         Dict(
    "status" => "missing", "message" => "Set run_suite_now=true to launch workers.")

# ╔═╡ cfdc9952-89e9-40fc-a656-bf0519ef0484
runs = get(report, "runs", Any[])

# ╔═╡ Cell order:
# ╠═41dbb952-51ff-4edb-bb60-5b75a58da62d
# ╠═4531fb5a-74fd-45b7-867a-94447193d561
# ╠═97a4d99b-afc1-4c64-8d58-0dbe9e02fe25
# ╠═32a629a1-e320-4025-b47a-f131149ddc1e
# ╠═e65d45fb-3452-42b7-919e-f999f0dc3ccc
# ╠═e91b2020-4eb7-40a8-a3f5-165aa7a195ad
# ╠═028d8c89-440d-4716-bd43-37590b0be870
# ╠═fa2e2a77-d688-43fd-bc2a-d85732c0318e
# ╠═cfdc9952-89e9-40fc-a656-bf0519ef0484

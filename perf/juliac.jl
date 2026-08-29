root = normpath(joinpath(@__DIR__, ".."))
juliac = normpath(joinpath(Sys.BINDIR, "..", "share", "julia", "juliac", "juliac.jl"))
isfile(juliac) || error("This Julia installation does not provide juliac.jl")

trim = isempty(ARGS) ? "no" : only(ARGS)
trim in ("no", "safe", "unsafe", "unsafe-warn") ||
    throw(ArgumentError("trim must be no, safe, unsafe, or unsafe-warn"))

output_dir = joinpath(@__DIR__, "results", "juliac")
mkpath(output_dir)
executable = joinpath(output_dir, "bibliography-smoke" * (Sys.iswindows() ? ".exe" : ""))
entrypoint = joinpath(@__DIR__, "juliac_smoke.jl")

command = `$(Base.julia_cmd()) --startup-file=no --project=$root $juliac --output-exe $executable --experimental --trim=$trim $entrypoint`
run(command)

executable_command = `$executable`
if Sys.iswindows()
    executable_command = addenv(
        executable_command, "PATH" => string(Sys.BINDIR, ';', ENV["PATH"]))
end
success(executable_command) || error("JuliaC smoke executable failed")
println("JuliaC smoke passed: $executable")

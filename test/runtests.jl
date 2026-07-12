using Bibliography
using BibInternal
using EzXML
using JSON3

using Aqua
using ExplicitImports
using JET
using Logging: NullLogger, with_logger
using Test
using TestItemRunner

with_logger(NullLogger()) do
    @testset "Bibliography.jl" begin
        include("internal.jl")
        include("Aqua.jl")
        include("ExplicitImports.jl")
        include("JET.jl")
        include("TestItemRunner.jl")
    end
end

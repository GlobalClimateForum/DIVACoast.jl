cd(@__DIR__)
include("../src/DIVACoast.jl")
using .DIVACoast
using Logging
using Test

# Get all test files, except excluded ones
excluded = Set(["runtests.jl", "test_hsps_df.jl", "test_damages.jl", "test_io.jl"])
tests = [file for file in readdir() if endswith(file, ".jl") && file ∉ excluded]

tests = ["test_exposure.jl"]
#run tests
for test in tests
    Main.global_logger(DIVALogger())
    @info "DIVACoast-Test: $test"
    include("./$(test)")
end
cd(@__DIR__)
include("../src/DIVACoast.jl")
using .DIVACoast
using Logging
# Get all test files
tests = [file for file in readdir() if file != "runtests.jl" && endswith(file, ".jl")]

# Include all test files
for test in tests
    Main.global_logger(DIVALogger())
    @info "DIVACoast-Test: $test"
    include("./$(test)")
end
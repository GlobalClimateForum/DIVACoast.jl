# Inside make.jl
include("./../src/jdiva_lib.jl")
push!(LOAD_PATH,"../src/")

using .jdiva
using Documenter

makedocs(
    sitename = "jdiva",
    modules  = [jdiva],
    remotes = nothing,
    pages=["Home" => "index.md"]
    )
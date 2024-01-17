# Inside make.jl
include("./../src/jdiva_lib.jl")
push!(LOAD_PATH,"../src/")

using .jdiva
using Documenter

makedocs(
    authors="Daniel Lincke et al <daniel.lincke@globalclimateforum.org>",
    sitename = "jdiva",
    modules  = [jdiva],
    remotes = nothing,
    pages=["Home" => "index.md"],
    format = Documenter.HTML(
        prettyurls = false,
#        repolink="https://globalclimateforum.gitlab.io/diva_library/",)
        repolink="https://gitlab.com/globalclimateforum/diva_library",)
    )
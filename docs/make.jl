# Inside make.jl
include("./../src/jdiva_lib.jl")
push!(LOAD_PATH, "../src/")

import .jdiva
using Documenter

makedocs(
    authors="Daniel Lincke et al <daniel.lincke@globalclimateforum.org>",
    sitename="jdiva docs",
    modules=[jdiva],
    remotes=nothing,
    # pages=["Home" => "index.md"],
    format=Documenter.HTML(
        prettyurls=false,
        repolink="https://gitlab.com/globalclimateforum/diva_library",
        collapselevel=1
    )
)
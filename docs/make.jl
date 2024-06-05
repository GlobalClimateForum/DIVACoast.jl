# Inside make.jl
include("./../src/jdiva_lib.jl")
push!(LOAD_PATH,"../src/")

import .jdiva
using Documenter

makedocs(
    authors="Daniel Lincke et al <daniel.lincke@globalclimateforum.org>",
    # sitename = "jdiva",
    modules  = [jdiva],
    remotes = nothing,
    pages=["Home" => "index.md"],
    format = Documenter.HTML(
        prettyurls = false,
#        repolink="https://globalclimateforum.gitlab.io/diva_library/",)
        repolink="https://gitlab.com/globalclimateforum/diva_library",)
    )

HTML(
    collapselevel = 1,
    description = "$sitename is a julia library for economic modelling of coastal sea-level rise impacts and adaptation. It provides a complete tool chain from geodatatypes to datatypes that allow different approaches of coasplain modelling to algorithms that compute flood impacts, erosion and wetland change."
)
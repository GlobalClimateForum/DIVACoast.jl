using Pkg
Pkg.activate("../.")
Pkg.instantiate()

include("../src/DIVACoast.jl")
using .DIVACoast
using Documenter

makedocs(
    authors="Daniel Lincke et al <daniel.lincke@globalclimateforum.org>",
    sitename="DIVACoast.jl Documentation",
    checkdocs = :none,
    modules=[],
    remotes=nothing,
    pages=[
        "Home" => "index.md",
        "Flood Hazard" => "hazard.md",
        "Flood Exposure" =>"exposure.md",
        "Flood Damage" => "damage.md",
        "Drivers" => "drivers.md",
        "Coastal Models" => "coastalmodels.md",
        "GeoData" => "geodata.md", ],
    format=Documenter.HTML(
        prettyurls=false,
        repolink="https://gitlab.com/globalclimateforum/DIVACoast.jl",
    )
)

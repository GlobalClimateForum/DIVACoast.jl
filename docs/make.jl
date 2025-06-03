using Pkg
Pkg.add("Documenter")
using Documenter

include("../src/DIVACoast.jl")
using .DIVACoast

makedocs(
    authors="Daniel Lincke et al <daniel.lincke@globalclimateforum.org>",
    sitename="DIVACoast.jl Docs",
    checkdocs = :none,
    modules=[DIVACoast],
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
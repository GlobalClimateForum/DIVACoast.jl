# Inside make.jl
# include("$(ENV["DIVA_LIB"])/src/DIVACoast.jl")
# push!(LOAD_PATH, "../src/")

# import .DIVACoast
using Documenter

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
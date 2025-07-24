using Pkg
Pkg.activate("$(ENV["DIVA_LIB"])")
include("$(ENV["DIVA_LIB"])/src/DIVACoast.jl")
using .DIVACoast
using Plots
include("./../src/datatypes/spatial_flood_profile//test_profile.jl")
import ArchGDAL
using Rasters

fp = SpatialFloodProfile(Matrix{Float32}(reduce(hcat, elevation)), exposures = [Matrix{Float32}(reduce(hcat, assets))],  seed = CartesianIndex(25, 5))
fpmasks = SpatialFloodProfileMask(fp)

inun1 = inundate(fp, fpmasks, 2.0, HydraulicConnectedBathtub())
inun2 = inundate(fp, fpmasks, 2.0, PathBasedAttenuatedBathtub(0.2))
exp1 = exposure(fp, fpmasks, 2.0, HydraulicConnectedBathtub())
exp2 = exposure(fp, fpmasks, 2.0, PathBasedAttenuatedBathtub(0.1))


println("Exposure with HydraulicConnectedBathtub: ", exp1)
println("Exposure with PathBasedAttenuatedBathtub: ", exp2)

p1 = heatmap(inun1, c=[:transparent, :darkblue], colorbar=false, aspect_ratio=:equal, title="HydraulicConnectedBathtub")
p2 = heatmap(inun2, c=[:transparent, :darkblue], colorbar=false, aspect_ratio=:equal, title="PathBasedAttenuatedBathtub")
plot(p1, p2, layout = @layout([a b]), size=(1000,500), legend=false) |> display
readline()
exit()

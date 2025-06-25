using Pkg
Pkg.activate("$(ENV["DIVA_LIB"])")
include("$(ENV["DIVA_LIB"])/src/DIVACoast.jl")
using .DIVACoast
using Plots
include("./../src/datatypes/floodfillprofile//test_profile.jl")
using GDAL

netherlandsCopDEM = "../testdata/Netherlands/tif/netherlands_cop_dem.tif"



fp = elevation |> FloodProfile

# Init a FloodProfile
# fp = reduce(hcat, elevation) |> FloodProfile



dists, paths = dijkstra_fill(fp, CartesianIndex(25, 5),2)

# Plot the distances as a heatmap with discrete values
p1 = heatmap(fp.elevation, c=:lightterrain, colorbar=false, aspect_ratio=:equal, clims=(0, 6), title="Elevation")
p2 = heatmap(dists, c=:matter, colorbar=false, aspect_ratio=:equal, clims=(1, maximum(dists)), levels=unique(dists), title="Dijkstra Distance")
p3 = heatmap(paths, c=cgrad(:default, categorical = true), colorbar = false, aspect_ratio=:equal, title="Dijkstra Paths")



plot(p1, p2, p3, layout = (1, 3), size=(1200, 600), grid=false, axes=false, ticks=false)
savefig("2DFilling.png")
exit()
# Display dijkstra fill
# Display floodfill 
anim = @animate for i in 0:4
    flooded = flood_fill(fp, CartesianIndex(25, 5), i)

    # flooded_assets = count(fp.exposures[1][findall(flooded)])
    # println("Flooded assets at water level $i: $flooded_assets")

    # flooded_assets = count([fp.exposures[1][i] for i in findall(flooded)])

    if i == 0
        heatmap(fp.elevation, c=:terrain, colorbar=false, aspect_ratio=:equal)
        plot!(grid=false, axes=false, ticks=false)
    else
        flooded_masked = Float64.(flooded)
        flooded_masked[flooded_masked .== 0] .= NaN
        heatmap!(flooded_masked, c=:darkblue, colorbar=false, aspect_ratio=:equal, alpha = 0.5)
        plot!(grid=false, axes=false, ticks=false)
    end

end

gif(anim, "flood.gif", fps=1)

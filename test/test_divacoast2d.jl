using Pkg
Pkg.activate("$(ENV["DIVA_LIB"])")
include("$(ENV["DIVA_LIB"])/src/DIVACoast.jl")
using .DIVACoast
using Plots
include("./../src/datatypes/floodfillprofile//test_profile.jl")
import ArchGDAL
using Rasters

netherlandsCopDEM = joinpath(@__DIR__, "..", "testdata", "Netherlands", "tif", "netherlands_cop_dem.tif")


# function coord2index(coordinate::Tuple{Float64, Float64}, raster::Rasters.Raster)
#     xdim, ydim = Rasters.dims(raster)
#     xvals = Rasters.DimensionalData.values(xdim)
#     yvals = Rasters.DimensionalData.values(ydim)
#     x_index = findmin(abs.(xvals .- coordinate[1]))[2]
#     y_index = findmin(abs.(yvals .- coordinate[2]))[2]
#     return (x_index, y_index)
# end

# elevationRaster = Rasters.Raster(netherlandsCopDEM)
# elevationMatrix = Matrix{Float32}(elevationRaster)

# seed = (X = 4.405007, Y = 53.254938)
# seed_idx = coord2index((seed.X, seed.Y), elevationRaster)

# fp = FloodProfile(elevationMatrix, seavalue = 0.0f0, seed = CartesianIndex(seed_idx ...))

fp = SpatialFloodProfile(Matrix{Float32}(reduce(hcat, elevation)), exposures = [Matrix{Float32}(reduce(hcat, assets))], seavalue = 0.0f0, seed = CartesianIndex(25, 5))

dists, paths = dijkstra_fill(fp,2)

# Plot the distances as a heatmap with discrete values


p1 = heatmap(fp.elevation, c=:lightterrain, title="Elevation", colorbar = false , aspect_ratio = :equal)
p2 = heatmap(dists, c=:matter, colorbar=false, aspect_ratio=:equal, clims=(1, maximum(dists)), levels=unique(dists), title="Dijkstra Distance")
p3 = heatmap(paths, c=cgrad(:default, categorical = true), colorbar = false, aspect_ratio=:equal, title="Dijkstra Paths")

plot(p1, p2, p3, layout = (1, 3), size=(1200, 600), grid=false, showaxis = false, ticks=false)

savefig("dijkstra.png")

# Plot Flood Fill Animation
area_flooded = []
assets_flooded = []

assets_masked = Float32.(fp.exposures[1])
assets_masked[assets_masked .== 0] .= NaN

println(fp.width, " x ", fp.height)

anim = @animate for i in 0:6

    flooded = flood_fill(fp, CartesianIndex(25, 5), i)
    flooded_indices = findall(flooded)
    area = length(flooded_indices)
    assets = sum(fp.exposures[1][flooded_indices])

    println(assets, " -> ", area)

    push!(area_flooded, area)
    push!(assets_flooded, assets)

    flooded_masked = Float64.(flooded)
    flooded_masked[flooded_masked .== 0] .= NaN


    p1 = heatmap(fp.elevation, c=:terrain, grid=false, showaxis = false, ticks=false, legend=false)
    heatmap!(p1, flooded_masked, c=:darkblue, alpha = 0.5, colorbar=false, aspect_ratio=:equal, grid=false, showaxis = false)

    p2 = plot(0:i, area_flooded; xlabel="Waterlevel", ylabel="Pixel Flooded", lw=2, color=:blue,
        title="Hypsometric Profile", xlims=(0,6), xticks=0:1:6, ylims=(0,2500), yticks=0:300:2700, legend=false)
    p2_twin = twinx()
    plot!(p2_twin, 0:i, assets_flooded; ylabel="Assets Flooded", color=:red, lw=2, legend=false, ylims=(0,50), yticks=0:5:50)


    plot(p1, p2, layout = @layout([a b]), size=(1000,500), legend=false)
end


gif(anim, "flood.gif", fps=1)

using Pkg
Pkg.activate("$(ENV["DIVA_LIB"])")
include("$(ENV["DIVA_LIB"])/src/DIVACoast.jl")
using .DIVACoast
using Plots
using GeoArrays



datapath = (subdir) -> joinpath(ENV["DIVA_LIB"], "testdata/Netherlands/tif", subdir)

elev = "netherlands_cop_dem_aligned.tif" |> datapath |> GeoArrays.read
elev = elev[1400:1800, 400:800]

lc = "netherlands_copernicus_landcover_aligned.tif" |> datapath |> GeoArrays.read
lc = lc[1400:1800, 400:800]

lc_attr_mapping = Dict(
    10 => 0.5, # Tree
    20 => 0.2, # Shrubland
    30 => 0.25, # Grassland
    40 => 0.4, # Cropland
    50 => 0.25, # Herbaceous wetland
    60 => 0.5, # Mangroves
    70 => 0.25, # Moss and lichen
    80 => 0.25, # Bare / sparse Vegetation
    90 => 1.0, # Urban / Built-up
    100 => 0.0, # Permanent water bodies
    110 => 0.0, # Snow and ice 
    254 => 0.25, # No data / unclassifiable 
    )

# Define custom colors for each land cover class
lc_colors = Dict(
    10 => "#949d6a",   # Tree
    20 => "#adb993",   # Shrubland
    30 => "#d0d38f",   # Grassland
    40 => "#f6ca83",   # Cropland
    50 => "#419d78",   # Herbaceous wetland
    60 => "#226f54",   # Mangroves
    70 => "#419d78",   # Moss and lichen
    80 => "#add2b7",   # Bare / sparse Vegetation
    90 => "#db504a",   # Urban / Built-up
    100 => "#084c61",  # Permanent water bodies
    110 => "#d6e4eb",  # Snow and ice 
    254 => "#3f474f"   # No data / unclassifiable 
)

# Main 

test_elev = fill(0.1f0, size(elev) ...)
test_elev[400, 400] = 0f0
elev = test_elev # Overwrite Elevation with test data plain

plot_params = Dict(
    :aspect_ratio => :equal, 
    :titlefontsize => 8, 
    :grid => false, 
    :boxstyle => nothing
)

lc_plot = heatmap(lc; plot_params ...)

attrates = copy(lc) 

for (class, rate) in lc_attr_mapping
    attrates[lc .== class] .= rate
end

at_plot = heatmap(attrates.A;  plot_params ...)
lc_plot = plot(lc_plot, at_plot, layout = (1, 2), size=(1000, 500), legend=false)


fp = SpatialFloodProfile(elev, seed = CartesianIndex(400, 400))
fpMask = SpatialFloodProfileMask(fp)

inundation = inundate(fp, fpMask,  4.0, PathBasedAttenuatedBathtub(attrates))
inundation2 = inundate(fp,fpMask,  4.0, HydraulicConnectedBathtub())

in_plot = heatmap(inundation; c = cgrad(:devon, rev=true), plot_params ...)
elev_plot = heatmap(fp.elevation; c = cgrad(:lightterrain, rev=false), plot_params ...)
in_plot_2 = heatmap(inundation2; c = cgrad(:devon, rev=false), plot_params ...)

plot(in_plot, elev_plot, at_plot, in_plot_2, layout = (2, 2), size=(1500, 500), legend=false) |> display
readline()
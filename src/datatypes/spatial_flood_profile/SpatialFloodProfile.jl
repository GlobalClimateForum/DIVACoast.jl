using Plots
using DataStructures
include("./kernels.jl")
include("./test_profile.jl")

struct SpatialFloodProfile{T}
    elevation::Matrix{T}
    elevation_unit::String
    area_unit::String
    width::Int
    height::Int
    kernel::Kernel
    seed::CartesianIndex{2}
    exposures::Vector{Matrix{T}}
    exposure_names::Array{Union{String, Nothing}}
    exposure_units::Array{Union{String, Nothing}}
end

function SpatialFloodProfile(
    elevation::Matrix{T};
    elevation_unit::String="m",
    area_unit::String="km²",
    kernel::Kernel=Neighbour8(),
    seed::CartesianIndex{2}=CartesianIndex(1, 1),
    exposures::Vector{Matrix{T}}=Vector{Matrix{T}}(),
    exposure_names::Array{String} = String[],
    exposure_units::Array{String} = String[]
) where T

    width = size(elevation, 2)
    height = size(elevation, 1)
    
    return SpatialFloodProfile{T}(
        elevation,
        elevation_unit,
        area_unit,
        width,
        height,
        kernel,
        seed,
        exposures,
        isempty(exposure_names) ? [nothing for i in 1:length(exposures)] : exposure_names,
        isempty(exposure_units) ? [nothing for i in 1:length(exposures)] : exposure_units
    )
end

struct SpatialFloodProfileMask{Bool}
    coast::Matrix{Bool}
    sea::Matrix{Bool}
    width::Int
    height::Int
end

function SpatialFloodProfileMask(profile::SpatialFloodProfile)
    coast, sea = private_mask_profile(profile::SpatialFloodProfile)
    width = size(coast, 2)
    height = size(coast, 1)
    return SpatialFloodProfileMask{Bool}(coast, sea, width, height)
end

function RecipesBase.plot(profile::SpatialFloodProfileMask)

    psettings = Dict(
        :colorbar => false, 
        :aspect_ratio => :equal, 
        :framestyle => :box, 
        :xticks => [1,profile.width],
        :yticks => [1,profile.height]
    )

    p1 = Plots.heatmap(Int.(profile.coast),
        c=[:white, :darkgreen],
        title="Coast Mask";
        psettings ...
        )

    p2 = Plots.heatmap(Int.(profile.sea),
        c=[:white, :darkblue],
        title="Sea Mask";
        psettings ...
        )

    return Plots.plot(p1, p2, layout = (1, 2), size=(1000, 500), legend=false)

end



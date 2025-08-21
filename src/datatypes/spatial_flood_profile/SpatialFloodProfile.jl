using Plots
using DataStructures
using GeoFormatTypes
using CoordinateTransformations
include("./SpatialKernel.jl")

struct SpatialFloodProfile
    elevation::AbstractArray{Real, 2}
    elevation_unit::String
    area_unit::String
    width::Int
    height::Int
    SpatialKernel::SpatialKernel
    seed::CartesianIndex{2}
    exposures::Vector{Matrix{Real}}
    exposure_names::Array{Union{String, Nothing}}
    exposure_units::Array{Union{String, Nothing}}
    crs::Union{GeoFormatTypes.WellKnownText, Nothing}
    affinemap::Union{CoordinateTransformations.AffineMap, Nothing}
end

function SpatialFloodProfile(
    elevation::Union{AbstractMatrix{T}, GeoArrays.GeoArray{T}},;
    seed::CartesianIndex{2} = CartesianIndex(1,1), 
    elevation_unit::String = "m",
    area_unit::String = "m²", 
    SpatialKernel::SpatialKernel = Neighbour8(), 
    exposures::Vector = [], 
    exposure_names::Union{Vector{String}, Nothing} = nothing, 
    exposure_units::Union{Vector{String}, Nothing} = nothing, 
    crs::Union{GeoFormatTypes.WellKnownText, Nothing} = nothing, 
    affinemap::Union{CoordinateTransformations.AffineMap, Nothing} = nothing) where T<:Real

    width, height = size(elevation)
    
    # Handle case for empty vectors
    if isempty(exposures)
        exposures = Vector{Nothing}()
    end
    
    exposure_names = exposure_names === nothing ? Vector{Union{String, Nothing}}() : exposure_names
    exposure_units = exposure_units === nothing ? Vector{Union{String, Nothing}}() : exposure_units
    
    return SpatialFloodProfile(elevation, elevation_unit, area_unit, width, height, SpatialKernel, seed, exposures, exposure_names, exposure_units, crs, affinemap)
end

function RecipesBase.plot(profile::SpatialFloodProfile) 

    psettings = Dict(
        :colorbar => true, 
        :aspect_ratio => :equal,
        :framestyle => :box,
        :xticks => [1, profile.width],
        :yticks => [1, profile.height],
        :title => "Spatial Flood Profile",
        :c => cgrad(:lightterrain, rev=false)
    )

    p = Plots.heatmap(
        profile.elevation;
        psettings ...
    )

    return p

end


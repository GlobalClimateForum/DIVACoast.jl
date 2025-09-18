using Plots
using DataStructures
using GeoFormatTypes
using CoordinateTransformations
include("./SpatialKernel.jl")

struct SpatialFloodProfile{T}
	elevation::AbstractArray{T, 2}
	elevation_unit::String
	area_unit::String
	width::Int
	height::Int
	SpatialKernel::SpatialKernel
	seed::CartesianIndex{2}
	exposures::Vector{AbstractMatrix{T}}
	exposure_names::Array{Union{String, Nothing}}
	exposure_units::Array{Union{String, Nothing}}
end


function SpatialFloodProfile(
	elevation::Union{AbstractMatrix{T}, GeoArrays.GeoArray{T}}; 
	seed::CartesianIndex{2} = CartesianIndex(1, 1),
	elevation_unit::String = "m",
	area_unit::String = "m²",
	SpatialKernel::SpatialKernel = Neighbour8(),
	exposures::Vector = [],
	exposure_names::Union{Vector{String}, Nothing} = nothing,
	exposure_units::Union{Vector{String}, Nothing} = nothing
	) where T
	
	width, height = size(elevation)

	# Handle case for empty vectors
	if isempty(exposures)
		exposures = Vector{AbstractMatrix{T}}()
	end

	exposure_names = exposure_names === nothing ? Vector{Union{String, Nothing}}() : exposure_names
	exposure_units = exposure_units === nothing ? Vector{Union{String, Nothing}}() : exposure_units

	return SpatialFloodProfile{T}(elevation, elevation_unit, area_unit, width, height, SpatialKernel, seed, exposures, exposure_names, exposure_units)
end


function Base.display(io::IO, profile::SpatialFloodProfile)
	prfstr = ""
	prfstr *= "Spatial Flood Profile [$(profile.width) x $(profile.height)]"
	return print(io, prfstr)
end


function RecipesBase.plot(profile::SpatialFloodProfile)


	psettings = Dict(
		:colorbar => true,
		:aspect_ratio => :equal,
		:framestyle => :box,
		:xticks => [1, profile.width],
		:yticks => [1, profile.height],
		:title => "Spatial Flood Profile",
		:c => cgrad(:lightterrain, rev = false),
	)

	p = Plots.heatmap(
		profile.elevation;
		psettings ...,
	)

	return p

end


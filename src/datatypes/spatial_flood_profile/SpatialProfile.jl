using Plots
using DataStructures
using GeoFormatTypes
using CoordinateTransformations
include("./SpatialCursor.jl")
# SpatialProfile structure

struct SpatialProfileMask{Bool}
	coast::GeoArrays.GeoArray{Bool, 2}
	sea::GeoArrays.GeoArray{Bool, 2}
end

struct SpatialProfile{T}
	elevation::AbstractArray{T, 2}
	elevation_unit::String
	area_unit::String
	cursor::SpatialCursor
	seed::CartesianIndex{2}
	mask::SpatialProfileMask{Bool}
	width::Int
	height::Int
	exposures::Vector{AbstractMatrix{T}}
	exposure_names::Vector{Union{String, Nothing}}
	exposure_units::Vector{Union{String, Nothing}}
end

# SpatialProfile constructors
function SpatialProfile(
	
	elevation::GT;
	mask::Union{SpatialProfileMask{Bool}, Nothing} = nothing, # Will be calculated if not provided
	seed::CartesianIndex{2} = CartesianIndex(1, 1),
	elevation_unit::String = "m",
	area_unit::String = "m²",
	cursor::SpatialCursor = SpatialCursor8(),

	exposures::Vector = [],
	exposure_names::Vector{Union{String, Nothing}} = Union{String, Nothing}[],
	exposure_units::Vector{Union{String, Nothing}} = Union{String, Nothing}[]

	) where GT <: GeoArrays.GeoArray{T, 2} where T <: Real
	
	if length(exposures) > 0
		exposure_names = isnothing(exposure_names) ? [nothing for _ in 1:length(exposures)] : exposure_names
		exposure_units = isnothing(exposure_units) ? [nothing for _ in 1:length(exposures)] : exposure_units
	end

	if isnothing(mask)
		spMask_ = SpatialProfileMask(elevation, seed, cursor)
	elseif mask isa SpatialProfileMask{Bool}
		spMask_ = mask
	else
		throw(ArgumentError("mask must be either nothing or a SpatialProfileMask{Bool}"))
	end

	width = size(elevation, 1)
	height = size(elevation, 2)

	return SpatialProfile{T}(elevation, elevation_unit, area_unit, cursor, seed, spMask_, width, height, exposures, exposure_names, exposure_units)
end

# SpatialProfileMask constructors
function SpatialProfileMask(
	coast::GeoArrays.GeoArray{Bool, 2},
	sea::GeoArrays.GeoArray{Bool, 2}
	)
	return SpatialProfileMask{Bool}(coast, sea)
end

# Create a SpatialProfileMask from an existing mask
function SpatialProfileMask(mask::GeoArrays.GeoArray{DT, 2}, oceanvalue) where DT <: Any

	# prepare boolean masks
	sea_mask = falses(size(mask))
	coast_mask = falses(size(mask))

	# ensure oceanvalue has the same element type as the mask
	ov = try
		convert(DT, oceanvalue)
	catch
		error("oceanvalue cannot be converted to mask element type $(DT)")
	end

	# find sea cells in the input mask (not in the empty sea_mask)
	sea_indices = findall(mask .== ov)
	sea_mask[sea_indices] .= true

	# coast cells are sea-adjacent non-sea cells among found sea_indices
	coast_indices = filter(idx -> !all(nbvalues(sea_mask, idx)), sea_indices)
	coast_mask[coast_indices] .= true

	# convert to GeoArrays preserving geo metadata
	coast_mask = GeoArrays.GeoArray(coast_mask, mask.f, mask.crs)
	sea_mask = GeoArrays.GeoArray(sea_mask, mask.f, mask.crs)

	return SpatialProfileMask{Bool}(coast_mask, sea_mask)

end

# Calculate a SpatialProfileMask from elevation data and  seed point
function SpatialProfileMask(elevation::GeoArrays.GeoArray, seed::CartesianIndex{2}, cursor::SpatialCursor)

	sea_mask = falses(size(elevation))
	coast_mask = falses(size(elevation))
	visited = falses(size(elevation))

	# Init sea value, check sea_value function and tovisit queue
	sea_val = elevation[seed]
	check_sea_value = idx -> ismissing(sea_val) ? ismissing(elevation[idx]) : elevation[idx] == sea_val
	tovisit = Queue{CartesianIndex{2}}()

	# Init with seed point
	enqueue!(tovisit, seed)
	sea_mask[seed] = true
	visited[seed] = true

	while !isempty(tovisit)

		current_ = dequeue!(tovisit)
		nb_cells = neighbours(elevation, current_, cursor = cursor) |> values

		for nb in nb_cells
			if !isnothing(nb) && !visited[nb]
				visited[nb] = true
				if check_sea_value(nb)
					sea_mask[nb] = true
					enqueue!(tovisit, nb)
				else
					coast_mask[nb] = true
				end
			end
		end
	end

	coast_mask = GeoArrays.GeoArray(coast_mask, elevation.f, elevation.crs)
	sea_mask = GeoArrays.GeoArray(sea_mask, elevation.f, elevation.crs)

	return SpatialProfileMask{Bool}(coast_mask, sea_mask)
end
	
# Plotting and display functions

function Base.show(io::IO, sp::SpatialProfile)
	print(io, "<DIVACoast.jl | SpatialProfile | $(sp.width)x$(sp.height)>")
end

function Base.show(io::IO, pm::SpatialProfileMask)
	print(io, "<DIVACoast.jl | SpatialProfileMask | $(size(pm.coast, 1))x$(size(pm.coast, 2))>")
end

function RecipesBase.plot(sp::SpatialProfile; kwargs...)

	elev = Plots.heatmap(sp.elevation; zlims = [-5, maximum(sp.elevation)], title = "Elevation", c = cgrad(:greys, rev = true), colorbar_title = sp.elevation_unit)
	sea = Plots.heatmap(sp.mask.sea; title = "Sea Mask", c = cgrad([:transparent, :red]), alpha = 0.5)
	coast = Plots.heatmap(sp.mask.coast; title = "Coast Mask", c = cgrad([:blue, :transparent]))
	return Plots.plot(elev, sea, coast; layout = (1, 3), size = (1200, 400))
end

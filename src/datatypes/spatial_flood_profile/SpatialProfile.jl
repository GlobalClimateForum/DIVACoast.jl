using Plots
using DataStructures
using GeoFormatTypes
using CoordinateTransformations
include("./SpatialCursor.jl")
# SpatialProfile structure

@kwdef struct SpatialProfileMask{Bool}
	coast::GeoArrays.GeoArray{Bool, 2}
	sea::GeoArrays.GeoArray{Bool, 2}
	land::GeoArrays.GeoArray{Bool, 2}
	distance::Union{GeoArrays.GeoArray{Float64, 2}, Nothing} = nothing
	path::Union{GeoArrays.GeoArray{Int, 2}, Nothing} = nothing
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
	seed::Union{CartesianIndex, Tuple, Vector} = CartesianIndex(1, 1),
	elevation_unit::String = "m",
	area_unit::String = "m²",
	cursor::SpatialCursor = SpatialCursor8(),
	exposures::Vector{GT} = GT[],
	exposure_names::Vector{Union{String, Nothing}} = Union{String, Nothing}[],
	exposure_units::Vector{Union{String, Nothing}} = Union{String, Nothing}[]

	) where GT <: GeoArrays.GeoArray{T, 2} where T <: Union{Real, Missing}
	
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

# --- SpatialProfileMask constructors ---
"""
	SpatialProfileMask(coast::GeoArray{Bool, 2}, sea::GeoArray{Bool, 2}, land::GeoArray{Bool, 2})

Constructs  a `SpatialProfileMask` directly from provided coast, sea, and land masks.

# Arguments
- `coast::GeoArray{Bool, 2}`: A GeoArray where `true` values indicate coastal cells.
- `sea::GeoArray{Bool, 2}`: A GeoArray where `true` values indicate sea cells.
- `land::GeoArray{Bool, 2}`: A GeoArray where `true` values indicate land cells. We consider land cells as those that are not sea cells.	
- `distance::Union{GeoArray{Float64, 2}, Nothing}`: Optional GeoArray containing distances from land cells to the nearest coast cell. Default is `nothing`.
- `path::Union{GeoArray{Int, 2}, Nothing}`: Optional GeoArray containing path identifiers from land cells to the nearest coast cell. Default is `nothing`.

# Returns
- `SpatialProfileMask{Bool}`: A `SpatialProfileMask` instance containing the provided masks. 
"""
function SpatialProfileMask(
	coast::GeoArrays.GeoArray{Bool, 2},
	sea::GeoArrays.GeoArray{Bool, 2},
	land::GeoArrays.GeoArray{Bool, 2}, 
	distance::Union{GeoArrays.GeoArray{Float64, 2}, Nothing} = nothing,
	path::Union{GeoArrays.GeoArray{Int, 2}, Nothing} = nothing
	)
	return SpatialProfileMask{Bool}(coast, sea, land, distance, path)
end

"""
	SpatialProfileMask(mask::GeoArray{DT, 2}, sea_class_value::Union{Number, Missing, Nothing})

Constructs a `SpatialProfileMask` from a single water body mask by identifying sea cells based on a specified value and derriving coast and land masks according to the sea mask. Coast cells 
are defined as non-sea cells that are adjacent to a sea cell. Land cells are defined as all non-sea cells. 

# Arguments
- `mask::GeoArray{DT, 2}`: A GeoArray containing values that can be used to identify sea cells based on the `sea_class_value`.
- `sea_class_value::Union{Number, Missing, Nothing}`: The value in the `mask` that indicates sea cells. Cells with this value will be classified as sea, while adjacent non-sea cells will be classified as coast, and als cells not classified as sea will be classified as land.
- `distances::Bool`: Default `true`. Wether to calculate a distance mask for all land cells to the nearest coast cells, and a path mask indicating the shortest path to the nearest coast cell by an unique integer identifier.

# Returns 
- `SpatialProfileMask{Bool}`: A `SpatialProfileMask` instance containing the derived sea, coast, and land masks. 
"""
function SpatialProfileMask(mask::GeoArrays.GeoArray{DT, 2}, sea_class_value::Union{Number, Missing, Nothing}; distances = true) where DT <: Any

	# prepare boolean masks
	sea_mask = falses(size(mask))
	coast_mask = falses(size(mask)) 

	# ensure sea_class_value has the same element type as the mask
	ov = try
		convert(DT, sea_class_value)
	catch
		error("sea_class_value cannot be converted to mask element type $(DT)")
	end

	# find sea cells in the input mask
	sea_indices = findall(mask .== ov)
	sea_mask[sea_indices] .= true

	# coast cells are sea-adjacent non-sea cells among found sea_indices
	coast_indices = filter(idx -> any(nbvalues(sea_mask, idx; cursor = SpatialCursor8())), findall(.!sea_mask))
	coast_mask[coast_indices] .= true

	# convert to GeoArrays preserving geo metadata
	coast_mask = GeoArrays.GeoArray(coast_mask, mask.f, mask.crs)
	sea_mask = GeoArrays.GeoArray(sea_mask, mask.f, mask.crs)
	land_mask = .!sea_mask	
	
	if distances
		distances, paths = dijkstra(sea_mask, coast_mask)
		distances = GeoArrays.GeoArray(distances, mask.f, mask.crs)
		paths = GeoArrays.GeoArray(paths, mask.f, mask.crs)
	else
		distances, paths = nothing, nothing
	end

	return SpatialProfileMask{Bool}(coast_mask, sea_mask , land_mask, distances, paths)

end


# Calculate a SpatialProfileMask from elevation data and seed point
"""
		SpatialProfileMask(elevation::GeoArrays.GeoArray, seed::CartesianIndex{2}, cursor::SpatialCursor)

Constructs a `SpatialProfileMask` by performing a breadth-first search (BFS) starting from a specified seed cell in the elevation data to identify connected sea cells and their adjacent coast cells.
The **seed cell is assumed to be a sea cell**, and the BFS explores neighboring cells to classify them sea. Cells that are adjacent to sea cells but not classified as sea are classified as coast cells. 
All cells that are not classified as sea are classified as land cells.

# Arguments
- `elevation::GeoArrays.GeoArray`: A GeoArray containing elevation data.
- `seed::CartesianIndex{2}`: The Cartesian index of the seed cell in the elevation GeoArray, which is assumed to be a sea cell. The BFS will start from this cell to identify connected sea cells and adjacent coast cells.
- `cursor::SpatialCursor`: A `SpatialCursor` instance that defines the neighborhood structure for the BFS (e.g., 4-connected, 8-connected).
- `distances::Bool`: Default `true`. Wether to calculate a distance mask for all land cells to the nearest coast cells, and a path mask indicating the shortest path to the nearest coast cell by an unique integer identifier.

# Returns
- `SpatialProfileMask{Bool}`: A `SpatialProfileMask` instance containing the derived sea, coast, and land masks based on the BFS exploration from the seed cell.

"""
function SpatialProfileMask(elevation::GeoArrays.GeoArray, seed::CartesianIndex{2}, cursor::SpatialCursor; distances = true)

	@debug "Calculating SpatialProfileMask from seed: $(seed)"

	# Init masks
	sea_mask = falses(size(elevation))
	coast_mask = falses(size(elevation))
	visited = falses(size(elevation))

	# Init sea value (value, being assumed to be sea) 
	sea_val = elevation[seed]

	# Function to check whether a cell is a sea cell
	check_sea_value = idx -> elevation[idx] == sea_val

	# Init queue for breadth-first search
	tovisit = Queue{CartesianIndex{2}}()
	enqueue!(tovisit, seed)

	# Inti first check
	sea_mask[seed] = true
	visited[seed] = true

	while !isempty(tovisit)

		# Pop index of the current step from the queue
		current_ = dequeue!(tovisit)

		# Get the values of the neighbouring cells using the spatial cursor
		nb_cells = nbindices(elevation, current_; cursor = cursor)
		
		# For each neighbor cell
		for nb in nb_cells

			# If the neighbour is not nothing (out of bounds) and not yet visited: 
			if !visited[nb]
				
				# Mark neighbour as visited
				visited[nb] = true

				# Check if neighbour is a sea or coast cell
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
	land_mask = .!sea_mask
	
	if distances
		distances, paths = dijkstra(sea_mask, coast_mask)
		distances = GeoArrays.GeoArray(distances, elevation.f, elevation.crs)
		paths = GeoArrays.GeoArray(paths, elevation.f, elevation.crs)
	else
		distances, paths = nothing, nothing
	end

	return SpatialProfileMask{Bool}(coast_mask, sea_mask, land_mask, distances, paths)
end
	
# Plotting and display functions

function Base.show(io::IO, sp::SpatialProfile)
	print(io, "<DIVACoast.jl | SpatialProfile | $(sp.width)x$(sp.height)>")
end

function Base.show(io::IO, pm::SpatialProfileMask)
	print(io, "<DIVACoast.jl | SpatialProfileMask | $(size(pm.coast, 1))x$(size(pm.coast, 2))>")
end

function RecipesBase.plot(sp::SpatialProfile; kwargs...)
		
	elev = Plots.heatmap(sp.elevation; zlims = [-5, maximum(sp.elevation)], title = "Elevation", c = cgrad(:terrain), colorbar_title = sp.elevation_unit)
	sea = Plots.heatmap(sp.mask.sea; title = "Sea Mask", c = cgrad([:transparent, "#F71735"]), alpha = 0.5)
	coast = Plots.heatmap(sp.mask.coast; title = "Coast Mask", c = cgrad(["#F71735", :transparent]))
	return Plots.plot(elev, sea, coast; layout = (1, 3), size = (1200, 400))
end

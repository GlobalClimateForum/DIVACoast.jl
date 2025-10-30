using Distances


abstract type SpatialCursor
    # Abstract type for spatial cursors
end

@kwdef struct SpatialCursor8 <: SpatialCursor
    up::Tuple{Int, Int} = (-1, 0)      # up
    down::Tuple{Int, Int} = (1, 0)     # down   
    left::Tuple{Int, Int} = (0, -1)    # left
    right::Tuple{Int, Int} = (0, 1)    # right      
    upleft::Tuple{Int, Int} = (-1, -1)  # up_left
    upright::Tuple{Int, Int} = (-1, 1)   # up_right
    downleft::Tuple{Int, Int} = (1, -1)  # down_left
    downright::Tuple{Int, Int} = (1, 1)  # down_right
end

@kwdef struct SpatialCursor4 <: SpatialCursor
    up::Tuple{Int, Int} = (-1, 0)      # up
    down::Tuple{Int, Int} = (1, 0)     # down   
    left::Tuple{Int, Int} = (0, -1)    # left
    right::Tuple{Int, Int} = (0, 1)    # right      
end

struct SpatialCursorRadial <: SpatialCursor
    directions::Dict{Symbol, Tuple{Int,Int}}
end

function SpatialCursorRadial(pxRadius::Int) 

    points_ = Dict{Symbol, Tuple{Int,Int}}()

    for x in -pxRadius:pxRadius
        for y in -pxRadius:pxRadius
            if √(x^2 + y^2) <= pxRadius && !(x == 0 && y == 0)
                dir_ = "$(x)rX$(y)rY" |> Symbol
                points_[dir_] = (x, y)
            end
        end
    end

    return SpatialCursorRadial(points_)
end

function directions(cursor::Union{SpatialCursor8, SpatialCursor4})
    return Dict(field => getfield(cursor, field) for field in fieldnames(typeof(cursor)))
end

function directions(cursor::SpatialCursorRadial)
    return Dict(field => cursor.directions[field] for field in keys(cursor.directions))
end

"""
    neighbours(from::AbstractArray, at::CartesianIndex{2}; cursor::SpatialCursor = SpatialCursor8(), returndist = false)
Get the neighboring indices and (optionally) distances of a given CartesianIndex `at` in the array `from`, using the specified `cursor` to define neighbor directions.
# Arguments
- `from::AbstractArray`: The array from which to get neighbors.
- `at::CartesianIndex{2}`: The Cartesian index of the cell for which to find neighbors.
- `cursor::SpatialCursor`: The spatial cursor defining neighbor directions (default is `SpatialCursor8()`).
- `returndist::Bool`: If true, returns distances to neighbors along with their indices (default is false). Returns results as Dict{Symbol, Union{CartesianIndex{2}, Tuple{CartesianIndex{2}, Float64}, Nothing}} where the key is the direction symbol.
"""
function neighbours(from::AbstractArray, at::CartesianIndex{2}; cursor::SpatialCursor = SpatialCursor8(), returndist = false)
    
    # Get Direction Dicts (dir::Symvol => (dx::Int, dy::Int))
    dirdict = directions(cursor)

    # Calculate neighbour positions (dir::Symbol => CartesianIndex{2} | nothing)
    neighbour_indices = Dict{Symbol, Union{CartesianIndex{2}, Tuple{CartesianIndex{2}, Float64}, Nothing}}(
        dir => begin
            at .+ CartesianIndex(dirdict[dir] ...) |> pos_ -> (checkbounds(Bool, from, pos_) ? pos_ : nothing)
        end for dir in keys(dirdict))

    
    # Calculate distances to neighbour positions if requested
    if returndist

        # Get cooordinate from which distances are calculated
        lon1, lat1 = GeoArrays.coords(from, at)
        # Check wether the GeoArray is projected or geographic to choose the appropiate distance function
        projected = occursin("PROJCS", string(from.crs)) || !occursin("GEOGCS", string(from.crs))

        for (direction, index) in neighbour_indices
            if isnothing(index)
                neighbour_indices[direction] = nothing
            else
                lon2, lat2 = GeoArrays.coords(from, index)
                dist_ = projected ? Distances.euclidean((lon1, lat1), (lon2, lat2)) : distance(lon1, lat1, lon2, lat2) * 1000
                neighbour_indices[direction] = (index, dist_)

            end
        end
        return neighbour_indices
    else 
        return neighbour_indices
    end
end

function neighbour_indices(from::T, at::CartesianIndex{2}; cursor::SpatialCursor = SpatialCursor8()) where T <: AbstractArray
    nbs = neighbours(from, at; cursor = cursor, returndist = false) |> values |> collect 
    return filter(!isnothing, nbs)
end

# function neighbour_vals(m::T, at::CartesianIndex{2}; nb::SpatialCursor = SpatialCursor8()) where T <: AbstractArray
#     nbs = neighbours(m, at; nb = nb, returndist = false) |> values |> collect 
#     idx = filter(!isnothing, nbs)
#     return [m[i] for i in idx]
# end


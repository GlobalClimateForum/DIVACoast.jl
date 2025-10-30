"""
    function flood_fill(sp::SpatialProfile, wl::DT) where DT <: Real
Performs Flood Fill (bathtub) inundation on a SpatialProfile `sp` given a water level `wl`.
# Arguments
- `sp::SpatialProfile`: The spatial flood profile containing elevation and associated sea & coast masks. 
- `wl::DT`: The water level for inundation.
# Returns 
- `Array{DT, 2}`: An array representing the inundation depth at each cell in the spatial profile.
The inundation depth is `0` for non-inundated cells, positive values for inundated cells, and `Inf` for sea cells.
"""
function flood_fill(sp::SpatialProfile, wl::DT) where DT <: Real

    # Init the inundation depth matrix
    inundation_depth = zeros(DT, sp.width, sp.height)
    inundation_depth[sp.mask.sea .== true] .= Inf

    # Initialize flooded mask
    flooded = falses(sp.width, sp.height)
    flooded[findall(sp.mask.sea .== true)] .= true

    # Init queue (need to check queue)
    queue = Queue{CartesianIndex{2}}()
    map(idx -> enqueue!(queue, idx), findall(sp.mask.coast .== true))

    while !isempty(queue)

        current_ = dequeue!(queue)

        if flooded[current_] || sp.elevation[current_] > wl
            continue # skip to the next cell
        end

        # Set the current cell as flooded
        flooded[current_] = true

        # Calculate inundation depth
        inundation_depth[current_] = wl - sp.elevation[current_]

        # Get all neighbors within the bounds and enqueue them if they are not flooded and their 
        # elevation is less than or equal to the water level
        nbs = neighbours(sp.elevation, current_, cursor = sp.cursor) |> values |> collect |> filter(!isnothing)
        map(idx -> (flooded[idx] && sp.elevation[idx] <= wl) ? nothing : enqueue!(queue, idx), nbs)
        
    end
    return inundation_depth
end
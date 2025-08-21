function flood_fill(profile::SpatialFloodProfile, wl::DT) where DT <: Number

    # Initialize inundation depth matrix
    inundation_depth = zeros(DT, profile.height, profile.width)
    # Initialize flooded mask (already checked mask)
    flooded = falses(profile.height, profile.width)
    # Initi queue (need to check queue)
    queue = Queue{CartesianIndex{2}}()

    # Set the seed point as flooded and set its inundation depth to Inf
    inundation_depth[profile.seed] = Inf
    sea_value = profile.elevation[profile.seed]

    # Start with the seed point - enqueue it
    enqueue!(queue, profile.seed)

    # As long as there are cells in the queue (to be checked)
    while !isempty(queue)

        # pop the next cell from the queue
        current_ = dequeue!(queue)
    
        # Check if the current cell is already flooded (checked) or if its elevation is greater than the water level
        if flooded[current_] || profile.elevation[current_] > wl
            continue # skip to the next cell
        end

        # Set the current cell as flooded (checked)
        flooded[current_] = true
        # Set the inundation depth for the current cell: either Inf (if sea) or wl - elevation (if land)
        inundation_depth[current_] = (profile.elevation[current_] == sea_value) ? Inf : wl - profile.elevation[current_]
        
        # Get all neighbors within the bounds and enqueue them if they are not flooded and their 
        # elevation is less than or equal to the water level
        nbs = filter(!isnothing, values(neighbours(profile.elevation, current_, nb = profile.SpatialKernel)))
        for nb in nbs
            if !flooded[nb] && profile.elevation[nb] <= wl
                enqueue!(queue, nb)
            end
        end
    end
    # Return the inundation depth matrix
    return inundation_depth
end

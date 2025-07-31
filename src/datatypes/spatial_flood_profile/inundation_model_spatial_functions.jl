function private_mask_profile(profile::SpatialFloodProfile)

    sea_mask = falses(size(profile.elevation))
    coast_mask = falses(size(profile.elevation))
    visited = falses(size(profile.elevation))

    sea_value = profile.elevation[profile.seed]
    queue = Queue{CartesianIndex{2}}()
    
    # Mark the seed point as sea and visited
    sea_mask[profile.seed] = true
    visited[profile.seed] = true
    enqueue!(queue, profile.seed)

    while !isempty(queue)
        current_ = dequeue!(queue)
        nb_cells = neighbours(profile.elevation, current_, nb = profile.kernel) |> values

        for nb in nb_cells
            if !isnothing(nb) && !visited[nb]
                visited[nb] = true
                if profile.elevation[nb] == sea_value
                    sea_mask[nb] = true
                    enqueue!(queue, nb)
                else
                    coast_mask[nb] = true
                end
            end
        end
    end

    return [coast_mask, sea_mask]

end

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
        nbs = filter(!isnothing, values(neighbours(profile.elevation, current_, nb = profile.kernel)))
        for nb in nbs
            if !flooded[nb] && profile.elevation[nb] <= wl
                enqueue!(queue, nb)
            end
        end
    end
    # Return the inundation depth matrix
    return inundation_depth
end

function dijkstra_fill(profile::SpatialFloodProfile, wl::DT) where DT <: Number

    # Distances to each pixel, initialized to Inf
    distances = fill(Inf, profile.height, profile.width)
    
    # Visited pixels
    visited = falses(profile.height, profile.width)

    # Path IDs
    paths = fill(-1, profile.height, profile.width)
    path_counter = 0

    # Priority queue for Dijkstra Fill - priority is based on lowest distance
    pqueue = PriorityQueue{CartesianIndex{2}, Int}()

    # Get the coast and sea masks
    coastmask, seamask = get_coast_sea(profile, profile.seavalue)

    # Mark all sea cells as visited and set their distances to 0
    for cell in findall(seamask) 
        distances[cell] = 0
        visited[cell] = true
    end

    # Add all coastcells to the priority queue with distance 0
    # and assign them a unique path ID - "seed cells"
    for (p, cell) in enumerate(findall(coastmask))
        distances[cell] = 0
        paths[cell] = p
        path_counter = p
        enqueue!(pqueue, cell, 0)
    end

    while !isempty(pqueue)
        index, distance = dequeue_pair!(pqueue)

        # Check if current index is already visited
        if visited[index]
            continue
        end

        # If not visited before, mark it as visited yet
        visited[index] = true

        # Get neighbors of the current index
        nbs = values(neighbours(profile.elevation, index, nb=profile.kernel))

        for nb in nbs # Check neighbors
            
            # Skip if the neighbor is out of bounds or already visited
            if isnothing(nb) || visited[nb]
            continue
            end

            # Calculate the distance to the neighbor (number of cells traveled)
            new_distance = distances[index] + 1
            
            # If the new distance is less than the current distance to the neighbor
            # and the elevation of the neighbor is less than or equal to the water level
            # update the distance and path and enqueue the neighbor with the new distance
            if new_distance < distances[nb] && profile.elevation[nb] <= wl
                distances[nb] = new_distance
                paths[nb] = paths[index]
            enqueue!(pqueue, nb, new_distance)
            end
        end
    end
    return distances, paths
end

function path_based_attenuated_inundation(profile::SpatialFloodProfile, profilemask::SpatialFloodProfileMask, wl::Real, attrate::Union{Real, AbstractArray{Real, 2}}; returnpaths = false)

    attrate = (attrate / 1000) # Convert attrate to km^-1 if given in m^-1

    # Initialize the propagation counter - defines which cells are processed in each iteration
    propagationcounter = 0
    propagation = fill(Inf, profile.height, profile.width)
    propagation[profilemask.coast] .= 0.0f0

    # Initialize the attenuation for each cell (Inf) and set attenuation at coast to 0.0
    attenuation = fill(Inf, profile.height, profile.width)
    attenuation[profilemask.coast] .= 0.0f0

    # Inititalize paths
    paths = fill(-1, profile.height, profile.width)
    
    # Assign path IDs to coastal cells
    path_indices = findall(profilemask.coast)
    for (i, idx) in enumerate(path_indices)
        paths[idx] = i
    end
    
    # Set Inundation depth to 0.0 for each land cell and to inf for sea cells
    inundation_depth = fill(0.0f0, profile.height, profile.width)
    inundation_depth[profilemask.sea] .= Inf
    inundation_depth[profilemask.coast] .= profile.elevation[profilemask.coast] .- wl

    # As long as there are cells to process
    while !isempty(findall(propagation .== propagationcounter))

       # For each cell in the current propagation step
        for cell in findall(propagation .== propagationcounter)

            profilemask.sea[cell] ? continue : nothing # jump to next cell if current cell is a sea cell

            # Calculate the inundation depth for the current cell - min inundation = 0.0
            inundation_depth[cell] = maximum((wl - profile.elevation[cell] - attenuation[cell], 0.0f0))

            # If the inundation depth is greater than 0.0 and not sea, propagate to neighbors
            if inundation_depth[cell] > 0.0f0

                # Get neighbors of the current cell
                nbs = values(neighbours(profile.elevation, cell, nb=profile.kernel; returndist = true))
                for (nb, distance) in nbs
    
                    # Skip neighbor if the neighbor is out of bounds
                    if isnothing(nb)
                        continue
                    end

                    # Assign path ID to the neighbor
                    paths[nb] = paths[cell]

                    # Calculate the attenuation rate for the neighbor
                    new_attenuation = attenuation[cell] + (attrate * distance)
                    # If the new attenuation is less than the current attenuation for the neighbor
                    # assign new attenuation rate and add neighbor 
                    if new_attenuation < attenuation[nb]
                        attenuation[nb] = new_attenuation
                        propagation[nb] = propagationcounter + 1
                        paths[nb] = paths[cell]
                    end

                end
            end
        end 
         # Update the propagation counter
        propagationcounter += 1
    end

    if returnpaths
        return inundation_depth, paths  # return the inundation depth matrix and paths
    else
        return inundation_depth
    end

end



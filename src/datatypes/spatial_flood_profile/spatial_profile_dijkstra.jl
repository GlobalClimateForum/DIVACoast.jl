
function dijkstra_fill(profile::SpatialProfile, wl::DT) where DT <: Number

    # Distances to each pixel, initialized to Inf
    distances = fill(Inf, profile.width, profile.height)
    
    # Visited pixels
    visited = falses(profile.width, profile.height)

    # Path IDs
    paths = fill(-1, profile.width, profile.height)
    path_counter = 0

    # Priority queue for Dijkstra Fill - priority is based on lowest distance
    pqueue = PriorityQueue{CartesianIndex{2}, Float64}()

    # Get the coast and sea masks
    coastmask, seamask = profile.mask.coast, profile.mask.sea

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
        nbs = neighbours(profile.elevation, index, cursor=profile.cursor; returndist = true)

        for direction in keys(nbs)

            # Check if the neighbor is out of bounds or already visited
            if isnothing(nbs[direction]) || visited[nbs[direction][1]] || haskey(pqueue, nbs[direction][1])
                continue
            else
                # Calculate a new distance to the neighbor from the current index 
                dist_to_nb = distances[index] + nbs[direction][2]

                # If the new distance is less than the current distance to the neighbor
                # and the elevation of the neighbor is less than or equal to the water level
                # update the distance and path and enqueue the neighbor with the new distance
                if dist_to_nb < distances[nbs[direction][1]] && profile.elevation[nbs[direction][1]] <= wl
                    distances[nbs[direction][1]] = dist_to_nb
                    paths[nbs[direction][1]] = paths[index]
                    enqueue!(pqueue, nbs[direction][1], dist_to_nb)
                end
            end

        end
    end
    return distances, paths
end


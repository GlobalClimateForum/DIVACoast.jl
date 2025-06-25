function get_coast_sea(profile::FloodProfile, seavalue::DT) where DT <: Union{Symbol, Number}
    sea_mask = profile.elevation .== seavalue
    is_coastal = (sea_cell::CartesianIndex{2}) -> begin
        nbs = values(getNBS(profile.elevation, sea_cell, nb=profile.kernel))
        any(nb -> !isnothing(nb) && profile.elevation[nb] != seavalue, nbs)
    end

    coastmask = falses(profile.height, profile.width)
    seamask = falses(profile.height, profile.width)
    
    for cell in findall(sea_mask)
        if is_coastal(cell)
            coastmask[cell] = true
        else
            seamask[cell] = true
        end
    end

    return coastmask, seamask
end

function flood_fill(profile::FloodProfile, seed::CartesianIndex{2}, wl::DT) where DT <: Number
    flooded = falses(profile.height, profile.width)
    queue = Queue{CartesianIndex{2}}()
    enqueue!(queue, seed)

    visitfilter = (value, wl) -> isa(value, typeof(:sea)) ? value == :sea && value != :out : value <= wl

    while !isempty(queue)
        current = dequeue!(queue)
        
        if flooded[current] || !visitfilter(profile.elevation[current], wl)
            continue
        end

        flooded[current] = true

        nbs = filter(!isnothing, values(getNBS(profile.elevation, current, nb=profile.kernel)))
        for nb in nbs
            if !flooded[nb] && visitfilter(profile.elevation[nb], wl)
                enqueue!(queue, nb)
            end
        end
    end

    return flooded
end


function dijkstra_fill(profile::FloodProfile, seed::CartesianIndex{2}, wl::DT) where DT <: Number

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
    coastmask, seamask = get_coast_sea(profile, :sea)

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
        nbs = values(getNBS(profile.elevation, index, nb=profile.kernel))

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

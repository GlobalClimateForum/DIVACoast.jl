function exposure(profile::SpatialFloodProfile, wl::Real, im::IM) where IM <: InundationModel

    if typeof(im) ∈ [SpatialBathtubInundation] 
        seed_ = im.seed
        flooded = flood_fill(profile, seed_, wl)
    else
        flooded = dijkstra_fill(profile, wl)
    end

end



function seamask(elevationMatrix::Matrix, seed::CartesianIndex{2})
    sea_value = elevationMatrix[seed]
    queue = Queue{CartesianIndex{2}}()
    enqueue!(queue, seed)
    sea_mask = falses(size(elevationMatrix))
    sea_mask[seed] = true
    while !isempty(queeue)
        current = dequeue!(queue)
        nbs = values(getNBS(elevationMatrix, current, nb=Neighbour8()))
        for nb in nbs
            if !isnothing(nb) && elevationMatrix[nb] == sea_value 
                    sea_mask[nb] = true
                    enqueue!(queue, nb)
            end
        end
    end
    return sea_mask
end

function get_coast_sea(profile::SpatialFloodProfile, seavalue::DT) where DT <: Union{Symbol, Number}
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


function flood_fill(profile::SpatialFloodProfile, seed::CartesianIndex{2}, wl::DT) where DT <: Number

    inundation_depth = zeros(DT, profile.height, profile.width)
    flooded = falses(profile.height, profile.width)
    queue = Queue{CartesianIndex{2}}()
    enqueue!(queue, seed)

    while !isempty(queue)

        current_ = dequeue!(queue)
    
        if flooded[current_] || profile.elevation[current_] > wl
            continue
        end

        flooded[current_] = true
        inundation_depth[current_] = wl - profile.elevation[current_]

        nbs = filter(!isnothing, values(getNBS(profile.elevation, current, nb = profile.kernel)))
        for nb in nbs
            if !flooded[nb] && profile.elevation[nb] <= wl
                enqueue!(queue, nb)
            end
        end
    end

    return inundation_depth
end

# function flood_fill(profile::SpatialFloodProfile, seed::CartesianIndex{2}, wl::DT) where DT <: Number
#     flooded = falses(profile.height, profile.width)
#     queue = Queue{CartesianIndex{2}}()
#     enqueue!(queue, seed)

#     visitfilter = (value, wl) -> isa(value, typeof(:sea)) ? value == :sea && value != :out : value <= wl

#     while !isempty(queue)
#         current = dequeue!(queue)
        
#         if flooded[current] || !visitfilter(profile.elevation[current], wl)
#             continue
#         end

#         flooded[current] = true

#         nbs = filter(!isnothing, values(getNBS(profile.elevation, current, nb=profile.kernel)))
#         for nb in nbs
#             if !flooded[nb] && visitfilter(profile.elevation[nb], wl)
#                 enqueue!(queue, nb)
#             end
#         end
#     end

#     return flooded
# end


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

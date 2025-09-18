# TODO: 
# get rid of sea_value and implement function, with and without mask
function flood_fill(profile::SpatialFloodProfile, wl::DT; 
    profile_mask::SpatialFloodProfileMask = nothing) where DT <: Real

    @info "Profile mask provided: using mask for flood fill."

    # Initialize inundation depth matrix
    inundation_depth = zeros(DT, profile.width, profile.height)
    inundation_depth[profile_mask.sea] .= Inf

    # Initialize flooded mask
    flooded = falses(profile.width, profile.height)
    flooded[findall(profile_mask.sea)] .= true

    # Init queue (need to check queue)
    queue = Queue{CartesianIndex{2}}()
    map(idx -> enqueue!(queue, idx), findall(profile_mask.coast))

    while !isempty(queue)

        current_ = dequeue!(queue)

        if flooded[current_] || profile.elevation[current_] > wl
            continue # skip to the next cell
        end

        # Set the current cell as flooded
        flooded[current_] = true

        # Calculate inundation depth
        inundation_depth[current_] = wl - profile.elevation[current_]

        # Get all neighbors within the bounds and enqueue them if they are not flooded and their 
        # elevation is less than or equal to the water level
        nbs = filter(!isnothing, values(neighbours(profile.elevation, current_, nb = profile.SpatialKernel)))
        for nb in nbs
            if !flooded[nb] && profile.elevation[nb] <= wl
                enqueue!(queue, nb)
            end
        end
    
    end

    return inundation_depth

end

# function flood_fill(profile::SpatialFloodProfile, wl::DT) where DT <: Number

#     # Initialize inundation depth matrix
#     inundation_depth = zeros(DT, profile.width, profile.height)
#     # Initialize flooded mask (already checked mask)
#     flooded = falses(profile.width, profile.height)
#     # Initi queue (need to check queue)
#     queue = Queue{CartesianIndex{2}}()

#     # Set the seed point as flooded and set its inundation depth to Inf
#     inundation_depth[profile.seed] = Inf

#     # Start with the seed point - enqueue it
#     enqueue!(queue, profile.seed)


#     # As long as there are cells in the queue (to be checked)
#     while !isempty(queue)

#         # pop the next cell from the queue
#         current_ = dequeue!(queue)
#         println(current_)
    
#         # Check if the current cell is already flooded (checked) or if its elevation is greater than the water level

#         if  flooded[current_] || ismissing(profile.elevation[current_]) || profile.elevation[current_] > wl
#             continue # skip to the next cell
#         end

#         # Set the current cell as flooded (checked)
#         flooded[current_] = true
#         # Set the inundation depth for the current cell: either Inf (if sea) or wl - elevation (if land)
#         inundation_depth[current_] = (profile.elevation[current_] == sea_value) ? Inf : wl - profile.elevation[current_]
        
#         # Get all neighbors within the bounds and enqueue them if they are not flooded and their 
#         # elevation is less than or equal to the water level
#         nbs = filter(!isnothing, values(neighbours(profile.elevation, current_, nb = profile.SpatialKernel)))
#         for nb in nbs
#             if !flooded[nb] && profile.elevation[nb] <= wl
#                 enqueue!(queue, nb)
#             end
#         end
#     end
#     # Return the inundation depth matrix
#     return inundation_depth
# end

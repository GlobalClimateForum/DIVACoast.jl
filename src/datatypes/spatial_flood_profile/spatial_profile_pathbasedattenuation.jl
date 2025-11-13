
function path_based_attenuated_inundation(
    profile::SpatialProfile,
    wl::Real, attrate::Union{Real, AbstractArray{2, <:Real},  GeoArrays.GeoArray{T,N,A} where {T <: Real, N, A <: AbstractArray{T, N}}};
    returnpaths = false, returnall = false)
    
    if attrate isa Real
            attrate = attrate / 1000
        elseif attrate isa GeoArrays.GeoArray
            attrate = attrate.A  ./ 1000
        else
            throw(ArgumentError("attrate must be either a Real, a GeoArrays.GeoArray, or an AbstractArray of Real values"))
    end

    # elevation_ = profile.elevation isa GeoArrays.GeoArray ? profile.elevation.A : profile.elevation
    elevation_ = profile.elevation

    # Initialize the propagation counter - defines which cells are processed in each iteration
    propagationcounter = 0
    propagation = fill(Inf, profile.width, profile.height)
    propagation[profile.mask.coast] .= 0.0f0

    # Initialize the attenuation for each cell (Inf) and set attenuation at coast to 0.0
    attenuation = fill(Inf, profile.width, profile.height)
    attenuation[profile.mask.coast] .= 0.0f0

    # Inititalize paths
    paths = fill(-1, profile.width, profile.height)

    # Assign path IDs to coastal cells
    path_indices = findall(profile.mask.coast)
    for (i, idx) in enumerate(path_indices)
        paths[idx] = i
    end
    
    # Set Inundation depth to 0.0 for each land cell and to inf for sea cells
    inundation_depth = fill(0.0f0, profile.width, profile.height)
    inundation_depth[profile.mask.sea] .= Inf
    inundation_depth[profile.mask.coast] .= elevation_[profile.mask.coast] .- wl

    # As long as there are cells to process
    while !isempty(findall(propagation .== propagationcounter))

       # For each cell in the current propagation step
        for cell in findall(propagation .== propagationcounter)

            profile.mask.sea[cell] ? continue : nothing # jump to next cell if current cell is a sea cell

            # Calculate the inundation depth for the current cell - min inundation = 0.0
            inundation_depth[cell] = maximum((wl - elevation_[cell] - attenuation[cell], 0.0f0))

            # If the inundation depth is greater than 0.0 and not sea, propagate to neighbors
            if inundation_depth[cell] > 0.0f0

                # Get neighbors of the current cell
                nbs = neighbours(elevation_, cell, cursor=profile.cursor; returndist = true) |> values |> collect |> x -> filter(!isnothing, x)

                for (nb, distance) in nbs
    
                    # Skip neighbor if the neighbor is out of bounds
                    if isnothing(nb)
                        continue
                    end

                    # Assign path ID to the neighbor
                    paths[nb] = paths[cell]
                    # Calculate the attenuation rate for the neighbor
                    if attrate isa Real
                        rate = attrate
                    else
                        rate = (attrate[cell] / 2 + attrate[nb] / 2)
                        # @info "Calculate rate_ from cell $(cell) to neighbor $(nb): $(rate)"
                    end

                    # Apply the attenuation rate to the neighbor
                    new_attenuation = attenuation[cell] + (rate * (distance))
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

    exports = Dict(
        :attenuation => attenuation, 
        :propagation => propagation, 
        :path => paths,
        :inundation_depth => inundation_depth
    )

    if returnpaths
        return inundation_depth, paths  # return the inundation depth matrix and paths
    elseif returnall
        return exports
    else
        return inundation_depth
    end

end



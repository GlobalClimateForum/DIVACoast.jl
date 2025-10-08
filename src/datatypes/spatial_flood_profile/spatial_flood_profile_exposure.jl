"""
    function exposure(profile::SpatialFloodProfile, profilemask::SpatialFloodProfileMask, wl::Real, im::Union{HydraulicConnectedBathtub, PathBasedAttenuatedBathtub}) where IM <: InundationModel

Calculates the cumulative exposure of a `SpatialFloodProfile` and its `SpatialFloodProfileMask` given a water level and an inundation model.
# Arguments
- `profile::SpatialFloodProfile`: The spatial flood profile containing elevation and exposure data.
- `profilemask::SpatialFloodProfileMask`: The mask defining the sea area and the coastline. 
- `wl::Real`: The water level for the inundation model.
- `im::Union{HydraulicConnectedBathtub, PathBasedAttenuatedBathtub}`: The inundation model to use for calculating inundation depth.
# Returns
- `Vector{Real}`: A vector containing the cumulative exposure for each exposure layer in the profile.
"""
function exposure(profile::SpatialFloodProfile, profilemask::SpatialFloodProfileMask, wl::Real, im::Union{HydraulicConnectedBathtub, PathBasedAttenuatedBathtub}) where IM <: InundationModel

    inundation_depth = inundate(profile, profilemask, wl, im)

    inundated = falses(size(inundation_depth))
    inundated[inundation_depth .> 0] .= true

    exp_ = []

    for exposure in (profile.exposures)
        exposed = sum(exposure[inundated])
        push!(exp_, exposed)
    end
       
    return exp_
end

function exposure(profile, inundation_arr::AbstractArray{R, 2}) where R <: Real

    inundated = falses(size(profile.exposures[1]))

    @info "$(size(inundated)) vs $(size(inundation_arr))"
    inundated[inundation_arr .> 0] .= true

    exp_ = []

    for exposure in (profile.exposures)
        exposed = sum(exposure[inundated])
        push!(exp_, exposed)
    end
       
    return exp_
end


"""
Inundates the `SpatialFloodProfile` using a specified water level and inundation model. Inundation takes place according
to the provided `SpatialFloodProfileMask`.
# Arguments
- `profile::SpatialFloodProfile`: The spatial flood profile containing elevation and exposure data.
- `profilemask::SpatialFloodProfileMask`: The mask defining the sea area and the coastline.
- `wl::Real`: The targeted water level.
- `im::Union{HydraulicConnectedBathtub, PathBasedAttenuatedBathtub}`: The inundation model to use for calculating inundation depth.
"""
function inundate(profile::SpatialFloodProfile, profilemask::SpatialFloodProfileMask,
    wl::Real, im::Union{HydraulicConnectedBathtub, PathBasedAttenuatedBathtub}) where IM <: InundationModel

    if im isa PathBasedAttenuatedBathtub
        inundation_depth = path_based_attenuated_inundation(profile, profilemask, wl, im.attrate)
    elseif im isa HydraulicConnectedBathtub
        inundation_depth = flood_fill(profile, wl; profile_mask = profilemask)
    end

    return inundation_depth
end


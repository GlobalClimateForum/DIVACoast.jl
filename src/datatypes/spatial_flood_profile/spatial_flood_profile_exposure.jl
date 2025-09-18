function exposure(profile::SpatialFloodProfile, profilemask::SpatialFloodProfileMask, wl::Real, im::Union{HydraulicConnectedBathtub, PathBasedAttenuatedBathtub}) where IM <: InundationModel

    if im isa PathBasedAttenuatedBathtub
        inundation_depth = path_based_attenuated_inundation(profile, profilemask, wl, im.attrate)
    elseif im isa HydraulicConnectedBathtub
        inundation_depth = flood_fill(profile, wl; profile_mask = profilemask)
    end

    area_ = sum(inundation_depth .> 0.0)
    e_ = Tuple([sum(exp_[inundation_depth .> 0.0]) for exp_ in profile.exposures])
    exposed_ = (area_, e_)

    return exposed_
end

function inundate(profile::SpatialFloodProfile, profilemask::SpatialFloodProfileMask,
    wl::Real, im::Union{HydraulicConnectedBathtub, PathBasedAttenuatedBathtub}; 
    exportdir = nothing) where IM <: InundationModel

    if im isa PathBasedAttenuatedBathtub
        inundation_depth = path_based_attenuated_inundation(profile, profilemask, wl, im.attrate)
    elseif im isa HydraulicConnectedBathtub
        inundation_depth = flood_fill(profile, wl; profile_mask = profilemask)
    end

    return inundation_depth
end


function damage(profile::SpatialFloodProfile, wl::Real, s::Array{String}, ddfs::Vector{Function}, im::IM = HydraulicConnectedBathtub(profile.seed)) where IM <: InundationModel
    
    inundation_depth = flood_fill(profile, im.seed, wl)
    damages = map(wl -> ddf(wl), findall(inundation_depth .> 0.0))

    area_ = sum(flooded_mask) 
    e_ = Tuple([sum(exp_[flooded_mask]) for exp_ in profile.exposures])
    exposed_ = (area_, e_)
    
    damages = [ddf(exposed_, wl) for ddf in ddfs]
    
    return exposed_, damages

end



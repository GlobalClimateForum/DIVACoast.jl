"""
    function exposure(profile::SpatialProfile, profilemask::SpatialProfileMask, wl::Real, im::Union{HydraulicConnectedBathtub, PathBasedAttenuatedBathtub})

Calculates the cumulative exposure of a `SpatialProfile` and its `SpatialProfileMask` given a water level and an inundation model.
# Arguments
- `profile::SpatialProfile`: The spatial flood profile containing elevation and exposure data.
- `profilemask::SpatialProfileMask`: The mask defining the sea area and the coastline. 
- `wl::Real`: The water level for the inundation model.
- `im::Union{HydraulicConnectedBathtub, PathBasedAttenuatedBathtub}`: The inundation model to use for calculating inundation depth.
# Returns
- `Vector{Real}`: A vector containing the cumulative exposure for each exposure layer in the profile.
"""
function exposure(profile::SpatialProfile, wl::Real, im::Union{HydraulicConnectedBathtub, PathBasedAttenuatedBathtub})

    inundation_depth = inundate(profile, wl, im)

    inundated = falses(size(inundation_depth))
    inundated[inundation_depth .> 0] .= true

    print("SIZE INUNDATION: $(size(inundation_depth)), SIZE EXPOSURE: $(size(profile.exposures[1]))\n")

    exp_ = []  
    for exposure in (profile.exposures)
        exposed = sum(exposure[inundated])
        push!(exp_, exposed)
    end
       
    return exp_
end

function exposure(profile, inundation_arr::Union{GeoArrays.GeoArray}) 

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

# function exposure(profile::SpatialProfile, wl::Vector{Real}, im::Union{HydraulicConnectedBathtub, PathBasedAttenuatedBathtub})

#     wl = sort(wl) 
#     inundation_depth = Vector{GeoArrays.GeoArray}(undef, lenght(wl))

#     profile_ = deepcopy(profile)

#     for (i, w) in enumerate(wl) 
        
#         if i > 1
#             profile.mask = SpatialProfileMask(
#                 inundation_depth[1], 
#                 Inf
#             ) 
#         end
        
#         inundation_depth[i] = inundate(profile, w, im)
#     end

# end

function damage(profile::SpatialProfile, wl::Real, s::Array{String}, ddfs::Vector{Function}, im::IM = HydraulicConnectedBathtub(profile.seed)) where IM <: InundationModel
    
    inundation_depth = flood_fill(profile, im.seed, wl)
    damages = map(wl -> ddf(wl), findall(inundation_depth .> 0.0))

    area_ = sum(flooded_mask) 
    e_ = Tuple([sum(exp_[flooded_mask]) for exp_ in profile.exposures])
    exposed_ = (area_, e_)
    
    damages = [ddf(exposed_, wl) for ddf in ddfs]
    
    return exposed_, damages

end

"""
Inundates the `SpatialProfile` using a specified water level and inundation model. Inundation takes place according
to the provided `SpatialProfileMask`.
# Arguments
- `profile::SpatialProfile`: The spatial flood profile containing elevation and exposure data.
- `wl::Real`: The targeted water level.
- `im::Union{HydraulicConnectedBathtub, PathBasedAttenuatedBathtub}`: The inundation model to use for calculating inundation depth.
"""
function inundate(sp::SpatialProfile, wl::Real, im::Union{HydraulicConnectedBathtub, PathBasedAttenuatedBathtub}) 
    if im isa HydraulicConnectedBathtub
        inundation_depth = flood_fill(sp, wl) 
    elseif im isa PathBasedAttenuatedBathtub
        inundation_depth = path_based_attenuated_inundation(sp, wl, im.attrate)
    end
    return inundation_depth
end




"""
    function inundate(hspf::HypsometricProfile, wl::Number, im::IM)  where {DT<:Real,IM<:InundationModel}

The `inundate` function computes the complete flood inundation for each elevation of a given HypsometricProfile and a given water level and InundationModel.

# Arguments
- `hspf::HypsometricProfile`: the hypsometric profile object which will be flooded.
- `wl::Number`: the water level that is propagated on the hypsometric profile.
- `im::IM`: the inundation model defining how the water is propagated on the hypsometric profile.

# Output
- two tuple of arrays, the first array returns the elevation of the hypsometric profile, the second array returns the water level per respective elevation (the arrays stop when no inundation happens)

# Example
```julia
inundate(hspf, 2.0, BathtubInundation)
```
"""
function inundate(hspf::HypsometricProfile{DT}, wl::Number, im::IM)::Tuple{Array{DT},Array{DT}} where {DT<:Real,IM<:InundationModel}
    @error("fallback")
end

function inundate(hspf::HypsometricProfile{DT}, wl::Number, im::IM)::Tuple{Array{DT},Array{DT}} where {DT<:Real,IM<:BathtubInundation}
    ind::Int64 = searchsortedfirst(hspf.elevation, wl)
    if (wl in hspf.elevation)
        return (hspf.elevation[1:ind], repeat([convert(DT, wl)], ind))
    else
        if (ind == 1)
            return ([hspf.elevation[1]], [wl])
        end
        if (ind > size(hspf.elevation, 1))
            ret = copy(hspf.elevation)
            push!(ret, wl)
            return (ret, map(x -> convert(DT, wl), ret))
        end
        ret = hspf.elevation[1:ind-1]
        push!(ret, wl)
        return (ret, map(x -> convert(DT, wl), ret))
    end
end

function inundate(hspf::HypsometricProfile{DT}, wl::Number, im::IM)::Tuple{Array{DT},Array{DT}} where {DT<:Real,IM<:LinearDistanceAttenuatedInundation}
    if !isdefined(hspf, :distance) && !isdefined(hspf, :slope)
        return private_inundate(hspf, wl, im)
    else
        return private_inundate(hspf, wl, im, hspf.distance, hspf.slope)
    end
end

function private_inundate(hspf::DIVACoast.HypsometricProfile{DT}, wl::Real, im::IM, distances::Vector{DT}, slopes::Vector{DT})::Tuple{Vector{DT},Vector{DT}} where {DT<:Real,IM<:DIVACoast.LinearDistanceAttenuatedInundation}

    # Guard clause: If the water level is below the first elevation, nothing is inundated, return the first elevation and the water level as the only point in the profile.
    if wl <= hspf.elevation[1]
        return ([hspf.elevation[1]], [DT(wl)])
    end

    # Get the index of the last elevation that is less than or equal to the water level, 
    # this will be the maximum index in the elevation profile that we need to consider for inundation 
    # As this is a sorted array, we can use searchsortedlast for efficient lookup (binary-search = cheap = O(log(n)))

    elev_idx_max = searchsortedlast(hspf.elevation, wl)

    # As we now know the maximum index of the elevation profile that we need to consider, 
    # we can pre-allocate the return arrays with the appropriate size (elev_idx_max + 1 to account for the potential intersection point)
    ret_elev = Vector{DT}(undef, elev_idx_max + 1)
    ret_wl   = Vector{DT}(undef, elev_idx_max + 1)

    # We also now that the first point in the return profile will always be the first elevation and the water level, so we can set that directly
    # Setting values in a pre-allocated array is cheaper than pushing values to a dynamically growing array, 
    # as it avoids the overhead of resizing and copying the array when it grows beyond its current capacity
    ret_elev[1] = hspf.elevation[1]
    ret_wl[1]   = wl

    # We still need to track the current index, as we could break out of the loop before reaching elev_idx_max,
    # if the water level is attenuated below the elevation at some point in the profile
    ind = 1 # Current step in the elevation profile

    # We start at the second point in the elevation profile
    for i in 2:elev_idx_max
        
        # We calculate the cumulative attenuation of the water level at the current point in the elevation profile
        Δ_wl_att_sum = distances[i] * im.attenuation_rate
        # We then calculate the attenuated water level at the current point in the elevation profile
        wl_att = wl - Δ_wl_att_sum

        # No we check if the attenuated water level is still above the elevation at the current point in the elevation profile,
        # if it is, we add the current point in the elevation profile and the attenuated water level to the return vectors
        if wl_att >= hspf.elevation[i]
            ret_elev[i] = hspf.elevation[i]
            ret_wl[i]   = wl_att
            ind = i
        # Else, we hit the point in the elevation profile where the water level is attenuated below the elevation, and we can break out of the loop, 
        # as we know that no further points in the elevation profile will be inundated
        else
            break
        end
    end

    # Now we want to determine the exact point of intersection between the water level and the elevation profile

    # Case 1: The loop reached the end of the profile without breaking, which means no intersection needed.
    if ind == length(hspf.elevation)
        resize!(ret_elev, ind)  # Remove the last reserved slot for the potential intersection point, as it is not needed
        resize!(ret_wl, ind) # Remove the last reserved slot for the potential intersection point, as it is not needed
        return (ret_elev, ret_wl)
    # Case 2: The loop broke before reaching the end of the profile, which means we need to calculate the intersection point 
    # and add it to the return vectors
    else

        # First we calculate the slope of the elevation profile at the point of intersection, 
        # which is the current index in the elevation profile where the loop broke, multiplied by 1000 to convert from m/m to m/km
        sl = slopes[ind + 1] * 1000
        d_intersect = (ret_wl[ind] - hspf.elevation[ind]) / (sl + im.attenuation_rate)
        intersect_val = hspf.elevation[ind] + sl * d_intersect
        ret_elev[ind + 1] = intersect_val
        ret_wl[ind + 1]   = intersect_val
        resize!(ret_elev, ind + 1)
        resize!(ret_wl, ind + 1)
        return (ret_elev, ret_wl)
    end
end

function private_inundate(hspf::HypsometricProfile{DT}, wl::Real, im::IM)::Tuple{Array{DT},Array{DT}} where {DT<:Real,IM<:LinearDistanceAttenuatedInundation}
    if (wl <= hspf.elevation[1])
        return ([hspf.elevation[1]], [wl])
    end

    wl_attenuated = copy(hspf.elevation)
    wl_attenuated[1] = wl

    ind = 1
    Δ_wl_att_sum = 0
    found_break = false

    while !found_break
        if (ind >= size(hspf.elevation, 1))
            found_break = true
        else
            Δ_wl_att_part = (distance(hspf, hspf.elevation[ind+1]) - distance(hspf, hspf.elevation[ind])) * im.attenuation_rate
            if wl - Δ_wl_att_sum >= hspf.elevation[ind+1]
                Δ_wl_att_sum += Δ_wl_att_part
                ind += 1
                wl_attenuated[ind] = wl - Δ_wl_att_sum
            else
                found_break = true
            end
        end
    end

    if (ind == size(hspf.elevation, 1))
        Δ_wl_att_part = (distance(hspf, hspf.elevation[ind])-distance(hspf, hspf.elevation[ind-1])) * im.attenuation_rate
        Δ_wl_att_sum += Δ_wl_att_part
        wl_attenuated[ind] = wl - Δ_wl_att_sum
        return (hspf.elevation, wl_attenuated)
    end

    d = distance(hspf, hspf.elevation[ind])
    sl = slope(hspf, ind + 1) * 1000 # (sl is now in m/km)
    d_intersect = (wl_attenuated[ind] - hspf.elevation[ind]) / (sl + im.attenuation_rate)

    ret_el = hspf.elevation[1:ind]
    ret_wl = wl_attenuated[1:ind]
    push!(ret_el, hspf.elevation[ind] + sl * d_intersect)
    push!(ret_wl, hspf.elevation[ind] + sl * d_intersect)

    return (ret_el, ret_wl)
end

"""
    
    function water_level(hspf::HypsometricProfile{DT}, wl::Number, el::Number, im::IM)::DT where {DT<:Real,IM<:InundationModel}

The `water_level` function computes the water level on a HypsometricProfile given a water level wl at the coast, an elevation el and InundationModel. Returns zero if the water cannot reach the elevation.

# Arguments
- `hspf::HypsometricProfile`: the hypsometric profile object which will be flooded.
- `wl::Number`: the water level that is propagated on the hypsometric profile.
- `im::IM`: the inundation model defining how the water is propagated on the hypsometric profile.

# Output
- the water level at elevation el (relative to the reference of the given water level), or zero if the water cannot reach this elevation

# Example
```julia
water_level(hspf, 3.4, 2.5, BathtubInundation)
```
"""

function water_level(hspf::HypsometricProfile{DT}, wl::Number, el::Number, im::IM)::DT where {DT<:Real,IM<:InundationModel}
    @error("fallback")
end

@inline function water_level(hspf::HypsometricProfile{DT}, wl::Number, el::Number, im::IM)::DT where {DT<:Real,IM<:BathtubInundation}
    if (el >= wl)
        convert(DT, 0.0)
    else
        convert(DT, wl)
    end
end

function water_level(hspf::HypsometricProfile{DT}, wl::Number, el::Number, im::IM)::DT where {DT<:Real,IM<:LinearDistanceAttenuatedInundation}
    if (wl <= hspf.elevation[1])
        return 0.0
    end

    ind = 1
    Δ_wl_att_sum = 0
    found_break = false

    while !found_break
        if (ind >= size(hspf.elevation, 1))
            found_break = true
        else
            if el <= hspf.elevation[ind+1]
                found_break = true
            else
                Δ_wl_att_part = (distance(hspf, hspf.elevation[ind+1]) - distance(hspf, hspf.elevation[ind])) * im.attenuation_rate
                if wl - Δ_wl_att_sum <= 0
                    return 0
                end
                if wl - Δ_wl_att_sum >= hspf.elevation[ind+1]
                    Δ_wl_att_sum += Δ_wl_att_part
                    ind += 1
                else
                    found_break = true
                end
            end
        end
    end

    if (ind >= size(hspf.elevation, 1))
        # interpolate further upwards?
        return (wl - Δ_wl_att_sum)
    end

    d = distance(hspf, hspf.elevation[ind])
    sl = slope(hspf, ind + 1) * 1000 # (sl is now in m/km)
    y_el = d * sl - hspf.elevation[ind]
    y_wl = d * im.attenuation_rate + (wl - Δ_wl_att_sum)
    d_intersect = (y_wl - y_el) / (sl + im.attenuation_rate)
    d_el = distance(hspf, el)

    if (d_el > d_intersect)
        return 0.0
    end

    Δ_wl_att_part = (d_el - distance(hspf, hspf.elevation[ind])) * im.attenuation_rate
    Δ_wl_att_sum += Δ_wl_att_part

    return (wl - Δ_wl_att_sum)
end


@inline function max_water_level(hspf::HypsometricProfile{DT}, wl::Real, im::IM)::DT where {DT<:Real,IM<:InundationModel}
    @error("fallback")
end

@inline function max_water_level(hspf::HypsometricProfile{DT}, wl::Real, im::IM)::DT where {DT<:Real,IM<:BathtubInundation} 
    wl
end

function max_water_level(hspf::HypsometricProfile{DT}, wl::Real, im::IM)::DT where {DT<:Real,IM<:LinearDistanceAttenuatedInundation}
    water_levels=inundate(hspf, wl, im)
    last(water_levels)[2]
end


"""
    
    function water_depth(hspf::HypsometricProfile{DT}, wl::Number, el::Number, im::IM)::DT where {DT<:Real,IM<:InundationModel}

The `water_depth` function computes the water depth on a HypsometricProfile given a water level wl at the coast, an elevation el and InundationModel. Returns zero if the water cannot reach the elevation.

# Arguments
- `hspf::HypsometricProfile`: the hypsometric profile object which will be flooded.
- `wl::Number`: the water level that is propagated on the hypsometric profile.
- `im::IM`: the inundation model defining how the water is propagated on the hypsometric profile.

# Output
- the water depth at elevation el, or zero if the water cannot reach this elevation

# Example
```julia
water_depth(hspf, 3.4, 2.5, BathtubInundation)
```
"""
function water_depth(hspf::HypsometricProfile{DT}, wl::Number, el::Number, im::IM)::DT where {DT<:Real,IM<:InundationModel} 
    if (el >= wl)
        convert(DT, 0.0)
    else
        water_level(hspf, wl, el, im) - el
    end
end
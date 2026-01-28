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

function inundate(hspf::HypsometricProfile{DT}, wl::Real, im::IM)::Tuple{Array{DT},Array{DT}} where {DT<:Real,IM<:LinearDistanceAttenuatedInundation}
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
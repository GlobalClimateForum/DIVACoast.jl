"""
    function inundate(hspf::HypsometricProfile, wl::Number, im::IM)  where {DT<:Real,IM<:InundationModel}

The `inundate` function models the flood inundation for each elevation of a given HypsometricProfile and a given water level and InundationModel.

output: tuple of two arrays, first array gives elevation, second one water level per respective elevation (the arrays stop when no inundation happens)


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
function inundate(hspf::HypsometricProfile{DT}, wl::Number, im::IM) ::Tuple{Array{DT}, Array{DT}} where {DT<:Real,IM<:InundationModel}
    @error("fallback")
end

function inundate(hspf::HypsometricProfile{DT}, wl::Number, im::IM)::Tuple{Array{DT}, Array{DT}} where {DT<:Real,IM<:BathtubInundation}
    ind::Int64 = searchsortedfirst(hspf.elevation, wl)
    if (wl in hspf.elevation)
        return (hspf.elevation[1:ind], repeat([convert(DT,wl)],ind))
    else
        if (ind == 1)
            return ([hspf.elevation[1]],[wl])
        end
        if (ind > size(hspf.elevation, 1))
            ret = copy(hspf.elevation)
            push!(ret, wl)
            return (ret, map(x -> convert(DT,wl), ret))
        end
        ret = hspf.elevation[1:ind-1]
        push!(ret, wl)
        return (ret, map(x -> convert(DT,wl), ret))
    end
end

function inundate(hspf::HypsometricProfile{DT}, wl::Real, im::IM)::Tuple{Array{DT}, Array{DT}} where {DT<:Real,IM<:LinearDistanceAttenuatedInundation}

    if (wl <= hspf.elevation[1])
        return (hspf.elevation[1],wl)
    end

    wl_attenuated = copy(hspf.elevation)
    wl_attenuated[1] = wl

    ind = 2
    Δ_wl_att_part = (distance(hspf, hspf.elevation[ind]) - distance(hspf, hspf.elevation[ind-1])) * im.attenuation_rate
    Δ_wl_att_sum = Δ_wl_att_part

    while ((Δ_wl_att_sum <= wl) && (ind <= size(hspf.elevation, 1)) && (wl - Δ_wl_att_sum >= hspf.elevation[ind]))
        wl_attenuated[ind] = wl - Δ_wl_att_sum
        ind += 1
        Δ_wl_att_part = (distance(hspf, hspf.elevation[ind]) - distance(hspf, hspf.elevation[ind-1])) * im.attenuation_rate
        Δ_wl_att_sum += Δ_wl_att_part
    end

    if (ind > size(hspf.elevation, 1))
        return (hspf.elevation, wl_attenuated)
    end
    
    if (wl - Δ_wl_att_sum < hspf.elevation[ind]) || (Δ_wl_att_sum > wl)
        ret_el = hspf.elevation[1:ind-1]
        ret_wl = wl_attenuated[1:ind-1]
        sl = slope(hspf, ind-1) 
        d_temp = (wl_attenuated[ind-1] - hspf.elevation[ind-1]) / (sl + im.attenuation_rate)
        (push!(ret_el, hspf.elevation[ind-1] + sl * d_temp),push!(ret_wl, hspf.elevation[ind-1] + sl * d_temp))
    end

end
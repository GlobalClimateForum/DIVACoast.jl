using DataFrames
using CSV
using Tables

"""
    function land_raising!(hspf::HypsometricProfile{Float32}, min_e::DT) where {DT<:Real}

The `land_raising!` function raises the elevation of a given hypsometric profile to a minimum elevation height min_e. 
The function returns the volume of land raised in m³.

# Arguments
- `hspf::HypsometricProfile`: the hypsometric profile object where the land will be raised.
- `min_elevation::Array{DT}`: the elevation increments that are below this threshold will be raised to this value.

# Example
```julia
volume = land_raising!(hspf, 2.0)
```
"""
function land_raising!(hspf::HypsometricProfile{Float32}, min_elevation::DT) where {DT<:Real}
    hp = deepcopy(hspf) # Create a copy of the HypsometricProfile
    idx = searchsortedfirst(hspf.elevation, min_elevation)
    # check if min_elevation is higher than current lowest elevation
    if min_elevation < hp.elevation[1]
        @warn "Minimum elevation $(min_elevation) is lower than current lowest elevation $(hspf.elevation[1]). No land raising applied."
        return
    end
    #if min elevation is between two element values of the elevation array, insert interpolated values
    if idx <= length(hspf.elevation) && min_elevation != hspf.elevation[idx] 
        #insert!(hspf.elevation, idx, min_elevation)
        # Insert new values in exposure arrays
        #hspf.cumulativeArea = [hspf.cumulativeArea[1:idx-1, :]; exposure(hp, min_elevation)[1]; hspf.cumulativeArea[idx:end, :]]
        #hspf.cumulativeExposure = [hspf.cumulativeExposure[1:idx-1, :]; exposure(hp, min_elevation)[2]'; hspf.cumulativeExposure[idx:end, :]]
        insert_elevation_point(hspf, min_elevation, idx)
    end

    #calculate volume needed to raise land
    area = vcat(0,[hspf.cumulativeArea[i]-hspf.cumulativeArea[i-1] for i in 2:length(hspf.cumulativeArea)])
    volume = sum([area[i] .* 1000000 .* (2.0.*min_elevation.-hspf.elevation[i-1].- hspf.elevation[i])./2 for i in 2:minimum([idx,length(hspf.elevation)])])
    
    if min_elevation > hp.elevation[end]
        # if new elevation is higher than entire floodplain, create new hp values that contain zero and entire area/exposure
        hspf.elevation = [min_elevation, min_elevation]
        hspf.cumulativeArea = [0f0, hspf.cumulativeArea[end]]
        hspf.cumulativeExposure = vcat(zeros(eltype(hspf.cumulativeExposure), 1, size(hspf.cumulativeExposure, 2)), hspf.cumulativeExposure[end,:]')
        
        #return volume of land raised
        return volume
    else
        #Remove all elements < min_elevation in elevation and cummulated area/exposure 
        deleteat!(hspf.elevation, 1:idx-1)
        hspf.cumulativeArea = hspf.cumulativeArea[idx:end,:]
        hspf.cumulativeExposure = hspf.cumulativeExposure[idx:end,:]
        
        # Insert new values with min_elevation and zero area/exposure
        insert!(hspf.elevation, 1, min_elevation)
        hspf.cumulativeArea = vcat(0f0, hspf.cumulativeArea) 
        hspf.cumulativeExposure = vcat(zeros(eltype(hspf.cumulativeExposure), 1, size(hspf.cumulativeExposure, 2)), hspf.cumulativeExposure)
        
        #return volume of land raised 
        return volume
    end
end

# Function to add two exposure tuples exposure_1 and exposure_2
function add_exposures(exposure_1::Tuple{Vararg{Union{Number, AbstractArray{<:Number}}}},
    exposure_2::Tuple{Vararg{Union{Number, AbstractArray{<:Number}}}})::Vector{Union{Array, Number}}
    
    exposure = Vector{Union{Array, Number}}(undef, length(exposure_1))
    for (i, (e1, e2)) in enumerate(zip(exposure_1, exposure_2))
        if isa(e1, Array) && isa(e2, Array)
            exposure[i] = e1 .+ e2
        elseif isa(e1, Number) && isa(e2, Number)
            exposure[i] = e1 + e2
        else
            @warn "$(typeof(e1)) + $(typeof(e2))"
            throw("Can't add Exposure Values of different types.")
        end
    end
    return exposure
end

"""
        function Base.:+(hspf1::HypsometricProfile{Float32}, hspf2::HypsometricProfile{Float32})

Addtion of two Hypsometric Profiles. Adds (combines) the folling properties of the HypsometricProfiles:

# Arguments
- Elevation: Combine Increments
- width: Adds the width of both HypsometricProfiles
- cumulativeArea: Adds the cumulative are of both HypsometricProfiles
- static Exposure: Adds the cumulative static exposure of both HypsometricProfiles
"""
function Base.:+(hspf1::HypsometricProfile{Float32}, hspf2::HypsometricProfile{Float32})

    get_units = (hp) -> [getfield(hp, sym) for sym in fieldnames(typeof(hp)) if occursin("unit", lowercase(String(sym)))]
    # Sanity check
    if !isequal(get_units(hspf1), get_units(hspf2))
        @warn "$(get_units(hspf1)) != $(get_units(hspf2))"
        throw("Can't add HypsometricProfiles of different units.")
    else
        hspfc = deepcopy(hspf1)
        hspfc.width = hspf1.width + hspf2.width

        # Combine elevation increments
        hspfc.elevation = vcat(hspf1.elevation, hspf2.elevation) |> sort |> unique
        
        # Get Exposure Values at elevation increment & combine assets
        hspf1_exposures  = map(e -> exposure(hspf1, e), hspfc.elevation)
        hspf2_exposures  = map(e -> exposure(hspf2, e), hspfc.elevation)
        exposures = map(add_exposures, hspf1_exposures, hspf2_exposures)

        hspfc.cummulativeArea = getindex.(exposures, 1)
        hspfc.cummulativeExposure = transpose(reduce(hcat, getindex.(exposures, 2)))
            end
    return hspfc
end
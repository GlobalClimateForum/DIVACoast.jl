using DataFrames
using CSV

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
- cummulativeArea: Adds the cummulative are of both HypsometricProfiles
- static Exposure: Adds the cummulative static exposure of both HypsometricProfiles
- dynamic Exposure: Adds the dynamic exposure of both HypsometricProfiles
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
        hspf1_exposures  = map(e -> exposure_below(hspf1, e), hspfc.elevation)
        hspf2_exposures  = map(e -> exposure_below(hspf2, e), hspfc.elevation)
        exposures = map(add_exposures, hspf1_exposures, hspf2_exposures)

        hspfc.cummulativeArea = getindex.(exposures, 1)
        hspfc.cummulativeStaticExposure =  reduce(hcat, getindex.(exposures, 2))
        hspfc.cummulativeDynamicExposure  = reduce(hcat, getindex.(exposures, 3))
        
        # hspfc.cummulativeDynamicExposure = reduce(hcat, [exp[3] for exp in exposures])
        
        # Adding / recalc of distances is missing
    end
    return hspfc
end

"""
        to_DF(hspf::HypsometricProfile{DT}) where {DT<:Real}

Convert a `HypsometricProfile` to a DataFrame. The DataFrame will contain the following columns: 
- elevation
- cummulativeArea
- a column for each exposure

# Arguments
- hspf::HypsometricProfile{DT}: The `HypsometricProfile` to convert.

# Returns
- df::DataFrame: A DataFrame containing the elevation, cummulativeArea, and exposure values of the `HypsometricProfile`.

# Example
```julia
hspf = load_hspf_nc(Int32, Float32, "./testdata/UKIRL/nc/UKIRL_hspfs_floodplains.nc")[42]
df = to_DF(hspf)
```
"""
function to_DF(hspf::HypsometricProfile{DT}) where {DT<:Real}
    df = DataFrame()
    df.elevation = hspf.elevation
    df.cummulativeArea = hspf.cummulativeArea
    # Try both cummulativeStaticExposure and cummulativeExposure for compatibility
    exposure_field = hasproperty(hspf, :cummulativeExposure) ? :cummulativeExposure : :cummulativeStaticExposure
    exposures = getfield(hspf, exposure_field)
    symbols = hasproperty(hspf, :exposureSymbols) ? hspf.exposureSymbols : []
    for i in 1:size(exposures, 2)
        colname = string(symbols[i])
        df[!, colname] = exposures[:, i]
    end
    return df
end

function to_DF(hspfs::Dict{Int32, Main.DIVACoast.HypsometricProfile{Float32}})

    dfs = [nothing for _ in 1:size(hspf, 1)]

    for (id, hspf) in hspfs
        pritnln(id)
    end
    return dfs
end

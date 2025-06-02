using DataFrames
using CSV

"""
    function land_raising!(hspf::HypsometricProfile{Float32}, min_e::DT) where {DT<:Real}

The `land_raising!` function raises the elevation of a hypsometric profile to a minimum elevation height min_e.

# Arguments
- `hspf::HypsometricProfile`: the hypsometric profile object where the land will be raised.
- `min_elevation::Array{DT}`: the elevation increments that are below this threshold will be raised to this value.

# Example
```julia
land_raising!(hspf, 2.0)
```
"""
function land_raising!(hspf::HypsometricProfile{Float32}, min_elevation::DT) where {DT<:Real}
    hspf.elevation = [maximum([i,min_elevation]) for i in hspf.elevation] 
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
    
    # Init DataFrame
    df = DataFrame()

    # Add elevation and cummulativeArea columns
    df.elevation = hspf.elevation
    df.cummulativeArea = hspf.cummulativeArea
    df.width = fill(hspf.width, size(df, 1))
    
    # Get cummulativeExposure values
    exposures = getfield(hspf, :cummulativeExposure)
   
    # Add cummulativeExposure columns to DataFrame
    symbols = hasproperty(hspf, :exposureNames) ? hspf.exposureNames : []
    for i in 1:size(exposures, 2)
        colname = string(symbols[i])
        df[!, colname] = exposures[:, i]
    end
    return df
end

function to_DF(hspfs::Dict{Int32, Main.DIVACoast.HypsometricProfile{Float32}})
    dfs = [begin
        hspf = to_DF(value)
        hspf.HP_ID = fill(key, size(hspf, 1)) # Add the key as ID for the HypsometricProfile
        hspf
        select!(hspf, :HP_ID, :) # re-order columns to have HP_ID first
        end for (key, value) in hspfs
            ]
    return vcat(dfs...) # Concatenate all HypsometricProfile DataFrames into one DataFrame
end

# Not working yer, needs to be fixed
function HypsometricProfile(df::DataFrame, ref::HypsometricProfile, exposureCols = Symbol[])

    hspf = deepcopy(ref)
    
    # Set the properties of the HypsometricProfile
    hspf.elevation = df.elevation
    hspf.cummulativeArea = df.cummulativeArea
    hspf.width = df.width[1]
    
    # Set the exposure values
    if isempty(exposureCols)
        @warn "No exposure columns provided, using all columns except elevation, cummulativeArea, and width."
        exposureCols = filter(x -> !(x in [:elevation, :cummulativeArea, :width]), names(df))
    else
        exposureCols = filter(x -> (x in names(df)) && !(x in [:elevation, :cummulativeArea, :width]), exposureCols)
    end
    
    exposures = [df[!, col] for col in exposureCols] 
    hspf.cummulativeExposure = hcat(exposures...)
    
    fnames = filter(x -> !(x in [:cummulativeExposure, :elevation, :cummulativeArea, :width]), fieldnames(typeof(hspf)))
    
    # Copy other properties from the reference HypsometricProfile
    for field in fnames
        if hasproperty(hspf, field)
            setfield!(hspf, field, getfield(ref, field))
        end
    end
    
    return hspf
end

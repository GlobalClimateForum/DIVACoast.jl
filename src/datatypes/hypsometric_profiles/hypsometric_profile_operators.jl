include("$(ENV["DIVA_LIB"])/src/DIVACoast.jl")
# include("$(ENV["DIVA_DATA"])/testdata/hypsometricprofiles.jl")

using .DIVACoast
using DataFrames
using CSV

data = (subdir) -> "$(ENV["DIVA_DATA"])/$(subdir)"

floodplains_hp_path = data("dataset_global/nc/Global_hspfs_floodplains_merit_deltadtm1_0.nc")
hp_floodplains = load_hsps_nc(Int32, Float32, floodplains_hp_path)

Base.global_logger(DIVALogger())

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
Addtion of two Hypsometric Profiles. Adds (combines) the folling properties of the HypsometricProfiles:
- Elevation: Combine Increments
- width: Adds the width of both HypsometricProfiles
- cummulativeArea: Adds the cummulative are of both HypsometricProfiles
- static Exposure: Adds the cummulative static exposure of both HypsometricProfiles
- dynamic Exposure: Adds the dynamic exposure of both HypsometricProfiles
NOTE: Distances are not added, and need to be recalculated!
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
        hspf1_exposures  = map(e -> exposure_below_bathtub(hspf1, e), hspfc.elevation)
        hspf2_exposures  = map(e -> exposure_below_bathtub(hspf2, e), hspfc.elevation)
        exposures = map(add_exposures, hspf1_exposures, hspf2_exposures)
        
        hspfc.cummulativeArea = getindex.(exposures, 1)
        hspfc.cummulativeStaticExposure =  reduce(hcat, [exp[2] for exp in exposures])
        hspfc.cummulativeDynamicExposure = reduce(hcat, [exp[3] for exp in exposures])
        
        # Adding / recalc of distances is missing
    end
    return hspfc
end

hp1 = hp_floodplains[62626]
hp2 = hp_floodplains[62639]

hp3 = hp1 + hp2




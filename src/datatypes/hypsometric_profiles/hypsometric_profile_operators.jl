include("$(ENV["DIVA_LIB"])/src/jdiva_env.jl")
include("$(ENV["DIVA_LIB"])/src/jdiva_lib.jl")
# include("$(ENV["DIVA_DATA"])/testdata/hypsometricprofiles.jl")

using .jdiva
using DataFrames
using CSV

floodplains_hp_path = diva_data("dataset_global/nc/Global_hspfs_floodplains_merit_deltadtm1_0.nc")
hp_floodplains  = load_hsps_nc(Int32, Float32, floodplains_hp_path)

using .jdiva

Base.global_logger(DIVALogger())

function Base.:+(hspf1::HypsometricProfile{Float32}, hspf2::HypsometricProfile{Float32}) 
    
    get_units = (hp) -> [getfield(hp,sym) for sym in fieldnames(typeof(hp)) if occursin("unit", lowercase(String(sym)))]
    # Sanity checks
    # Check if units are the same
    if !isequal(get_units(hspf1),get_units(hspf2))
        @warn "$(get_units(hspf1)) != $(get_units(hspf2))"
        throw("Can't add HypsometricProfiles of different units.")
    else

    hspfc = deepcopy(hspf1)

    println(fieldnames(typeof(hspf1)))

    # Add width
    hspfc.width = hspf1.width + hspf2.width
    
    # Combine elevation increments
    hspfc.elevation = vcat(hspf1.elevation, hspf2.elevation) |> sort |> unique

    # Combine Area, StaticExposure, dynamicExposure
    for (index, elev) in enumerate(hspfc.elevation)

        ea1, es1, ed1 = exposure_below_bathtub(hspf1, elev)
        ea2, es2. ed2 = exposure_below_bathtub(hspf2, elev)
        
   end 

   hspf1.staticExposureSymbols
   hspf2.dynamicExposureSymbols


    # ( :cummulativeArea, :area_unit, :cummulativeStaticExposure, :staticExposureSymbols, :staticExposureUnits, :cummulativeDynamicExposure, :dynamicExposureSymbols, :dynamicExposureUnits, :logger)



    end 
end

hp1 = hp_floodplains[62626]
hp2 = hp_floodplains[62639]

hp3 = hp1 + hp2
# width::DT
# width_unit::String
# elevation::Array{DT}
# elevation_unit::String
# cummulativeArea::Array{DT}
# area_unit::String
# cummulativeStaticExposure::Array{DT,2}
# staticExposureSymbols
# staticExposureUnits::Array{String}
# cummulativeDynamicExposure::Array{DT,2}
# dynamicExposureSymbols
# dynamicExposureUnits::Array{String}
# #  distances::Array{DT}
# logger::ExtendedLogger



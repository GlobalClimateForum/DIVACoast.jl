module DIVACoast

import YAML

# Read local library configuration
config = YAML.load_file(joinpath(@__DIR__, "DIVACoast.jl.yml"), dicttype=Dict{Symbol,Any})

# Export global constants
export earth_circumference_km, earth_radius_km

# Export Base-functions
export convert, display, enumerate

# Export HypsometricProfile structs and functions
export HypsometricProfile, HypsometricProfileCollection, slope,
    unit, named, compress!, compress_multithread!, land_raising!

# Export HypsometricProfile - Exposure functions
export exposure, multiply_exposure!, multiply_exposure_above!, multiply_exposure_below!, 
    remove_exposure_below!, add_exposure, add_exposure_above!, add_exposure_between!, 
    add_exposure_variable!, remove_exposure_variable!

# Export HypsometricProfile - Damage functions
export damage, expected_damage

# Export Damage -  structs and functions
export StandardDDF

# Export Statistic Operations
export LinInt, linear_interp, support, probs, cdf, pdf, quantile, manual_integration

# Export Inundation Model - struct and functions
export InundationModel, BathtubInundation, LinearDistanceAttenuatedInundation, inundate, water_depth

# Export GeoArray adapter stuff
export read_geotiff_to_geoarray_2d, empty_geo_array, is_rotated, is_circular, no_data_value

# Export GeoArray I/O stuff
export read_geotiff_header!, read_geotiff_data_complete!

# Export GeoArray utilities stuff
export nh4, nh8, distance, area
export UpperLeft, LowerRight
export AbstractDirection, East, North, West, South

# Export SparseArray's for memory friendly data processing
export SparseArrayADOC, SparseArrayDOK

# Set constants from local config
earth_circumference_km = config[:earthCircumferenceKM]
earth_radius_km = config[:earthRadiusKM]

function __init__()

    DRAW_HEADER = config[:drawHeader]
    SHORT_HEADER = config[:shortHeader]

    # Header
    if DRAW_HEADER && SHORT_HEADER
        println("┌                                       ┐")
        println("│ DIVACoast.jl | © GLOBAL CLIMATE FORUM │")
        println("└                                       ┘")
    elseif DRAW_HEADER
        println("┌                                                      ┐")
        println("│~▗▄▄▄~~▗▄▄▄▖▗▖~~▗▖~▗▄▖~~▗▄▄▖~▗▄▖~~▗▄▖~~▗▄▄▖▗▄▄▄▖▄~▗▖█~│")
        println("│~▐▌~~█~~~█~~▐▌~~▐▌▐▌~▐▌▐▌~~~▐▌~▐▌▐▌~▐▌▐▌~~~~~█~~~~▗▖█~│")
        println("│~▐▌~~█~~~█~~▐▌~~▐▌▐▛▀▜▌▐▌~~~▐▌~▐▌▐▛▀▜▌~▝▀▚▖~~█~▄~~▐▌█~│")
        println("│~▐▙▄▄▀~▗▄█▄▖~▝▚▞▘~▐▌~▐▌▝▚▄▄▖▝▚▄▞▘▐▌~▐▌▗▄▄▞▘~~█~▀▄▄▞▘█~│")
        println("│~~~~~~~~~~~~~~~~[©GLOBAL CLIMATE FORUM]~~~~~~~~~~~~~~~│")
        println("└                                                      ┘")
    end
end


# Include scripts
include("./logger/logger.jl")
include("./datatypes/geodatatype/SparseGeoArrays.jl")
include("./datatypes/geoarray_adapter/geoarray_adapter.jl")
include("./datatypes/geoarray_adapter/geoarray_io.jl")
include("./datatypes/geoarray_adapter/geoarray_utils.jl")
include("./datatypes/geoarray_adapter/geoutils_types.jl")
include("./datatypes/sparse_arrays/sparse_array_adoc.jl")
include("./datatypes/sparse_arrays/sparse_array_dok.jl")
include("./datatypes/inundation_model/inundation_model.jl")
include("./datatypes/hypsometric_profiles/hypsometric_profile.jl")
include("./datatypes/hypsometric_profiles/hypsometric_profile_collection.jl")
include("./datatypes/hypsometric_profiles/hypsometric_profile_dataframe.jl")
include("./datatypes/inundation_model/inundation_model_functions.jl")
include("./datatypes/depth_damage_functions/standard_ddf.jl")
include("./datatypes/hypsometric_profiles/hypsometric_profile_exposure.jl")
include("./datatypes/hypsometric_profiles/hypsometric_profile_damage.jl")
include("./datatypes/hypsometric_profiles/hypsometric_profile_expected_damage.jl")
include("./datatypes/hypsometric_profiles/hypsometric_profile_exposure_modifications.jl")
include("./datatypes/hypsometric_profiles/hypsometric_profile_variable_modifications.jl")
include("./datatypes/hypsometric_profiles/hypsometric_profile_plot.jl")
include("./datatypes/hypsometric_profiles/hypsometric_profile_operators.jl")
include("./datatypes/hypsometric_profiles/hypsometric_profile_damage_standard_ddf.jl")
include("./datatypes/coastal_model/local_coastal_model.jl")
include("./datatypes/coastal_model/composed_coastal_model.jl")
include("./datatypes/coastal_model/composed_coastal_model_generics.jl")
include("./datatypes/geodatatype/nn.jl")
include("./algorithms/conversion/sgr_to_hsp.jl")
include("./algorithms/coastal/coastline.jl")
include("./algorithms/coastal/coastplain.jl")
include("./algorithms/statistics/gev_fits.jl")
include("./algorithms/statistics/gpd_fits.jl")
include("./algorithms/statistics/ev_fit.jl")
include("./algorithms/statistics/extreme_distributions_plot.jl")
include("./algorithms/statistics/LinearInterpolation.jl")
include("./algorithms/numerical/simple_integration.jl")
include("./io/nc/HSPs_nc_load.jl")
include("./io/nc/HSPs_nc_save.jl")
include("./io/csv/ccm_indicator_datafame.jl")
include("./io/jld/jld_load.jl")
include("./tools/geotiff_tools.jl")
include("./scenario/ssp_scenario_reader.jl")
include("./scenario/slr_scenario_reader.jl")
end


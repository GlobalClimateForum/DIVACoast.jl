# import Pkg
# # Activates the DIVACoast.jl project environment (dependencies)
# Pkg.activate(joinpath(@__DIR__, "../."))
# Pkg.instantiate()

module DIVACoast

import YAML

# Read local library configuration
config = YAML.load_file(joinpath(@__DIR__, "DIVACoast.jl.yml"), dicttype=Dict{Symbol,Any})

export earth_circumference_km, earth_radius_km

export earth_circumference_km, earth_radius_km
export HypsometricProfile, convert, slope,
    unit, exposure, named, display,
    multiply_exposure!, multiply_exposure_above!, multiply_exposure_below!,
    remove_exposure_below!, add_exposure, add_exposure_above!, add_exposure_between!,
    add_exposure_variable!, remove_exposure_variable!, StandardDDF,
    damage, expected_damage,
    compress!, compress_multithread!, land_raising!
export LinInt, linear_interp, support, probs, cdf, pdf, quantile, manual_integration
export InundationModel, BathtubInundation, LinearDistanceAttenuatedInundation, inundate, water_depth

# append depot path (local packages) to project load path
# append!(LOAD_PATH, DEPOT_PATH)

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


# Include functions
include("./logger/logger.jl")
include("./datatypes/geodatatype/SparseGeoArrays.jl")
include("./datatypes/inundation_model/inundation_model.jl")
include("./datatypes/hypsometric_profiles/hypsometric_profile.jl")
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


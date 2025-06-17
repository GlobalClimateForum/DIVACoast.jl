using Pkg
# Activates the DIVACoast.jl project environment (dependencies)
Pkg.activate(@__DIR__)
Pkg.instantiate()

import YAML
export earth_circumference_km, earth_radius_km

# Read local library configuration
global config = YAML.load_file(joinpath(@__DIR__, "../src/DIVACoast.jl.yml"), dicttype = Dict{Symbol, Any})

module DIVACoast
export earth_circumference_km, earth_radius_km
export HypsometricProfile, to_DF, slope,
    unit, exposure, named, display,
    multiply_exposure!, multiply_exposure_above!, multiply_exposure_below!,
    remove_exposure_below!, add_exposure, add_exposure_above!, add_exposure_between!,
    add_exposure_variable!, remove_exposure_variable!, StandardDDF,
    damage_bathtub_standard_ddf, damage_bathtub, damage,
    compress!, compress_multithread!, land_raising!
export LinInt, linear_interp, support, probs, cdf, pdf, quantile, manual_integration

    # append depot path (local packages) to project load path
    # append!(LOAD_PATH, DEPOT_PATH)

    # Set constants from local config
    earth_circumference_km = Main.config[:earthCircumferenceKM]
    earth_radius_km = Main.config[:earthRadiusKM]

    function __init__()

        DRAW_HEADER = Main.config[:drawHeader]
        SHORT_HEADER = Main.config[:shortHeader]
    
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

        # Include functions
        include("../src/logger/logger.jl")
        include("../src/datatypes/geodatatype/SparseGeoArrays.jl")
        include("../src/datatypes/inundation_model/inundation_model.jl")
        include("../src/datatypes/hypsometric_profiles/hypsometric_profile.jl")
        include("../src/datatypes/inundation_model/inundation_model_functions.jl")
        include("../src/datatypes/depth_damage_functions/standard_ddf.jl")
        include("../src/datatypes/hypsometric_profiles/hypsometric_profile_exposure.jl")
        include("../src/datatypes/hypsometric_profiles/hypsometric_profile_damage.jl")
        include("../src/datatypes/hypsometric_profiles/hypsometric_profile_damage_arbitrary_ddf.jl")
        include("../src/datatypes/hypsometric_profiles/hypsometric_profile_exposure_modifications.jl")
        include("../src/datatypes/hypsometric_profiles/hypsometric_profile_variable_modifications.jl")
        include("../src/datatypes/hypsometric_profiles/hypsometric_profile_plot.jl")
        include("../src/datatypes/hypsometric_profiles/hypsometric_profile_operators.jl")
        include("../src/datatypes/hypsometric_profiles/hypsometric_profile_damage_standard_ddf.jl")
        include("../src/datatypes/coastal_model/local_coastal_model.jl")
        include("../src/datatypes/coastal_model/composed_coastal_model.jl")
        include("../src/datatypes/coastal_model/composed_coastal_model_generics.jl")
        include("../src/datatypes/geodatatype/nn.jl")
        include("../src/algorithms/conversion/sgr_to_hsp.jl")
        include("../src/algorithms/coastal/coastline.jl")
        include("../src/algorithms/coastal/coastplain.jl")
        include("../src/algorithms/statistics/gev_fits.jl")
        include("../src/algorithms/statistics/gpd_fits.jl")
        include("../src/algorithms/statistics/extreme_distributions_plot.jl")
        include("../src/algorithms/statistics/LinearInterpolation.jl")
        include("../src/algorithms/numerical/simple_integration.jl")
        include("../src/io/nc/HSPs_nc_load.jl")
        include("../src/io/nc/HSPs_nc_save.jl")
        include("../src/io/csv/ccm_indicator_datafame.jl")
        include("../src/io/jld/jld_load.jl")
        include("../src/tools/geotiff_tools.jl")
        include("../src/scenario/ssp_scenario_reader.jl")
        include("../src/scenario/slr_scenario_reader.jl")
    end
end


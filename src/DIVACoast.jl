using Pkg
# Activates the DIVACoast.jl project environment (dependencies)
Pkg.activate(joinpath(@__DIR__, "../."))
Pkg.instantiate()

import YAML
export earth_circumference_km, earth_radius_km

# Read local library configuration
global config = YAML.load_file(joinpath(@__DIR__, "DIVACoast.jl.yml"), dicttype = Dict{Symbol, Any})

# Set global constants from local config
global earth_radius_km = Main.config[:earthRadiusKM]
global earth_circumference_km = Main.config[:earthCircumferenceKM]

# append depot path (local packages) to project load path
# append!(LOAD_PATH, DEPOT_PATH)

module DIVACoast

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
        include("./logger/logger.jl")
        include("./datatypes/geodatatype/SparseGeoArrays.jl")
        include("./datatypes/hypsometric_profiles/hypsometric_profiles.jl")
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
        include("./algorithms/numerical/simple_integration.jl")
        include("./io/nc/HSPs_nc_load.jl")
        include("./io/nc/HSPs_nc_save.jl")
        include("./io/csv/ccm_indicator_datafame.jl")
        include("./io/jld/jld_load.jl")
        include("./tools/geotiff_tools.jl")
        include("./scenario/ssp_scenario_reader.jl")
        include("./scenario/slr_scenario_reader.jl")
    end
end


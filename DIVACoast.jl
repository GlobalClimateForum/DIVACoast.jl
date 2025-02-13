using Pkg
# Activates the DIVACoast.jl project environment (dependencies)
Pkg.activate(@__DIR__)
Pkg.instantiate()

import YAML
export earth_circumference_km, earth_radius_km

# Read local library configuration
global config = YAML.load_file(joinpath(@__DIR__, "DIVACoast.jl.yml"), dicttype = Dict{Symbol, Any})

# Set global constants from local config
global earth_radius_km = Main.config[:earthRadiusKM]
global earth_circumference_km = Main.config[:earthCircumferenceKM]


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
        include("./src/logger/log_v2.jl")
        include("./src/logger/jdiva_logger.jl")
        include("./src/datatypes/geodatatype/SparseGeoArrays.jl")
        include("./src/datatypes/hypsometric_profiles/hypsometric_profiles.jl")
        include("./src/datatypes/coastal_model/local_coastal_model.jl")
        include("./src/datatypes/coastal_model/composed_coastal_model.jl")
        include("./src/datatypes/coastal_model/composed_coastal_model_generics.jl")
        include("./src/datatypes/geodatatype/nn.jl")
        include("./src/algorithms/conversion/SGRToHSP.jl")
        include("./src/algorithms/coastal/coastline.jl")
        include("./src/algorithms/coastal/coastplain.jl")
        include("./src/algorithms/statistics/gev_fits.jl")
        include("./src/algorithms/statistics/gpd_fits.jl")
        include("./src/algorithms/numerical/simple_integration.jl")
        include("./src/io/nc/HSPs_nc_load.jl")
        include("./src/io/nc/HSPs_nc_save.jl")
        include("./src/io/csv/ccm_indicator_datafame.jl")
        include("./src/io/jld/jld_load.jl")
        include("./src/tools/geotiff_tools.jl")
        include("./src/scenario/ssp_wrapper.jl")
        include("./src/scenario/slr_wrapper.jl")
    end
end


module jdiva

# constants
const global earth_radius_km = 6371
const global earth_circumference_km = 40075

include("./logger/jdiva_logger.jl")
include("./datatypes/geodatatype/SparseGeoArrays.jl")
include("./datatypes/hypsometric_profiles/hypsometric_profiles.jl")
include("./datatypes/coastal_model/local_coastal_model.jl")
include("./datatypes/coastal_model/composed_coastal_model.jl")
include("./datatypes/coastal_model/composed_coastal_model_generics.jl")
include("./algorithms/conversion/SGRToHSP.jl")
include("./algorithms/coastal/coastline.jl")
include("./algorithms/coastal/coastplain.jl")
include("./algorithms/statistics/ewl_fits.jl")
include("./io/nc/HSPs_nc_load.jl")
include("./io/nc/HSPs_nc_save.jl")
include("./io/csv/ccm_indicator_datafame.jl")
include("./tools/geotiff_tools.jl")
include("./scenario/ssp_wrapper.jl")

end

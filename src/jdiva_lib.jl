module jdiva

# constants
const global earth_radius_km = 6371
const global earth_circumference_km = 40075

include("./logger/jdiva_logger.jl")
include("./datatypes/geodatatype/SparseGeoArrays.jl")
include("./datatypes/hypsometric_profiles/hypsometric_profiles.jl")
include("./datatypes/coastal_model/local_coastal_model.jl")
include("./algorithms/conversion/SGRToHSP.jl")
include("./io/nc/HSPs_nc_load.jl")
include("./io/nc/HSPs_nc_save.jl")
include("./tools/geotiff_tools.jl")

end

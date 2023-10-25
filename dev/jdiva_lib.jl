module jdiva

# constants
const global earth_radius_km = 6371

include("./logger/jdiva_logger.jl")
include("./datatypes/geodatatype/SparseGeoArrays.jl")
include("./datatypes/hypsometric_profiles/hypsometric_profiles.jl")
include("./algorithms/conversion/SGRToHSP.jl")

end

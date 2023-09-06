import GeoFormatTypes as GFT

include("sparsegeoarray.jl")
include("crs.jl")
include("io.jl")
include("geoutils.jl")

export SparseGeoArray
export readGEOTiffDataComplete, saveGEOTiffDataComplete
export nh4, nh8
export coords, indices, AbstractStrategy, Center, UpperLeft, UpperRight, LowerLeft, LowerRight
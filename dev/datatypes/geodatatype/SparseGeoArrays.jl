import GeoFormatTypes as GFT

include("sparsegeoarray.jl")
include("sparsegeoarray_operations.jl")
include("crs.jl")
include("io.jl")
include("geoutils.jl")

export SparseGeoArray
export readGEOTiffDataComplete, saveGEOTiffDataComplete
export readGEOTiffDataCategorised
export nh4, nh8
export union, union!
export coords, indices, AbstractStrategy, Center, UpperLeft, UpperRight, LowerLeft, LowerRight, crop!

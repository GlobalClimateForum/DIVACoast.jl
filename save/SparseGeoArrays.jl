import GeoFormatTypes as GFT

include("sparsegeoarray.jl")
include("sparsegeoarray_operations.jl")
include("sparsegeoarray_utils.jl")
include("crs.jl")
include("io.jl")
include("geoutils.jl")

export SparseGeoArray, SparseGeoArrayFromFile
export readGEOTiffDataComplete, saveGEOTiffDataComplete
export readGEOTiffDataCategorised
export nh4, nh8
<<<<<<< HEAD
export sga_union, sga_union!, sga_intersect
export coords, indices, AbstractStrategy, Center, UpperLeft, UpperRight, LowerLeft, LowerRight, crop!, area, distance
=======
export sga_union, sga_union!, sga_intersect,sga_multiUnion
export coords, indices, AbstractStrategy, Center, UpperLeft, UpperRight, LowerLeft, LowerRight, crop!, area
>>>>>>> 77d3a777202c58ec32cc59c3bbf2a5dd37fec363

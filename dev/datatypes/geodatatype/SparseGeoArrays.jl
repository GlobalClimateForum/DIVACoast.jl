import GeoFormatTypes as GFT

include("sparsegeoarray.jl")
include("sparsegeoarray_operations.jl")
include("sparsegeoarray_utils.jl")
include("crs.jl")
include("io.jl")
include("geoutils_types.jl")
include("geoutils.jl")

export SparseGeoArray, SparseGeoArrayFromFile
export read_geotiff_header!, read_geotiff_data_complete!, save_geotiff_data_complete, read_geotiff_data_partial!
export read_geotiff_data_categorised!
export nh4, nh8

export sga_union, sga_union!, sga_intersect, sga_multi_union, sga_summarize_within, sga_summarize_within_with_partial_read, partial_read_around
export coords, indices, crop!, area, distance, go_direction, clear_data
export AbstractStrategy, Center, UpperLeft, UpperRight, LowerLeft, LowerRight
export AbstractDirection, East, North, West, South


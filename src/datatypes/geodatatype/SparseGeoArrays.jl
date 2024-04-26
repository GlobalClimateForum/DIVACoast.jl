import GeoFormatTypes as GFT

include("sparsegeoarray.jl")
include("sparsegeoarray_operations.jl")
include("sparsegeoarray_utils.jl")
include("crs.jl")
include("io.jl")
include("geoutils_types.jl")
include("geoutils.jl")
include("geoutils_generic.jl")

export SparseGeoArray, SparseGeoArrayFromFile
export empty_copy
export read_geotiff_header!, read_geotiff_data_complete!,  read_geotiff_data_partial!, partial_read_around!, extract_box_around
export save_geotiff_data_complete, save_data_complete_csv
export read_geotiff_data_categorised!, read_geotiff_data_filtered!
export nh4, nh8
export nh4_function_application, nh8_function_application

export sga_union, sga_union!, sga_intersect, sga_multi_union, sga_summarize_within, sga_summarize_within_with_partial_read, get_closest_value
export coords, indices, crop!, area, distance, go_direction, clear_data!
export AbstractStrategy, Center, UpperLeft, UpperRight, LowerLeft, LowerRight
export AbstractDirection, East, North, West, South


include("../jdiva_lib.jl")

using .jdiva

println("../../testdata/luebeck_meritDEM.tif")
sga1 = SparseGeoArray{Float32,Int32}("/home/honsel/Projects/testdata/Copernicus_DSM_30_N29_00_E014_00_DEM.tif")
sga2 = SparseGeoArray{Float32,Int32}("/home/honsel/Projects/testdata/Copernicus_DSM_30_N28_00_E015_00_DEM.tif")


union = sga_union(sga1, sga2)

exportFile = "/home/honsel/Projects/testdata/Copernicus_union.tif"
saveGEOTiffDataComplete(union,filename)

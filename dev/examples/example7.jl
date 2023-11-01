include("../jdiva_lib.jl")

using .jdiva

println("../../testdata/luebeck_meritDEM.tif")
sga1 = SparseGeoArray{Float32,Int32}("/home/honsel/Projects/testdata/Copernicus_DSM_30_N29_00_E014_00_DEM.tif")
sga2 = SparseGeoArray{Float32,Int32}("/home/honsel/Projects/testdata/Copernicus_DSM_30_N28_00_E015_00_DEM.tif")
sga3 = SparseGeoArray{Float32, Int32}("/home/honsel/Projects/testdata/Copernicus_DSM_30_N29_00_E015_00_DEM.tif")
union = SparseGeoArray{Float32, Int32}("/home/honsel/Projects/testdata/Copernicus_union2.tif")

#union = sga_union(sga1, sga2)
#exportFile = "/home/honsel/Projects/testdata/Copernicus_union.tif"
#saveGEOTiffDataComplete(union,exportFile)
#union2 = sga_multiUnion([sga1, sga2, sga3])
#exportFile2 = "/home/honsel/Projects/testdata/Copernicus_union2.tif"
#saveGEOTiffDataComplete(union2,exportFile2)

exportFile3 = "/home/honsel/Projects/testdata/intersect.tif"
intersect = sga_intersect(union, sga3)
saveGEOTiffDataComplete(intersect ,exportFile3)









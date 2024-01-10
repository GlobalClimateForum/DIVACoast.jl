include("../jdiva_lib.jl")

using .jdiva

sga = SparseGeoArray{Float32,Int32}("../../../../data/example_UK/tif/UKIRL_merit_coastline.tif")
saveGEOTiffDataComplete(sga,"test.tif",1)

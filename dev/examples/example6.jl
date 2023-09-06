include("../jdiva_lib.jl")

using .jdiva

sga = SparseGeoArray{Float32,Int32}("luebeck_meritDEM.tif")
saveGEOTiffDataComplete(sga,"test.tif")

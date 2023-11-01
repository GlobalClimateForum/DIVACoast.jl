include("../jdiva_lib.jl")
using .jdiva

# Union of multiple files


searchdir(path,key) = filter(x->occursin(key,x), readdir(path))
files = searchdir("../../", ".tif")
files = [SparseGeoArray{Float32,Int32}("../../$file") for file in files]
union = sga_multiUnion(files)

exportFile = "/home/honsel/Projects/testdata/multiUnion.tif"
saveGEOTiffDataComplete(union,exportFile)
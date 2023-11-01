include("../jdiva_lib.jl")
using .jdiva

# Union of multiple files


searchdir(path,key) = filter(x->occursin(key,x), readdir(path))
filenames = searchdir("../../", ".tif")
files = [SparseGeoArray{Float32,Int32}("../../$file") for file in filenames]
union = sga_union(files)

exportFile = "../../multiUnion.tif"
saveGEOTiffDataComplete(union,exportFile)

pushfirst!(filenames, "../../multiUnion.tif")
intersection = sga_intersect(files[1:2])

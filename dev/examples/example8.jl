include("../jdiva_lib.jl")
using .jdiva



searchdir(path,key) = filter(x->endswith(x,key), readdir(path))
filenames = searchdir("../../", ".tif")
files = [SparseGeoArray{Float32,Int32}("../../$file") for file in filenames]
union = sga_union(files)

exportFile = "../../multiUnion.tif"
saveGEOTiffDataComplete(union,exportFile)

pushfirst!(filenames, "multiUnion.tif")
files = [SparseGeoArray{Float32,Int32}("../../$file") for file in filenames]

intersection = sga_intersect(files[1:2])
saveGEOTiffDataComplete(intersection[1],"../../intersect1.tif")
saveGEOTiffDataComplete(intersection[2],"../../intersect2.tif")


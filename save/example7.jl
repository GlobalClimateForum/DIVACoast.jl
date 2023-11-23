include("../jdiva_lib.jl")

using .jdiva

println("../../testdata/luebeck_meritDEM.tif")
sga1 = SparseGeoArray{Float32,Int32}("../../UKIRL_merit_coastplain_elecz_12m_gadm_1290_Rushen.tif")
sga2 = SparseGeoArray{Float32,Int32}("../../UKIRL_merit_coastplain_elecz_12m_gadm_1335_County_Galway.tif")
#union = sga_union(sga1, sga2)


sga_union(sga1, sga2)
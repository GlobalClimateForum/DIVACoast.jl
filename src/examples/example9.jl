include("/home/honsel/GCF_DIVA/diva_library/dev/jdiva_lib.jl")
using .jdiva
using DataFrames
using CSV
using Statistics


testSGA = SparseGeoArray{Float32,Int32}("../../testdata/luebeck/luebeck_GHS_POP_E2020_GLOBE_R2023A_4326_3ss_V1_0_new.tif")
sumElevation = sga_getWithin((10.68769, 53.86815), 0.005, testSGA, sum)
println(sumElevation)


#populationData = SparseGeoArray{Float32,Int32}("./data/GHS_POP.tif")
#df.population50km = missings(Float32, nrow(df)) 


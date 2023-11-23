include("/home/honsel/GCF_DIVA/diva_library/dev/jdiva_lib.jl")
using .jdiva
using DataFrames
using CSV
using Statistics



testSGA = SparseGeoArray{Float32,Int32}("/home/honsel/Projects/testdata/copernicus.tif")
sumElevation = sga_getWithin((0.5928, 52.4067), 0.005, testSGA, sum)
println(sumElevation)
meanElevation = sga_getWithin((0.5928, 52.4067), 0.005, testSGA, mean)
println(meanElevation)

csvData = CSV.File("./data_meta_regression.csv", delim = ";") |> DataFrame
df = select(csvData, "longitude", "latitude")
populationData = SparseGeoArray{Float32, Int32}("./data/Global_ghs_pop_coastal_masked.tif")

#populationData = SparseGeoArray{Float32,Int32}("./data/GHS_POP.tif")
#df.population50km = missings(Float32, nrow(df)) 


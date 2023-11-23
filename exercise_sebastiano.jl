include("./dev/jdiva_lib.jl")
using .jdiva
using DataFrames
using CSV
using Statistics

testSGA = SparseGeoArray{Float32,Int32}("./testdata/UKIRL/UKIRL_merit_coastplain_elecz_20m.tif")
sumElevation = sga_getWithin((0.5928, 52.4067), 0.005, testSGA, sum)
println(sumElevation)
meanElevation = sga_getWithin((0.5928, 52.4067), 0.005, testSGA, mean)
println(meanElevation)

csvData = CSV.File("./testdata/UKIRL/studies_UK.csv", delim = ",") |> DataFrame
df = select(csvData, "longitude", "latitude")

populationData = SparseGeoArray{Float32, Int32}("./testdata/UKIRL/UKIRL_GHS_POP_E2020_GLOBE_R2023A_4326_3ss_V1_0.tif")



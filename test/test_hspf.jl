# Test Hypsometric Profiles
include("../src/DIVACoast.jl")
using .DIVACoast

using DataFrames

hspfs = load_hsps_nc(Int32, Float32, "./testdata/UKIRL/nc/UKIRL_hspfs_floodplains.nc")


# Try with explicit module reference
df =  to_DF(hspfs[2071])
println(df)

println(typeof(hspfs))
dfs = to_DF(hspfs)
println(first(df, 10))
println(size(dfs))


save(hspfs, "test_hspfs.jld2")
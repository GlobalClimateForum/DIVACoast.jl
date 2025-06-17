using Pkg
Pkg.activate("$(ENV["DIVA_LIB"])")
include("$(ENV["DIVA_LIB"])/src/DIVACoast.jl")
using .DIVACoast
using DataFrames


hspfs = load_hsps_nc(Int32, Float32, "./testdata/UKIRL/nc/UKIRL_hspfs_floodplains.nc")


h1 = deepcopy(hspfs[12]) 
h2 = deepcopy(hspfs[12])


h2 = DataFrame(h2)
h2.popShare = (h2.population ./ maximum(h2.population)) * 100

h2.assetsEUR = 0.85 * h2.assets


h2 = HypsometricProfile(h2, exposureCols = [:population, :assets, :assetsEUR, :popShare], exposureUnits = ["", "USD", "EUR", "%"])




# save(h2, "./hpfs_test.jld2")


print(h2)
display(h2)

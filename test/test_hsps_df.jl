using Pkg
Pkg.activate("$(ENV["DIVA_LIB"])")
include("$(ENV["DIVA_LIB"])/src/DIVACoast.jl")
using .DIVACoast


hspfs = load_hsps_nc(Int32, Float32, "./testdata/UKIRL/nc/UKIRL_hspfs_floodplains.nc")


h1 = deepcopy(hspfs[42]) 
h2 = deepcopy(hspfs[42])

println(to_DF(h1)[200:210, :])

println(to_DF(h2)[200:210, :])

h2 = to_DF(h2)
h2.popShare = h2.population ./ maximum(h2.population)
h2 = HypsometricProfile(h2, exposureCols = [:population, :assets, :popShare], exposureUnits = ["m", "m", "m"])

save(h2, "./hpfs_test.jld2")

println(to_DF(h2)[200:210, :])

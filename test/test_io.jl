#using Pkg

#Pkg.activate(".")
#include("../src/DIVACoast.jl")
#using .DIVACoast

#using .DIVACoast
using DataFrames
using Plots

#=
hspfs = load_hsps_nc(Int32, Float32, "../testdata/UKIRL/nc/UKIRL_hspfs_floodplains.nc")

hp1 = deepcopy(hspfs[42])

df_hp1 = to_DF(hp1)

pop_share =  (popTotal, pop) -> pop / popTotal
pop_total = maximum(df_hp1.population)

df_hp1.popshare = map!(df_hp1.population, eachrow(df_hp1)) do row 
    return pop_share(pop_total, row.population)
end


println(first(df_hp1, 10))
println("SUM popshare" , sum(df_hp1.popshare))

hp2 = HypsometricProfile(df_hp1, hp1)
println(first(to_DF(hp2), 5))
=#
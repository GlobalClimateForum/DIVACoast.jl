include("/home/lincke/Repositories/diva++/lib/DIVACoast.jl/src/DIVACoast.jl")
using .DIVACoast


# we load the hypsometric profiles for each segment (we have precomputed and saved them before)
hspfs = load_hsps_nc(Int32, Float32, "./nc/UKIRL_hspfs_floodplains.nc")
foreach(x -> compress!(x), values(hspfs))


using Pkg
Pkg.activate("$(ENV["DIVA_LIB"])")
include("$(ENV["DIVA_LIB"])/src/DIVACoast.jl")
using .DIVACoast

path = "./testdata/UKIRL/nc/UKIRL_hspfs_floodplains.nc"

if !isfile(basename(path) * "jld2")
    @info "File does not exist, loading from netCDF"
else
    @info "File exists, loading from JLD2"
end
@time load(path, load_hsps_nc, (Int32, Float32))





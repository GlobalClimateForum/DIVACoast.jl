using Pkg
Pkg.activate("$(ENV["DIVA_LIB"])")
include("$(ENV["DIVA_LIB"])/src/DIVACoast.jl")
using .DIVACoast
using Plots
using GeoArrays
using CSV
using DataFrames

# helpers

path_to_data = (subdir) -> joinpath(ENV["DIVA_LIB"], "testdata/uk_the_wash", subdir)

function reclassify_wbm(wbm::GeoArrays.GeoArray)

    mapping = Dict(
    "nowater" => 0.0, 
    "ocean" => 1.0, 
    "lake" => 2.0,
    "river" => 3.0
    )

    result_ = deepcopy(wbm) 
    result_[result_ .!= mapping["ocean"]] .= false
    result_[result_ .== mapping["ocean"]] .= true

    return result_
end

na_mask_fabdem = (fabdem::GeoArrays.GeoArray, wbm::GeoArrays.GeoArray) -> begin
    fabdem[wbm .== true] .= Float32(-9999) # Set ocean values to NoData
    return fabdem
end

# data pipeline

@info "data pipeline ..."

wbm = "copdem_wbm.tif" |> path_to_data |> GeoArrays.read |> reclassify_wbm
fabdem = "fabdem.tif" |> path_to_data |> GeoArrays.read |> fabdem_ -> na_mask_fabdem(fabdem_, wbm)
pop = "worldpop.tif" |> path_to_data |> GeoArrays.read
corine = "corine.tif" |> path_to_data |> GeoArrays.read
attrates = "corine_attrates.csv" |> path_to_data |> CSV.File |> DataFrame


fp = SpatialFloodProfile(fabdem; seed = findall(wbm .== true)[1], exposures = [pop])
fpMask = SpatialFloodProfileMask(fp)

inundation = inundate(fp, fpMask, 3.0f0, PathBasedAttenuatedBathtub(0.6f0))

# inundation |> i_ -> GeoArrays.GeoArray(i_, fabdem.f, fabdem.crs) |> plot(c = :blues)

exposure(fp, inundation) 

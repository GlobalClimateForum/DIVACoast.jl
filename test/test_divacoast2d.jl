using Pkg
Pkg.activate("$(ENV["DIVA_LIB"])")
include("$(ENV["DIVA_LIB"])/src/DIVACoast.jl")
using .DIVACoast
using Plots
using GeoArrays
using CSV
using DataFrames
using Distributions
using Statistics
using Logging

# helpers

global_logger(DIVALogger("./log.txt"))

path_to_data = (subdir) -> joinpath(ENV["DIVA_DATA"], "spatial_test_data", subdir)

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
@info "Loading test data"

wbm = "wbm.tif" |> path_to_data |> GeoArrays.read |> reclassify_wbm
fabdem = "fabdem.tif" |> path_to_data |> GeoArrays.read |> fabdem_ -> na_mask_fabdem(fabdem_, wbm)
pop = "worldpop.tif" |> path_to_data |> GeoArrays.read
corine = "corine.tif" |> path_to_data |> GeoArrays.read
# attrates = "corine_attrates.csv" |> path_to_data |> CSV.File |> DataFrame

@info "Initialize SpatialProfile"
fp = SpatialProfile(fabdem; seed = findall(wbm .== true)[1], exposures = [pop])

@info "Running inundation model tests"

hcb = inundate(fp, 2.0, HydraulicConnectedBathtub())
pba = inundate(fp, 2.0, PathBasedAttenuatedBathtub(0.1))

attenuation_rates = zeros(size(fp.elevation) ...) .+ 0.3

for x in 1:size(fp.elevation, 1)
    for y in 1:size(fp.elevation, 2)
        if ! fp.mask.sea[x,y]
            attenuation_rates[x,y] = sqrt(x + y) * 0.05
        end
    end
end

attenuation_rates = GeoArrays.GeoArray(attenuation_rates, fp.elevation.f, fp.elevation.crs)

pba_local = inundate(fp, 2.0, PathBasedAttenuatedBathtub(attenuation_rates))

@info "Inundation model tests completed successfully"

p1 = heatmap(hcb; title = "HCB ", c = cgrad(:blues), colorbar_title = "m")
p2 = heatmap(pba; title = "PBAB (global attenuation)", c = cgrad(:blues), colorbar_title = "m")
p3 = heatmap(pba_local; title = "PBAB (local attenuation)", c = cgrad(:blues), colorbar_title = "m")

plot(p1, p2, p3; layout = (1, 3), size = (1500, 400)) |> display
readline()



using Pkg
Pkg.activate("$(ENV["DIVA_LIB"])")
include("$(ENV["DIVA_LIB"])/src/DIVACoast.jl")
using .DIVACoast
using Plots; # pyplot()
using GeoArrays
using CSV
using DataFrames
using Logging

global_logger(DIVALogger())
path_to_data = (subdir) -> joinpath(ENV["DIVA_DATA"], "spatial_flood_model_comparison_UKIRL", "uk_wash_floodplain" , "aligned",  subdir)

# Helpers

function reclassify_wbm(wbm::GeoArrays.GeoArray)
    mapping = Dict(
    "nowater" => 0.0, 
    "ocean" => 1.0, 
    "lake" => 2.0,
    "river" => 3.0
    )

    result_ = falses(size(wbm.A))
    result_[wbm.A .== mapping["ocean"]] .= true
    result_[wbm.A .== mapping["river"]] .= true # Treat rivers as oceans
    return GeoArrays.GeoArray(result_, wbm.f, wbm.crs)
end

na_mask_fabdem = (fabdem::GeoArrays.GeoArray, wbm::GeoArrays.GeoArray) -> begin
    fabdem_ = Array{Union{Float32, Missing}}(copy(fabdem.A))
    fabdem_[wbm .== true] .= missing # Set ocean values to NoData
    return GeoArrays.GeoArray(fabdem_, fabdem.f, fabdem.crs)
end

function mask_to_floodplain(array::GeoArrays.GeoArray, floodplainmask::GeoArrays.GeoArray) 

    masked_array = Array{Union{eltype(array.A), Missing}}(copy(array.A))
    for i in eachindex(array)
        if ismissing(floodplainmask[i]) || floodplainmask[i] == 1 || floodplainmask[i] === true
            masked_array[i] = missing
        end
    end
    return GeoArrays.GeoArray(masked_array, array.f, array.crs)

end

function set_attenuation_rates(mapping::DataFrame, corine::GeoArrays.GeoArray)

    attrates = similar(corine.A, Float32)

    for row in eachrow(mapping)
        attrates[corine .== row[:class_code]] .= row[:attenuation_rate]
    end

    return GeoArrays.GeoArray(attrates, corine.f, corine.crs)
end


# Data loading / pre-processing
@info "Loading test data"
wbm = "wbm.tif" |> path_to_data |> GeoArrays.read |> reclassify_wbm
fabdem = "fabdem.tif" |> path_to_data |> GeoArrays.read
pop = "worldpop.tif" |> path_to_data |> GeoArrays.read
corine = "corine.tif" |> path_to_data |> GeoArrays.read
attrates = "corine_attr_mapping.csv" |> path_to_data |> CSV.File |> DataFrame |> x -> set_attenuation_rates(x, corine)

# Model construction

@info "Initialize SpatialProfile & Initialize SpatialProfileMask"

fm = SpatialProfileMask(wbm, 1)
fp = SpatialProfile(fabdem;  mask = fm, exposures = [pop])

plot(fp) |> display
readline()

# Scenario construction
@info "Initialize spatial scenarios" 

water_levels = collect(0.5:0.5:5.0)
spatial_models = Dict(
    "SP_PBAB_glob" => PathBasedAttenuatedBathtub(0.3)
)

# "SP_HCB" => HydraulicConnectedBathtub(),
# "SP_PBAB_loc" => PathBasedAttenuatedBathtub(attrates)

scenarios = Base.product(water_levels, keys(spatial_models))

# Inundation (model runs) and export

for (wl, modelname) in scenarios

    @info "Inundation: $modelname at $wl"

    # Inundation
    inun_depth = inundate(fp, wl, spatial_models[modelname])
    # exposure(fp, wl, spatial_models[modelname])
   
    # Export
    exportname = "$(modelname)_$(wl).tif"

    exp_data = Float32.(inun_depth)
    exp_data[exp_data .== Inf] .= Float32(-9999)
    exp_data[isnan.(exp_data)] .= Float32(-9999)
    exp_data[ismissing.(exp_data)] .= Float32(-9999)

    exp = GeoArrays.GeoArray(exp_data, fp.elevation.f, fp.elevation.crs)
    # GeoArrays.write(joinpath(path_to_data(""), exportname), exp)
end

# @info "Initialize Hypsometric Profile scenarios"

# hp_exposure = Vector{GeoArrays.GeoArray}(undef, 1)
# hp_exposure[1] = pop
# hp = to_hypsometric_profile(fabdem, "m", hp_exposure,["population"], ["individuals"], Float32(1.0), "m", Float32(-5), Float32(20),  Float32(1.0), "m")

# hp_exposure = [exposure(hp, wl) for wl in water_levels]

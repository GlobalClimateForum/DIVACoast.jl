"""
    InundationModel(coast_length::DT, coast_length_unit::String,
    elevations::Array{DT}, elevation_unit::String, area::Array{DT}, area_unit::String,
    exposure_data::StructArray{T1}, exposure_units::Array{String}) where {DT<:Real,T1}

An InundationModel represents the model type used to model water inundation over a HypsometricProfile. 
BathtubInundation uses the bathtub approach and LinearDistanceAttenuatedInundation uses a linear factor to attenuate the water level.
"""
abstract type InundationModel end

struct BathtubInundation <: InundationModel end

struct LinearDistanceAttenuatedInundation <: InundationModel
    attenuation_rate::Real
end

#struct NonlinearDistanceAttenuatedInundation <: InundationModel
#    attenuation_function::Function
#end

struct UserDefinedInundation <: InundationModel
    # ?? 
    # attenuation_functions :: Dict{Symbol,Function}
end
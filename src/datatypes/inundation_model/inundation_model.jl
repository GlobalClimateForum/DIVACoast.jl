"""
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

# Spatial Inundation Models
struct HydraulicConnectedBathtub <: InundationModel
    function HydraulicConnectedBathtub()
        return new()
    end
end

struct PathBasedAttenuatedBathtub <: InundationModel
    attrate::Union{Real, GeoArrays.GeoArray, AbstractMatrix}
    function PathBasedAttenuatedBathtub(attrate::Union{Real, GeoArrays.GeoArray, AbstractMatrix})
        return new(attrate)
    end
end

function Base.show(io::IO, im::Union{HydraulicConnectedBathtub, PathBasedAttenuatedBathtub})
    if im isa HydraulicConnectedBathtub
        print(io, "<DIVACoast.jl | HCB Model>")
    elseif im isa PathBasedAttenuatedBathtub
        print(io, "<DIVACoast.jl | PBAB Model>")
    elseif im isa BathtubInundation
        print(io, "<DIVACoast.jl | Bathtub Model>")
    elseif im isa LinearDistanceAttenuatedInundation
        print(io, "<DIVACoast.jl | LDA Model>")
    end
end
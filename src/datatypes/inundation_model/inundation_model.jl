export InundationModel, BathtubInundation, LinearDistanceAttenuatedInundation, inundate

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
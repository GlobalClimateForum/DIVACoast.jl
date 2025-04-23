export InundationModel, BathtubInundation, LinearDistanceAttenuatedInundation, inundate

abstract type InundationModel end

struct BathtubInundation <: InundationModel end

struct LinearDistanceAttenuatedInundation <: InundationModel
    attenuation_rate::Real
end

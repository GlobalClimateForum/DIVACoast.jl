export damage

# fallback
include("hypsometric_profile_damage_fallback.jl")
include("hypsometric_profile_damage_standard_ddf.jl")

damage(hspf::HypsometricProfile{DT}, wl::Real, s::Array{Symbol}, ddfs::Vector{Function}, im::IM = BathtubInundation()) where {DT<:Real, IM<:InundationModel} = damage(hspf, wl, map(x -> String(x),s), ddfs, im) 
damage(hspf::HypsometricProfile{DT}, wl::Real, s::Array{Symbol}, ddfs::Vector{StandardDDF}, im::IM = BathtubInundation()) where {DT<:Real, IM<:InundationModel} = damage(hspf, wl, map(x -> String(x),s), ddfs, im) 

damage(hspf::HypsometricProfile{DT}, wl::Real, s::String, ddf::Function, im::IM = BathtubInundation()) where {DT<:Real, IM<:InundationModel} = damage(hspf, wl, [s], convert(Array{Function},[ddf]), im)[1]
damage(hspf::HypsometricProfile{DT}, wl::Real, s::Symbol, ddf::Function, im::IM = BathtubInundation()) where {DT<:Real, IM<:InundationModel} = damage(hspf, wl, [String(s)], convert(Array{Function},[ddf]), im)[1]

damage(hspf::HypsometricProfile{DT}, wl::Real, s::String, ddf::StandardDDF, im::IM = BathtubInundation()) where {DT<:Real, IM<:InundationModel} = damage(hspf, wl, [s], convert(Array{StandardDDF},[ddf]), im)[1]
damage(hspf::HypsometricProfile{DT}, wl::Real, s::Symbol, ddf::StandardDDF, im::IM = BathtubInundation()) where {DT<:Real, IM<:InundationModel} = damage(hspf, wl, [String(s)], convert(Array{StandardDDF},[ddf]), im)[1]

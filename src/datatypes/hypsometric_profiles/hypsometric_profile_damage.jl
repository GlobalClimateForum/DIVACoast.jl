export damage

"""
    damage(hspf::HypsometricProfile{DT}, wl::Real, s::Array{}, ddfs::Vector{Function}, im::IM=BathtubInundation()) where {DT<:Real,IM<:InundationModel}
    ...

Calculates the flood damage for a given water level wl based on provided damage functions ddfs for all exposure variables in s.
The default inundation model (if not specified otherwise) is bathtub inundation.

# Arguments
- `hspf::HypsometricProfile{DT}`: The hypsometric profile.
- `wl::Real`: The water level for which the damage is calculated.
- `s::String or s::Symbol or s::Array{String} or Array{Symbol}`: An array of exposure variable names for which the damage is calculated. If only one variable is used please use the version with a single variable instaed of an array (the latter one might cause problems then).
- `ddfs::Vector{Function}`: A vector of damage functions corresponding to the exposure variables in s. 
  StandardDDF(h) can be used for a standard depth-damage function 
`f(d)= d/(d+h)`
- `im::IM`: The inundation model to be used, default is BathtubInundation().


# Example
```julia
  damage(hspf, 2.0, "assets", d -> d/(d+1))   # returns a number
  damage(hspf, 4.5, ["population","assets"], [d -> 1, d -> d/(d+1)])    # returns a 2-elment Array
  damage(hspf, 4.5, [:population,:assets], [StandardDDF(0.0), StandardDDF(1.0)])    # returns a 2-elment Array
```
"""

# fallback
include("hypsometric_profile_damage_fallback.jl")
include("hypsometric_profile_damage_standard_ddf.jl")

damage(hspf::HypsometricProfile{DT}, wl::Real, s::Array{String}, ddfs::Vector{Function}, im::IM = BathtubInundation()) where {DT<:Real, IM<:InundationModel} = damage(hspf, wl, map(x -> get_position(hspf, x), s), ddfs, im) 
damage(hspf::HypsometricProfile{DT}, wl::Real, s::Array{String}, ddfs::Vector{StandardDDF}, im::IM = BathtubInundation()) where {DT<:Real, IM<:InundationModel} = damage(hspf, wl, map(x -> get_position(hspf, x), s), ddfs, im) 

damage(hspf::HypsometricProfile{DT}, wl::Real, s::Array{Symbol}, ddfs::Vector{Function}, im::IM = BathtubInundation()) where {DT<:Real, IM<:InundationModel} = damage(hspf, wl, map(x -> String(x),s), ddfs, im) 
damage(hspf::HypsometricProfile{DT}, wl::Real, s::Array{Symbol}, ddfs::Vector{StandardDDF}, im::IM = BathtubInundation()) where {DT<:Real, IM<:InundationModel} = damage(hspf, wl, map(x -> String(x),s), ddfs, im) 

damage(hspf::HypsometricProfile{DT}, wl::Real, s::String, ddf::Function, im::IM = BathtubInundation()) where {DT<:Real, IM<:InundationModel} = damage(hspf, wl, [s], convert(Array{Function},[ddf]), im)[1]
damage(hspf::HypsometricProfile{DT}, wl::Real, s::Symbol, ddf::Function, im::IM = BathtubInundation()) where {DT<:Real, IM<:InundationModel} = damage(hspf, wl, [String(s)], convert(Array{Function},[ddf]), im)[1]

damage(hspf::HypsometricProfile{DT}, wl::Real, s::String, ddf::StandardDDF, im::IM = BathtubInundation()) where {DT<:Real, IM<:InundationModel} = damage(hspf, wl, [s], convert(Array{StandardDDF},[ddf]), im)[1]
damage(hspf::HypsometricProfile{DT}, wl::Real, s::Symbol, ddf::StandardDDF, im::IM = BathtubInundation()) where {DT<:Real, IM<:InundationModel} = damage(hspf, wl, [String(s)], convert(Array{StandardDDF},[ddf]), im)[1]

using Distributions

"""
    expected_damage(hspf::HypsometricProfile{DT}, dist::Distribution, wl_lower_limit::Real, s, ddfs::Vector{Function}, im::IM=BathtubInundation(), tol::Real=1e-3) where {DT<:Real,IM<:InundationModel}
    ...

Calculates the expected flood damage for a given distribution of water levels 'dist' based on provided damage functions ddfs for all exposure variables in s.
The default inundation model (if not specified otherwise) is bathtub inundation.

# Arguments
- `hspf::HypsometricProfile{DT}`: The hypsometric profile.
- `dist::Distribution` :: The probability distribution of the water levels that flood the hypsometric profile.
- `wl_lower_limit::Real`:: the lowest water level taken into account (for instance if all water levels below are defended by a dike)
- `s::String or s::Symbol or s::Array{String} or Array{Symbol}`: An array of exposure variable names for which the damage is calculated. If only one variable is used please use the version with a single variable instaed of an array (the latter one might cause problems then).
- `ddfs::Vector{Function}`: A vector of damage functions corresponding to the exposure variables in s. 
  StandardDDF(h) can be used for a standard depth-damage function `f(d)= d/(d+h)`
- `im::IM`: The inundation model to be used, default is BathtubInundation().

# Example
```julia
  expected_damage(hspf, GeneralizedPareto(2.5,0.75,0), "assets", StandardDDF(1.0))   # returns a number
  expected_damage(hspf, GeneralizedExtremeValue(2.0,0.18,0.1), ["population","assets"], [d -> 1, d -> d/(d+1)])    # returns a 2-elment Array
  expected_damage(hspf, GeneralizedPareto(2.5,0.75,0), [:population,:assets], [StandardDDF(0.0), StandardDDF(1.0)], LinearDistanceAttenuatedInundation(0.25))   # returns a 2-elment Array

  ```
"""

include("hypsometric_profile_expected_damage_special_cases.jl")

expected_damage(hspf::HypsometricProfile{DT}, dist::Distribution, wl_lower_limit::Real, s::Array{Symbol}, ddfs::Vector{Function}, im::IM=BathtubInundation(), tol::Real=1e-3) where {DT<:Real,IM<:InundationModel} = expected_damage(hspf, dist, wl_lower_limit, map(x -> String(x), s), ddfs, im, tol)
expected_damage(hspf::HypsometricProfile{DT}, dist::Distribution, wl_lower_limit::Real, s::String, ddf::Function, im::IM=BathtubInundation()) where {DT<:Real,IM<:InundationModel} = expected_damage(hspf, dist, wl_lower_limit, [s], convert(Array{Function}, [ddf]), im)[1]
expected_damage(hspf::HypsometricProfile{DT}, dist::Distribution, wl_lower_limit::Real, s::Symbol, ddf::Function, im::IM=BathtubInundation()) where {DT<:Real,IM<:InundationModel} = expected_damage(hspf, dist, wl_lower_limit, [String(s)], convert(Array{Function}, [ddf]), im)[1]

expected_damage(hspf::HypsometricProfile{DT}, dist::Distribution, wl_lower_limit::Real, s::String, ddf::StandardDDF, im::IM=BathtubInundation()) where {DT<:Real,IM<:InundationModel} = expected_damage(hspf, dist, wl_lower_limit, [s], convert(Array{StandardDDF}, [ddf]), im)[1]
expected_damage(hspf::HypsometricProfile{DT}, dist::Distribution, wl_lower_limit::Real, s::Symbol, ddf::StandardDDF, im::IM=BathtubInundation()) where {DT<:Real,IM<:InundationModel} = expected_damage(hspf, dist, wl_lower_limit, [String(s)], convert(Array{StandardDDF}, [ddf]), im)[1]


function expected_damage(hspf::HypsometricProfile{DT}, dist::Distribution, wl_lower_limit::Real, s::Array{String}, ddfs::Vector{F}, im::IM=BathtubInundation()) where {DT<:Real,F<:Function,IM<:InundationModel}
    tol::Real = 1e-3
    x_low = max(minimum(dist), wl_lower_limit)

    inds = map(x -> get_position(hspf, x), s)
    ret = zeros(DT, size(inds, 1))
    for ind in 1:size(inds, 1)
        ret[ind] = expected_damage_integral_computation(x -> f_to_integrate(hspf, dist, x, ddfs[ind], s[ind], im, tol), x_low, maximum(dist), tol)
    end
    return ret
end

function f_to_integrate(hspf::HypsometricProfile{DT}, dist::Distribution, x, dam::F, s, im::IM, tol::Real) where {DT<:Real,F<:Function,IM<:InundationModel}
    p = pdf(dist, x)
    if isnan(p)
        return 0.0
    end
    return damage(hspf, x, s, dam, im) * p
end


function expected_damage_integral_computation(f, lower, upper, tolerance)
    try
        return quadgk(f, lower, upper, rtol=tolerance)[1]
    catch
        return integrate_simple(f, lower, 50)
    end
end
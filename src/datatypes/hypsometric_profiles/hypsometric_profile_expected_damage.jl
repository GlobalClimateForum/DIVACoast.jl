using Distributions

include("hypsometric_profile_expected_damage_special_cases.jl")

"""
    expected_damage_bathtub_standard_ddf(LocalCoastalModel::LocalCoastalModel{DT}, hdd_area::DT, hdds_other::Array{DT})

This function calculates the annual expected damage for one local coastal model (Hypsometric Profile and Extreme surge distribution) by 
integrating the product of damages and the pdf (probability disctribution function) of the surge model over all possible extreme values. 
The output are annual expected damage (as a pair) for area (one number) and for all other exposure dimensions (an array of numbers). 
The standard depth damage function (dd = 1/(1+hdd)) is used to estimate flood damages, the hdd parameters for ares (one number) and for all other exposure dimensions (an array of numbers) are input parameters"""

#expected_damage(hspf::HypsometricProfile{DT}, hazard::Distribution, wl_lower_limit::Real, s::Array{Symbol}, ddfs::Vector{Function}, im::IM=BathtubInundation()) where {DT<:Real,IM<:InundationModel} = damage(hspf, wl, map(x -> String(x), s), ddfs, im)
#expected_damage(hspf::HypsometricProfile{DT}, hazard::Distribution, wl_lower_limit::Real, s::Array{Symbol}, ddfs::Vector{StandardDDF}, im::IM=BathtubInundation()) where {DT<:Real,IM<:InundationModel} = damage(hspf, wl, map(x -> String(x), s), ddfs, im)

expected_damage(hspf::HypsometricProfile{DT}, dist::Distribution, wl_lower_limit::Real, s::Array{Symbol}, ddfs::Vector{Function}, im::IM=BathtubInundation(), tol::Real=1e-3) where {DT<:Real,IM<:InundationModel} = expected_damage(hspf, dist, wl_lower_limit, map(x -> String(x), s), ddfs, im, tol)
expected_damage(hspf::HypsometricProfile{DT}, hazard::Distribution, wl_lower_limit::Real, s::String, ddf::Function, im::IM=BathtubInundation()) where {DT<:Real,IM<:InundationModel} = expected_damage(hspf, hazard, wl_lower_limit, [s], convert(Array{Function}, [ddf]), im)[1]
expected_damage(hspf::HypsometricProfile{DT}, hazard::Distribution, wl_lower_limit::Real, s::Symbol, ddf::Function, im::IM=BathtubInundation()) where {DT<:Real,IM<:InundationModel} = expected_damage(hspf, hazard, wl_lower_limit, [String(s)], convert(Array{Function}, [ddf]), im)[1]

expected_damage(hspf::HypsometricProfile{DT}, hazard::Distribution, wl_lower_limit::Real, s::String, ddf::StandardDDF, im::IM=BathtubInundation()) where {DT<:Real,IM<:InundationModel} = expected_damage(hspf, hazard, wl_lower_limit, [s], convert(Array{StandardDDF}, [ddf]), im)[1]
expected_damage(hspf::HypsometricProfile{DT}, hazard::Distribution, wl_lower_limit::Real, s::Symbol, ddf::StandardDDF, im::IM=BathtubInundation()) where {DT<:Real,IM<:InundationModel} = expected_damage(hspf, hazard, wl_lower_limit, [String(s)], convert(Array{StandardDDF}, [ddf]), im)[1]


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
export LocalCoastalModel,
  expected_damage_bathtub_standard_ddf, expected_damage_bathtub

using Distributions

mutable struct LocalCoastalModel{DT<:Real}
  surge_model::Distribution
  coastal_plain_model::HypsometricProfile{DT}
end
"""
expected_damage_bathtub_standard_ddf(LocalCoastalModel::LocalCoastalModel{DT}, hdd_area::DT, hdds_static::Array{DT}, hdds_dynamic::Array{DT})

This function calculates the annual expected damage for one local coastal model (Hypsometric Profile and Extreme surge distribution) by 
integrating the product of damages and the pdf (probability disctribution function) of the surge model over all possible extreme values. 
The output are annual expected damage for area, static and dynamic. The standard depth damage function is used to estimate flood damages."""
function expected_damage_bathtub_standard_ddf(lcm::LocalCoastalModel{DT}, hdd_area::DT, hdds_static::Array{DT}, hdds_dynamic::Array{DT}) where {DT<:Real}
  edam_area = quadgk(x -> (damage_bathtub_standard_ddf(lcm.coastal_plain_model, x, hdd_area, :area) * pdf(lcm.surge_model, x)), 0, maximum(lcm.surge_model), rtol=1e-3)[1]
  edam_static = Array{DT}(undef, size(lcm.coastal_plain_model.cummulativeStaticExposure)[2])
  edam_dynamic = Array{DT}(undef, size(lcm.coastal_plain_model.cummulativeDynamicExposure)[2])

  for ind in 1:size(lcm.coastal_plain_model.cummulativeStaticExposure, 2)
    edam_static[ind] = quadgk(x -> (damage_bathtub_standard_ddf(lcm.coastal_plain_model, x, hdds_static[ind], lcm.coastal_plain_model.staticExposureSymbols[ind]) * pdf(lcm.surge_model, x)), minimum(0), maximum(lcm.surge_model), rtol=1e-3)[1]
  end

  for ind in 1:size(lcm.coastal_plain_model.cummulativeDynamicExposure, 2)
    edam_dynamic[ind] = quadgk(x -> (damage_bathtub_standard_ddf(lcm.coastal_plain_model, x, hdds_dynamic[ind], lcm.coastal_plain_model.dynamicExposureSymbols[ind]) * pdf(lcm.surge_model, x)), minimum(0), maximum(lcm.surge_model), rtol=1e-3)[1]
  end

  (edam_area, edam_static, edam_dynamic)
end

expected_damage_bathtub_standard_ddf(lcm::LocalCoastalModel{DT}, hdd_area::Real, hdds_static, hdds_dynamic) where {DT<:Real} = 
  if (hdds_static == []) && (hdds_dynamic == [])
    expected_damage_bathtub_standard_ddf(lcm, convert(DT, hdd_area), Matrix{DT}(undef, 0, 0), Matrix{DT}(undef, 0, 0))
  elseif (hdds_static == [])
    expected_damage_bathtub_standard_ddf(lcm, convert(DT, hdd_area), Matrix{DT}(undef, 0, 0), convert(Array{DT}, hdds_dynamic))
  elseif (hdds_dynamic == [])
    expected_damage_bathtub_standard_ddf(lcm, convert(DT, hdd_area), convert(Array{DT}, hdds_static), Matrix{DT}(undef, 0, 0))
  else
    expected_damage_bathtub_standard_ddf(lcm, convert(DT, hdd_area), convert(Array{DT}, hdds_static), convert(Array{DT}, hdds_dynamic))
  end

function expected_damage_bathtub_standard_ddf(lcm::LocalCoastalModel, hdd::Real, s::Symbol)
  quadgk(x -> (damage_bathtub_standard_ddf(lcm.coastal_plain_model, x, hdd, s) * pdf(lcm.surge_model, x)), minimum(0), maximum(lcm.surge_model), rtol=1e-3)[1]
end

"""
expected_damage_bathtub(LocalCoastalModel::LocalCoastalModel{DT}, ddf_area::Function, ddf_static::Array{Function}, ddf_dynamic::Array{Function})

This function calculates the annual expected damage for one local coastal model (Hypsometric Profile and Extreme surge distribution) by 
integrating the product of damages and the pdf (probability disctribution function) of the surge model. The output are annual expected damage 
for area, static and dynamic. The depth damage functions inserted as inputs are used in this functino to calculate flood damages."""
function expected_damage_bathtub(lcm::LocalCoastalModel{DT}, ddf_area::Function, ddf_static::Array{Function}, ddf_dynamic::Array{Function}) where {DT<:Real}
  edam_area = quadgk(x -> (damage_bathtub(lcm.coastal_plain_model, x, ddf_area, :area) * pdf(lcm.surge_model, x)), 0, maximum(lcm.surge_model), rtol=1e-3)[1]
  edam_static = Array{DT}(undef, size(lcm.coastal_plain_model.cummulativeStaticExposure)[2])
  edam_dynamic = Array{DT}(undef, size(lcm.coastal_plain_model.cummulativeDynamicExposure)[2])

  for ind in 1:size(lcm.coastal_plain_model.cummulativeStaticExposure, 2)
    edam_static[ind] = quadgk(x -> (damage_bathtub(lcm.coastal_plain_model, x, ddf_static[ind], lcm.coastal_plain_model.staticExposureSymbols[ind]) * pdf(lcm.surge_model, x)), minimum(0), maximum(lcm.surge_model), rtol=1e-3)[1]
  end

  for ind in 1:size(lcm.coastal_plain_model.cummulativeDynamicExposure, 2)
    edam_dynamic[ind] = quadgk(x -> (damage_bathtub(lcm.coastal_plain_model, x, ddf_dynamic[ind], lcm.coastal_plain_model.dynamicExposureSymbols[ind]) * pdf(lcm.surge_model, x)), minimum(0), maximum(lcm.surge_model), rtol=1e-3)[1]
  end

  (edam_area, edam_static, edam_dynamic)
end

function expected_damage_bathtub(lcm::LocalCoastalModel{DT}, ddf::Function, s::Symbol) where {DT<:Real}
  quadgk(x -> (damage_bathtub(lcm.coastal_plain_model, convert(DT, x), ddf, s) * pdf(lcm.surge_model, x)), minimum(0), maximum(lcm.surge_model), rtol=1e-3)[1]
end

exposure_below_bathtub(lcm::LocalCoastalModel{DT}, e::Real) where {DT<:Real} = exposure_below_bathtub(lcm.coastal_plain_model, e)
exposure_below_bathtub(lcm::LocalCoastalModel{DT}, e::Real, s::Symbol) where {DT<:Real} = exposure_below_bathtub(lcm.coastal_plain_model, s, e)

damage_bathtub_standard_ddf(lcm::LocalCoastalModel{DT}, wl, hdd_area, hdds_static, hdds_dynamic) where {DT<:Real} = damage_standard_ddf(lcm.coastal_plain_model, wl, hdd_area, hdds_static, hdds_dynamic)
damage_bathtub_standard_ddf(lcm::LocalCoastalModel{DT}, wl::T1, hdd::T2, s::Symbol) where {DT<:Real,T1<:Real,T2<:Real} = damage_standard_ddf(lcm.coastal_plain_model, s, convert(DT, wl), convert(DT, hdd))

export LocalCoastalImpactModel, CoastalImpactUnit,
  expected_damage_bathtub_standard_ddf, expected_damage_bathtub, exposure_below_bathtub,
  apply_accumulate, apply_accumulate_record, apply, apply_accumulate_store, 
  apply_accumulate_store_multithread, apply_store, apply_store_multithread,
  collect_data
  
using Distributions
using QuadGK

abstract type CoastalImpactUnit end

"""
    LocalCoastalImpactModel{DT<:Real, IDT, DATA} <: CoastalImpactUnit
A `LocalCoastalImpactModel` combines a surge model (distribution) and a coastal plain model (`HypsometricProfile`).
It also holds the current protection level.
"""
mutable struct LocalCoastalImpactModel{DT<:Real, IDT, DATA} <: CoastalImpactUnit
  id :: IDT
  surge_model :: Distribution
  coastal_plain_model :: HypsometricProfile{DT}
  protection_level :: Real
  data :: DATA
end

"""
expected_damage_bathtub_standard_ddf(LocalCoastalModel::LocalCoastalModel{DT}, hdd_area::DT, hdds_static::Array{DT}, hdds_dynamic::Array{DT})

This function calculates the annual expected damage for one local coastal model (Hypsometric Profile and Extreme surge distribution) by 
integrating the product of damages and the pdf (probability disctribution function) of the surge model over all possible extreme values. The output are annual expected damage for area, static and dynamic. The standard depth damage function is used to estimate flood damages."""
function expected_damage_bathtub_standard_ddf(lcm::LocalCoastalImpactModel{DT, DATA}, hdd_area::DT, hdds_static::Array{DT}, hdds_dynamic::Array{DT}) where {DT<:Real, DATA}
#  edam_area = quadgk(x -> (damage_bathtub_standard_ddf(lcm.coastal_plain_model, x, hdd_area, :area) * pdf(lcm.surge_model, x)), lcm.coastal_plain_model.elevation[1], maximum(lcm.surge_model), rtol=1e-3)[1]
  lower_limit = if lcm.protection_level==0 lcm.coastal_plain_model.elevation[1] else quantile(lcm.surge_model,1-1/lcm.protection_level) end

  edam_area = expected_damage_integral_computation(lcm, "area", x -> (damage_bathtub_standard_ddf(lcm.coastal_plain_model, x, hdd_area, :area) * pdf(lcm.surge_model, x)), lower_limit, maximum(lcm.surge_model), 1e-3)

  edam_static = Array{DT}(undef, size(lcm.coastal_plain_model.cummulativeStaticExposure)[2])
  edam_dynamic = Array{DT}(undef, size(lcm.coastal_plain_model.cummulativeDynamicExposure)[2])

  for ind in 1:size(lcm.coastal_plain_model.cummulativeStaticExposure, 2)
    edam_static[ind] = expected_damage_integral_computation(lcm, String(lcm.coastal_plain_model.staticExposureSymbols[ind]), x -> (damage_bathtub_standard_ddf(lcm.coastal_plain_model, x, hdds_static[ind], lcm.coastal_plain_model.staticExposureSymbols[ind]) * pdf(lcm.surge_model, x)), lower_limit, maximum(lcm.surge_model), 1e-3)
  end

  for ind in 1:size(lcm.coastal_plain_model.cummulativeDynamicExposure, 2)
    edam_dynamic[ind] = expected_damage_integral_computation(lcm, String(lcm.coastal_plain_model.dynamicExposureSymbols[ind]), x -> (damage_bathtub_standard_ddf(lcm.coastal_plain_model, x, hdds_dynamic[ind], lcm.coastal_plain_model.dynamicExposureSymbols[ind]) * pdf(lcm.surge_model, x)), lower_limit, maximum(lcm.surge_model), 1e-3)
  end

  (edam_area, edam_static, edam_dynamic)
end

expected_damage_bathtub_standard_ddf(lcm::LocalCoastalImpactModel{DT,DATA}, hdd_area::Real, hdds_static, hdds_dynamic) where {DT<:Real, DATA} = 
  if (hdds_static == []) && (hdds_dynamic == [])
    expected_damage_bathtub_standard_ddf(lcm, convert(DT, hdd_area), Matrix{DT}(undef, 0, 0), Matrix{DT}(undef, 0, 0))
  elseif (hdds_static == [])
    expected_damage_bathtub_standard_ddf(lcm, convert(DT, hdd_area), Matrix{DT}(undef, 0, 0), convert(Array{DT}, hdds_dynamic))
  elseif (hdds_dynamic == [])
    expected_damage_bathtub_standard_ddf(lcm, convert(DT, hdd_area), convert(Array{DT}, hdds_static), Matrix{DT}(undef, 0, 0))
  else
    expected_damage_bathtub_standard_ddf(lcm, convert(DT, hdd_area), convert(Array{DT}, hdds_static), convert(Array{DT}, hdds_dynamic))
  end

function expected_damage_bathtub_standard_ddf(lcm::LocalCoastalImpactModel, hdd::Real, s::Symbol)
  lower_limit = if lcm.protection_level==0 lcm.coastal_plain_model.elevation[1] else quantile(lcm.surge_model,1-1/lcm.protection_level) end
  expected_damage_integral_computation(lcm, String(s), x -> (damage_bathtub_standard_ddf(lcm.coastal_plain_model, x, hdd, s) * pdf(lcm.surge_model, x)), lower_limit, maximum(lcm.surge_model), 1e-3)
end

"""
expected_damage_bathtub(LocalCoastalModel::LocalCoastalModel{DT}, ddf_area::Function, ddf_static::Array{Function}, ddf_dynamic::Array{Function})

This function calculates the annual expected damage for one local coastal model (Hypsometric Profile and Extreme surge distribution) by 
integrating the product of damages and the pdf (probability disctribution function) of the surge model. The output are annual expected damage 
for area, static and dynamic. The depth damage functions inserted as inputs are used in this functino to calculate flood damages."""
function expected_damage_bathtub(lcm::LocalCoastalImpactModel{DT}, ddf_area::Function, ddf_static::Array{Function}, ddf_dynamic::Array{Function}) where {DT<:Real}
  lower_limit = if lcm.protection_level==0 lcm.coastal_plain_model.elevation[1] else quantile(lcm.surge_model,1-1/lcm.protection_level) end

  edam_area = expected_damage_integral_computation(lcm, "area", x -> damage_bathtub(lcm.coastal_plain_model, x, ddf_area, :area) * pdf(lcm.surge_model, x), lower_limit, maximum(lcm.surge_model), 1e-3)

  edam_static = Array{DT}(undef, size(lcm.coastal_plain_model.cummulativeStaticExposure)[2])
  edam_dynamic = Array{DT}(undef, size(lcm.coastal_plain_model.cummulativeDynamicExposure)[2])

  for ind in 1:size(lcm.coastal_plain_model.cummulativeStaticExposure, 2)
    edam_static[ind] = expected_damage_integral_computation(lcm, String(lcm.coastal_plain_model.staticExposureSymbols[ind]), x -> damage_bathtub(lcm.coastal_plain_model, x, ddf_static[ind], lcm.coastal_plain_model.staticExposureSymbols[ind]) * pdf(lcm.surge_model, x), lower_limit, maximum(lcm.surge_model), 1e-3)
  end

  for ind in 1:size(lcm.coastal_plain_model.cummulativeDynamicExposure, 2)
    edam_dynamic[ind] = expected_damage_integral_computation(lcm, String(lcm.coastal_plain_model.dynamicExposureSymbols[ind]), x -> damage_bathtub(lcm.coastal_plain_model, x, ddf_dynamic[ind], lcm.coastal_plain_model.dynamicExposureSymbols[ind]) * pdf(lcm.surge_model, x), lower_limit, maximum(lcm.surge_model), 1e-3)
  end

  (edam_area, edam_static, edam_dynamic)
end

function expected_damage_bathtub(lcm::LocalCoastalImpactModel{DT,DATA}, ddf::Function, s::Symbol) where {DT<:Real, DATA}
  lower_limit = if lcm.protection_level==0 lcm.coastal_plain_model.elevation[1] else quantile(lcm.surge_model,1-1/lcm.protection_level) end
  expected_damage_integral_computation(lcm, String(s), x -> (damage_bathtub(lcm.coastal_plain_model, convert(DT, x), ddf, s) * pdf(lcm.surge_model, x)), lower_limit, maximum(lcm.surge_model), 1e-3)
end

function expected_damage_integral_computation(lcm::LocalCoastalImpactModel{DT, DATA}, s::String, f, lower, upper, tolerance) where {DT<:Real, DATA}
  try
    return quadgk(f, lower, upper, rtol=tolerance)[1]
  catch
    #println("I failed $(lcm.id) - $s")
    return 0.0
  end
end


exposure_below_bathtub(lcm::LocalCoastalImpactModel{DT, DATA}, e::Real) where {DT<:Real,DATA} = exposure_below_bathtub(lcm.coastal_plain_model, e)
exposure_below_bathtub(lcm::LocalCoastalImpactModel{DT, DATA}, e::Real, s::Symbol) where {DT<:Real,DATA} = exposure_below_bathtub(lcm.coastal_plain_model, s, e)

damage_bathtub_standard_ddf(lcm::LocalCoastalImpactModel{DT, DATA}, wl, hdd_area, hdds_static, hdds_dynamic, ) where {DT<:Real,DATA} = damage_standard_ddf(lcm.coastal_plain_model, wl, hdd_area, hdds_static, hdds_dynamic)
damage_bathtub_standard_ddf(lcm::LocalCoastalImpactModel{DT, DATA}, wl::T1, hdd::T2, s::Symbol) where {DT<:Real,T1<:Real,T2<:Real,DATA} = damage_standard_ddf(lcm.coastal_plain_model, s, convert(DT, wl), convert(DT, hdd))


function apply_accumulate(lm :: LocalCoastalImpactModel{DT, DATA}, f :: Function, accumulate :: Function) where {DT<:Real, DATA}
  return f(lm)
end

function apply_accumulate_record(lm :: LocalCoastalImpactModel{DT, DATA}, f :: Function, accumulate :: Function) where {DT<:Real, DATA}
  return f(lm)
end

function apply_accumulate_store(lm :: LocalCoastalImpactModel{DT, DATA}, f :: Function, accumulate :: Function, store :: Function) where {DT<:Real, DATA}
  res = f(lm)
  store(res,lm)
  return res
end

function apply_accumulate_store_multithread(lm :: LocalCoastalImpactModel{DT, DATA}, f :: Function, accumulate :: Function, store :: Function, mtlevel :: String) where {DT<:Real, DATA}
  res = f(lm)
  store(res,lm)
  return res
end

@inline
function apply(lm :: LocalCoastalImpactModel{DT, DATA}, f :: Function) where {DT<:Real, DATA}
  f(lm)
end

function apply_store(lm :: LocalCoastalImpactModel{DT, DATA}, f::Function, store::Function) where {DT<:Real, DATA}
  f(lm)
  store(lm)
end

function apply_store_multithread(lm :: LocalCoastalImpactModel{DT, DATA}, f::Function, store::Function, mtlevel :: String)  where {DT<:Real, DATA}
  f(lm)
  store(lm)
end

@inline
function find(lm :: LocalCoastalImpactModel{DT, DATA}, level::String, id :: IT3) where {DT<:Real, DATA, IT3} 
  return false
end

@inline
function collect_data(lm :: LocalCoastalImpactModel{DT, DATA}, outputs, output_row_names, output_rows, metadata, metadatanames) where {DT<:Real, DATA} 
  # do nothing
end

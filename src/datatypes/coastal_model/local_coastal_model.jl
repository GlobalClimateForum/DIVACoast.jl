export LocalCoastalImpactModel, CoastalImpactUnit,
  exposure,
  expected_damage_bathtub_standard_ddf, expected_damage_bathtub, damage_bathtub_standard_ddf,
  apply_accumulate, apply_accumulate_record, apply, apply_multithread, apply_accumulate_store,
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
mutable struct LocalCoastalImpactModel{DT<:Real,IDT,DATA} <: CoastalImpactUnit
  id::IDT
  surge_model::Distribution
  coastal_plain_model::HypsometricProfile{DT}
  protection_level::Real
  data::DATA
end

"""
    expected_damage_bathtub_standard_ddf(LocalCoastalModel::LocalCoastalModel{DT}, hdd_area::DT, hdds_other::Array{DT})

This function calculates the annual expected damage for one local coastal model (Hypsometric Profile and Extreme surge distribution) by 
integrating the product of damages and the pdf (probability disctribution function) of the surge model over all possible extreme values. 
The output are annual expected damage (as a pair) for area (one number) and for all other exposure dimensions (an array of numbers). 
The standard depth damage function (dd = 1/(1+hdd)) is used to estimate flood damages, the hdd parameters for ares (one number) and for all other exposure dimensions (an array of numbers) are input parameters"""
function expected_damage_bathtub_standard_ddf(lcm::LocalCoastalImpactModel{DT,DATA}, hdd_area::DT, hdds_other::Array{DT}, tol::Real=1e-3) where {DT<:Real,DATA}
  lower_limit = if lcm.protection_level == 0
    lcm.coastal_plain_model.elevation[1]
  else
    quantile(lcm.surge_model, 1 - 1 / lcm.protection_level)
  end

  edam_area = expected_damage_integral_computation(lcm, "area", x -> f_to_integrate(lcm, x, hdd_area, :area), lower_limit, maximum(lcm.surge_model), tol)
  edam_other = Array{DT}(undef, size(lcm.coastal_plain_model.cummulativeExposure)[2])

  for ind in 1:size(lcm.coastal_plain_model.cummulativeExposure, 2)
    edam_other[ind] = expected_damage_integral_computation(lcm, String(lcm.coastal_plain_model.exposureNames[ind]), x -> f_to_integrate(lcm, x, hdds_other[ind], Symbol(lcm.coastal_plain_model.exposureNames[ind])), lower_limit, maximum(lcm.surge_model), tol)
  end

  (edam_area, edam_other)
end

expected_damage_bathtub_standard_ddf(lcm::LocalCoastalImpactModel{DT,DATA}, hdd_area::Real, hdds_other, tol::Real=1e-3) where {DT<:Real,DATA} =
  if (hdds_other == [])
    expected_damage_bathtub_standard_ddf(lcm, convert(DT, hdd_area), Matrix{DT}(undef, 0, 0), tol)
  else
    expected_damage_bathtub_standard_ddf(lcm, convert(DT, hdd_area), convert(Array{DT}, hdds_other), tol)
  end

function expected_damage_bathtub_standard_ddf(lcm::LocalCoastalImpactModel, hdd::Real, s::Symbol, tol::Real=1e-3)
  lower_limit = if lcm.protection_level == 0
    lcm.coastal_plain_model.elevation[1]
  else
    quantile(lcm.surge_model, 1 - 1 / lcm.protection_level)
  end
  expected_damage_integral_computation(lcm, String(s), x -> (damage_bathtub_standard_ddf(lcm.coastal_plain_model, x, hdd, s) * pdf(lcm.surge_model, x)), lower_limit, maximum(lcm.surge_model), tol)
end

"""
    expected_damage_bathtub(LocalCoastalModel::LocalCoastalModel{DT}, ddf_area::Function, ddf_other::Array{Function})

This function calculates the (annual) expected damage for one local coastal model (Hypsometric Profile and Extreme surge distribution) by 
integrating the product of damages and the pdf (probability disctribution function) of the surge model. The output are annual expected damage 
for (one number) and for all other exposure dimensions (an array of numbers). 
The depth damage functions for ares (one function) and for all other exposure dimensions (an array of functions) are input parameters."""
function expected_damage_bathtub(lcm::LocalCoastalImpactModel{DT}, ddf_area::Function, ddf_other::Array{Function}, tol::Real=1e-3) where {DT<:Real}
  lower_limit = if lcm.protection_level == 0
    lcm.coastal_plain_model.elevation[1]
  else
    quantile(lcm.surge_model, 1 - 1 / lcm.protection_level)
  end

  edam_area = expected_damage_integral_computation(lcm, "area", x -> damage_bathtub(lcm.coastal_plain_model, x, ddf_area, :area) * pdf(lcm.surge_model, x), lower_limit, maximum(lcm.surge_model), tol)
  edam_other = Array{DT}(undef, size(lcm.coastal_plain_model.cummulativeExposure)[2])

  for ind in 1:size(lcm.coastal_plain_model.cummulativeExposure, 2)
    edam_other[ind] = expected_damage_integral_computation(lcm, String(lcm.coastal_plain_model.exposureNames[ind]), x -> damage_bathtub(lcm.coastal_plain_model, x, ddf_other[ind], lcm.coastal_plain_model.exposureNames[ind]) * pdf(lcm.surge_model, x), lower_limit, maximum(lcm.surge_model), tol)
  end

  (edam_area, edam_other)
end

function expected_damage_bathtub(lcm::LocalCoastalImpactModel{DT,DATA}, ddf::Function, s::Symbol, tol::Real=1e-3) where {DT<:Real,DATA}
  lower_limit = if lcm.protection_level == 0
    lcm.coastal_plain_model.elevation[1]
  else
    quantile(lcm.surge_model, 1 - 1 / lcm.protection_level)
  end
  expected_damage_integral_computation(lcm, String(s), x -> (damage_bathtub(lcm.coastal_plain_model, convert(DT, x), ddf, s) * pdf(lcm.surge_model, x)), lower_limit, maximum(lcm.surge_model), tol)
end

function f_to_integrate(lcm, x, hdd, s)
  p = pdf(lcm.surge_model, x)
  if isnan(p)
    return 0.0
  end
  return damage_bathtub_standard_ddf(lcm.coastal_plain_model, x, hdd, s) * p
end

function expected_damage_integral_computation(lcm::LocalCoastalImpactModel{DT,DATA}, s::String, f, lower, upper, tolerance) where {DT<:Real,DATA}
  try
    return quadgk(f, lower, upper, rtol=tolerance)[1]
  catch
    #   println("I failed $(lcm.id) - $s")
    return integrate_simple(f, lower, 30)
  end
end


exposure(lcm::LocalCoastalImpactModel{DT,DATA}, wl::Number, im::IM=BathtubInundation()) where {DT<:Real,IM<:InundationModel,DATA} = exposure(lcm.coastal_plain_model, wl, im)
exposure(lcm::LocalCoastalImpactModel{DT,DATA}, wl::Number, s, im::IM=BathtubInundation()) where {DT<:Real,IM<:InundationModel,DATA} = exposure(lcm.coastal_plain_model, wl, s, im)
damage(lcm::LocalCoastalImpactModel{DT,DATA}, wl::Real, s, ddfs, im::IM=BathtubInundation()) where {DT<:Real,IM<:InundationModel,DATA} = damage(lcm.coastal_plain_model, wl, s, ddfs, im) 

damage_bathtub_standard_ddf(lcm::LocalCoastalImpactModel{DT,DATA}, wl, hdd_area, hdds_other) where {DT<:Real,DATA} = damage_bathtub_standard_ddf(lcm.coastal_plain_model, wl, hdd_area, hdds_other)
damage_bathtub_standard_ddf(lcm::LocalCoastalImpactModel{DT,DATA}, wl::T1, hdd::T2, s::Symbol) where {DT<:Real,T1<:Real,T2<:Real,DATA} = damage_bathtub_standard_ddf(lcm.coastal_plain_model, convert(DT, wl), convert(DT, hdd), s)


function apply_accumulate(lm::LocalCoastalImpactModel{DT,DATA}, f::Function, accumulate::Function) where {DT<:Real,DATA}
  return f(lm)
end

function apply_accumulate_record(lm::LocalCoastalImpactModel{DT,DATA}, f::Function, accumulate::Function) where {DT<:Real,DATA}
  return f(lm)
end

function apply_accumulate_store(lm::LocalCoastalImpactModel{DT,DATA}, f::Function, accumulate::Function, store::Function) where {DT<:Real,DATA}
  res = f(lm)
  store(res, lm)
  return res
end

function apply_accumulate_store_multithread(lm::LocalCoastalImpactModel{DT,DATA}, f::Function, accumulate::Function, store::Function, mtlevel::String) where {DT<:Real,DATA}
  res = f(lm)
  store(res, lm)
  return res
end

@inline
function apply(lm::LocalCoastalImpactModel{DT,DATA}, f::Function) where {DT<:Real,DATA}
  f(lm)
end

@inline
function apply_multithread(lm::LocalCoastalImpactModel{DT,DATA}, f::Function, mtlevel::String) where {DT<:Real,DATA}
  f(lm)
end

function apply_store(lm::LocalCoastalImpactModel{DT,DATA}, f::Function, store::Function) where {DT<:Real,DATA}
  f(lm)
  store(lm)
end

function apply_store_multithread(lm::LocalCoastalImpactModel{DT,DATA}, f::Function, store::Function, mtlevel::String) where {DT<:Real,DATA}
  f(lm)
  store(lm)
end

@inline
function find(lm::LocalCoastalImpactModel{DT,DATA}, level::String, id::IT3) where {DT<:Real,DATA,IT3}
  return false
end

@inline
function collect_data(lm::LocalCoastalImpactModel{DT,DATA}, outputs, output_row_names, output_rows, metadata, metadatanames) where {DT<:Real,DATA}
  # do nothing
end

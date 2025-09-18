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
#mutable struct LocalCoastalImpactModel{DT<:Real,IDT,DATA} <: CoastalImpactUnit
mutable struct LocalCoastalImpactModel{DT<:Real,IDT,DATA,DIST<:Distribution} <: CoastalImpactUnit
  id::IDT
  surge_model::DIST
  coastal_plain_model::HypsometricProfile{DT}
  protection_level::Float64
  data::DATA
end
LocalCoastalImpactModel(id::IDT, surge_model::DIST, coastal_plain_model::HypsometricProfile{DT}, protection_level::Real, data::DATA) where {DT<:Real,IDT,DATA,DIST<:Distribution} = LocalCoastalImpactModel{DT,IDT,DATA,DIST}(id, surge_model, coastal_plain_model, convert(Float64,protection_level), data)

exposure(lcm::LocalCoastalImpactModel{DT,IDT,DATA,DIST}, wl::Number, im::IM=BathtubInundation()) where {DT<:Real,IM<:InundationModel,IDT,DATA,DIST<:Distribution} = exposure(lcm.coastal_plain_model, wl, im)
exposure(lcm::LocalCoastalImpactModel{DT,IDT,DATA,DIST}, wl::Number, s, im::IM=BathtubInundation()) where {DT<:Real,IM<:InundationModel,IDT,DATA,DIST<:Distribution} = exposure(lcm.coastal_plain_model, wl, s, im)
damage(lcm::LocalCoastalImpactModel{DT,IDT,DATA,DIST}, wl::Real, s, ddfs, im::IM=BathtubInundation()) where {DT<:Real,IM<:InundationModel,IDT,DATA,DIST<:Distribution} = damage(lcm.coastal_plain_model, wl, s, ddfs, im)

function expected_damage(lcm::LocalCoastalImpactModel{DT,IDT,DATA,DIST}, s, ddfs, im::IM=BathtubInundation(); rtol::Real=1e-3) where {DT<:Real,IM<:InundationModel,IDT,DATA,DIST<:Distribution}
  protection_height = if lcm.protection_level == 0
    0.0
  else
    quantile(lcm.surge_model, 1 - 1 / lcm.protection_level)
  end
  expected_damage(lcm.coastal_plain_model, lcm.surge_model, protection_height, s, ddfs, im; rtol)
end

function apply_accumulate(lm::LocalCoastalImpactModel{DT,IDT,DATA,DIST}, f::Function, accumulate::Function) where {DT<:Real,IDT,DATA,DIST<:Distribution}
  return f(lm)
end

function apply_accumulate_record(lm::LocalCoastalImpactModel{DT,IDT,DATA,DIST}, f::Function, accumulate::Function) where {DT<:Real,IDT,DATA,DIST<:Distribution}
  return f(lm)
end

function apply_accumulate_store(lm::LocalCoastalImpactModel{DT,IDT,DATA,DIST}, f::Function, accumulate::Function, store::Function) where {DT<:Real,IDT,DATA,DIST<:Distribution}
  res = f(lm)
  store(res, lm)
  return res
end

function apply_accumulate_store_multithread(lm::LocalCoastalImpactModel{DT,IDT,DATA,DIST}, f::Function, accumulate::Function, store::Function, mtlevel::String) where {DT<:Real,IDT,DATA,DIST<:Distribution}
  res = f(lm)
  store(res, lm)
  return res
end

@inline
function apply(lm::LocalCoastalImpactModel{DT,IDT,DATA,DIST}, f::Function) where {DT<:Real,IDT,DATA,DIST<:Distribution}
  f(lm)
end

@inline
function apply_multithread(lm::LocalCoastalImpactModel{DT,IDT,DATA,DIST}, f::Function, mtlevel::String) where {DT<:Real,IDT,DATA,DIST<:Distribution}
  f(lm)
end

function apply_store(lm::LocalCoastalImpactModel{DT,IDT,DATA,DIST}, f::Function, store::Function) where {DT<:Real,IDT,DATA,DIST<:Distribution}
  f(lm)
  store(lm)
end

function apply_store_multithread(lm::LocalCoastalImpactModel{DT,IDT,DATA,DIST}, f::Function, store::Function, mtlevel::String) where {DT<:Real,IDT,DATA,DIST<:Distribution}
  f(lm)
  store(lm)
end

@inline
function find(lm::LocalCoastalImpactModel{DT,IDT,DATA,DIST}, level::String, id::IT3) where {DT<:Real,IDT,DATA,IT3,DIST<:Distribution}
  return false
end

@inline
function collect_data(lm::LocalCoastalImpactModel{DT,IDT,DATA,DIST}, outputs, output_row_names, output_rows, metadata, metadatanames) where {DT<:Real,IDT,DATA,DIST<:Distribution}
  # do nothing
end

export LocalCoastalModel,
  expected_damage_standard_ddf, expected_damage

using Distributions

mutable struct LocalCoastalModel{DT<:Real}
  surge_model::Distribution
  coastal_plain_model::HypsometricProfile{DT}
end

function expected_damage_standard_ddf(lcm::LocalCoastalModel{DT}, hdd_area::DT, hdds_static::Array{DT}, hdds_dynamic::Array{DT}) where {DT<:Real}
  edam_area = quadgk(x -> (damage_standard_ddf(lcm.coastal_plain_model, :area, x, hdd_area) * pdf(lcm.surge_model, x)), 0, maximum(lcm.surge_model), rtol=1e-2)[1]
  edam_static = Array{DT}(undef, size(lcm.coastal_plain_model.cummulativeStaticExposure)[2])
  edam_dynamic = Array{DT}(undef, size(lcm.coastal_plain_model.cummulativeDynamicExposure)[2])

  for ind in 1:size(lcm.coastal_plain_model.cummulativeStaticExposure, 2)
    edam_static[ind] = quadgk(x -> (damage_standard_ddf(lcm.coastal_plain_model, lcm.coastal_plain_model.staticExposureSymbols[ind], x, hdds_static[ind]) * pdf(lcm.surge_model, x)), minimum(0), maximum(lcm.surge_model), rtol=1e-2)[1]
  end

  for ind in 1:size(lcm.coastal_plain_model.cummulativeDynamicExposure, 2)
    edam_dynamic[ind] = quadgk(x -> (damage_standard_ddf(lcm.coastal_plain_model, lcm.coastal_plain_model.dynamicExposureSymbols[ind], x, hdds_dynamic[ind]) * pdf(lcm.surge_model, x)), minimum(0), maximum(lcm.surge_model), rtol=1e-2)[1]
  end

  (edam_area, edam_static, edam_dynamic)
end

expected_damage_standard_ddf(lcm::LocalCoastalModel{DT}, hdd_area::Real, hdds_static, hdds_dynamic) where {DT<:Real} = 
  if (hdds_static == [])
    expected_damage_standard_ddf(lcm, convert(DT, hdd_area), Matrix{DT}(undef, 0, 0), hdds_dynamic)
  else
    expected_damage_standard_ddf(lcm, convert(DT, hdd_area), convert(Array{DT}, hdds_static), hdds_dynamic)
  end

function expected_damage_standard_ddf(lcm::LocalCoastalModel, s::Symbol, hdd::Real)
  quadgk(x -> (damage_standard_ddf(lcm.coastal_plain_model, s, x, hdd) * pdf(lcm.surge_model, x)), minimum(0), quantile(lcm.surge_model,0.9999), rtol=1e-3)[1]
end

exposure_below(lcm::LocalCoastalModel{DT}, e::Real) where {DT<:Real} = exposure_below(lcm.coastal_plain_model, e)
exposure_below(lcm::LocalCoastalModel{DT}, s::Symbol, e::Real) where {DT<:Real} = exposure_below(lcm.coastal_plain_model, s, e)

damage_standard_ddf(lcm::LocalCoastalModel{DT}, wl, hdd_area, hdds_static, hdds_dynamic) where {DT<:Real} = damage_standard_ddf(lcm.coastal_plain_model, wl, hdd_area, hdds_static, hdds_dynamic)
damage_standard_ddf(lcm::LocalCoastalModel{DT}, s::Symbol, wl::T1, hdd::T2) where {DT<:Real,T1<:Real,T2<:Real} = damage_standard_ddf(lcm.coastal_plain_model, s, convert(DT, wl), convert(DT, hdd))

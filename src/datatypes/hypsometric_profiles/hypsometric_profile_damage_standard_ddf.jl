using QuadGK

# special case ddf = d/(d+hdd)
function damage_bathtub_standard_ddf(hspf::HypsometricProfile{DT}, wl::DT, hdd_area::DT, hdds_static::Array{DT}, hdds_dynamic::Array{DT}) where {DT<:Real}
  dam = exposure_below_bathtub(hspf, first(hspf.elevation))
  dam_area = dam[1]
  dam_static = dam[2]
  dam_dynamic = dam[3]

  for ind in 1:size(hspf.elevation, 1)-1
    if hspf.elevation[ind] > wl
      return (dam_area, dam_static, dam_dynamic)
    else
      sl = slope(hspf, ind + 1)
      wl_low = hspf.elevation[ind]
      wl_high = (hspf.elevation[ind+1] <= wl) ? hspf.elevation[ind+1] : wl

      Δ_area = (hspf.elevation[ind+1] <= wl) ? hspf.cummulativeArea[ind+1] - hspf.cummulativeArea[ind] : exposure_below_bathtub(hspf, wl_high, :area) - hspf.cummulativeArea[ind]

      if (Δ_area != 0)
        Δ_exp_st = (hspf.elevation[ind+1] <= wl) ? (
          size(hspf.cummulativeStaticExposure)[2] >= 1 ? hspf.cummulativeStaticExposure[ind+1, :] - hspf.cummulativeStaticExposure[ind, :] : Array{DT,2}(undef, 0, 0)
        ) : (
          size(hspf.cummulativeStaticExposure)[2] >= 1 ? exposure_below_bathtub(hspf, wl)[2] - hspf.cummulativeStaticExposure[ind, :] : Array{DT,2}(undef, 0, 0)
        )

        Δ_exp_dy = (hspf.elevation[ind+1] <= wl) ? (
          size(hspf.cummulativeDynamicExposure)[2] >= 1 ? hspf.cummulativeDynamicExposure[ind+1, :] - hspf.cummulativeDynamicExposure[ind, :] : Array{DT,2}(undef, 0, 0)
        ) : (
          size(hspf.cummulativeDynamicExposure)[2] >= 1 ? exposure_below_bathtub(hspf, wl)[3] - hspf.cummulativeDynamicExposure[ind, :] : Array{DT,2}(undef, 0, 0)
        )
        ρ_area = hspf.width / 1000
        ρ_exp_st = (Δ_exp_st / (Δ_area / hspf.width)) / 1000
        ρ_exp_dy = (Δ_exp_dy / (Δ_area / hspf.width)) / 1000
        dam_t = partial_damage_bathtub_standard_ddf(hspf, wl, hdd_area, hdds_static, hdds_dynamic, sl, wl_low, wl_high, Δ_area, Δ_exp_st, Δ_exp_dy, ρ_area, ρ_exp_st, ρ_exp_dy)
        dam_area = dam_area + dam[1]
        dam_static = (size(dam_t[2], 1) > 0) ? dam_static + dam_t[2] : dam_static
        dam_dynamic = (size(dam_t[3], 1) > 0) ? dam_dynamic + dam_t[3] : dam_dynamic
      end
    end
  end

  return (dam_area, dam_static, dam_dynamic)
end


function damage_bathtub_standard_ddf(hspf::HypsometricProfile{DT}, wl::DT, hdd::DT, s::Symbol)::DT where {DT<:Real}
  pos = get_position(hspf, s)
  if (pos[1] == -1)
    return zero(DT)
  end

  dam = exposure_below_bathtub(hspf, first(hspf.elevation), s)
  exposure = zeros(DT, size(hspf.elevation, 1))
  if (pos[1] == 1)
    exposure = hspf.cummulativeArea
  end
  if (pos[1] == 2)
    exposure = hspf.cummulativeStaticExposure[:, pos[2]]
  end
  if (pos[1] == 3)
    exposure = hspf.cummulativeDynamicExposure[:, pos[2]]
  end

  for ind in 1:size(hspf.elevation, 1)-1
    if hspf.elevation[ind] > wl
      return dam
    else
      sl = slope(hspf, ind + 1)
      wl_low = hspf.elevation[ind]
      wl_high = (hspf.elevation[ind+1] <= wl) ? hspf.elevation[ind+1] : wl

      Δ_exp = (hspf.elevation[ind+1] <= wl) ? exposure[ind+1] - exposure[ind] : exposure_below_bathtub(hspf, wl_high, s) - exposure[ind]
      Δ_area = (hspf.elevation[ind+1] <= wl) ? hspf.cummulativeArea[ind+1] - hspf.cummulativeArea[ind] : exposure_below_bathtub(hspf, wl_high, :area) - hspf.cummulativeArea[ind]

      if (Δ_area != 0 && Δ_exp != 0)
        ρ_exp = (Δ_exp / (Δ_area / hspf.width)) / 1000
        Δ_elevation1 = wl - wl_high
        Δ_elevation2 = wl - wl_low
        Δ_elevation3 = wl_high - wl_low
        factor = (hdd > 0) ? hdd * log((hdd + Δ_elevation1) / (hdd + Δ_elevation2)) + Δ_elevation3 : sl / ρ_exp * Δ_exp
        dam += factor * ρ_exp / sl
        if isnan(dam) println("$factor * $(ρ_exp) / $sl") end
      end
    end
  end
  return dam
end


damage_bathtub_standard_ddf(hspf::HypsometricProfile{DT}, wl::Real, hdd_area::Real, hdds_static::Array{DT}, hdds_dynamic::Array{DT}) where {DT<:Real} = damage_bathtub_standard_ddf(hspf, convert(DT, wl), convert(DT, hdd_area), hdds_static, hdds_dynamic)
damage_bathtub_standard_ddf(hspf::HypsometricProfile{DT}, wl::Real, hdd_area::Real, hdds_static::Array{T1}, hdds_dynamic::Array{T2}) where {DT<:Real,T1<:Real,T2<:Real} = damage_bathtub_standard_ddf(hspf, convert(DT, wl), convert(DT, hdd_area), convert(Array{DT}, hdds_static), convert(Array{DT}, hdds_dynamic))
damage_bathtub_standard_ddf(hspf::HypsometricProfile{DT}, wl::Real, hdd_area::Real, hdds_static::Vector{Any}, hdds_dynamic::Array{DT}) where {DT<:Real} =
  if (hdds_static == [])
    damage_bathtub_standard_ddf(hspf, convert(DT, wl), convert(DT, hdd_area), Matrix{DT}(undef, 0, 0), hdds_dynamic)
  else
    damage_bathtub_standard_ddf(hspf, convert(DT, wl), convert(DT, hdd_area), convert(Array{DT}, hdds_static), hdds_dynamic)
  end
damage_bathtub_standard_ddf(hspf::HypsometricProfile{DT}, wl::Real, hdd_area::Real, hdds_static::Vector{DT}, hdds_dynamic::Array{Any}) where {DT<:Real} =
  if (hdds_dynamic == [])
    damage_bathtub_standard_ddf(hspf, convert(DT, wl), convert(DT, hdd_area), hdds_static, convert(Array{DT}, hdds_dynamic))
  else
    damage_bathtub_standard_ddf(hspf, convert(DT, wl), convert(DT, hdd_area), hdds_static, Matrix{DT}(undef, 0, 0))
  end
damage_bathtub_standard_ddf(hspf::HypsometricProfile{DT}, wl::Real, hdd_area::Real, hdds_static::Vector{Any}, hdds_dynamic::Array{T}) where {DT<:Real,T<:Real} =
  if (hdds_static == [])
    damage_bathtub_standard_ddf(hspf, convert(DT, wl), convert(DT, hdd_area), Matrix{DT}(undef, 0, 0), convert(Array{DT}, hdds_dynamic))
  else
    damage_bathtub_standard_ddf(hspf, convert(DT, wl), convert(DT, hdd_area), convert(Array{DT}, hdds_static), convert(Array{DT}, hdds_dynamic))
  end
damage_bathtub_standard_ddf(hspf::HypsometricProfile{DT}, wl::Real, hdd_area::Real, hdds_static::Vector{T}, hdds_dynamic::Array{Any}) where {DT<:Real,T<:Real} =
  if (hdds_dynamic == [])
    damage_bathtub_standard_ddf(hspf, convert(DT, wl), convert(DT, hdd_area), convert(Array{DT}, hdds_static), convert(Array{DT}, hdds_dynamic))
  else
    damage_bathtub_standard_ddf(hspf, convert(DT, wl), convert(DT, hdd_area), convert(Array{DT}, hdds_static), Matrix{DT}(undef, 0, 0))
  end

damage_bathtub_standard_ddf(hspf::HypsometricProfile{DT}, wl::T1, hdd::T2, s::Symbol) where {DT<:Real,T1<:Real,T2<:Real} = damage_bathtub_standard_ddf(hspf, convert(DT, wl), convert(DT, hdd), s)


# @inline
function partial_damage_bathtub_standard_ddf(hspf::HypsometricProfile{DT}, wl::DT,
  hdd_area::DT, hdds_static::Array{DT}, hdds_dynamic::Array{DT},
  sl::DT, wl_low::DT, wl_high::DT,
  Δ_area::DT, Δ_exp_st::Array{DT}, Δ_exp_dy::Array{DT},
  ρ_area::DT, ρ_exp_st::Array{DT}, ρ_exp_dy::Array{DT}) where {DT<:Real}

  Δ_elevation1 = wl - wl_high
  Δ_elevation2 = wl - wl_low
  Δ_elevation3 = wl_high - wl_low
  factor_area = (hdd_area > 0) ? hdd_area * log((hdd_area + Δ_elevation1) / (hdd_area + Δ_elevation2)) + Δ_elevation3 : sl / ρ_area * Δ_area
  factor_static = map(h -> (h * log((h + Δ_elevation1) / (h + Δ_elevation2)) + Δ_elevation3), hdds_static)
  factor_dynamic = map(h -> (h * log((h + Δ_elevation1) / (h + Δ_elevation2)) + Δ_elevation3), hdds_dynamic)

  # catch all evil cases
  for fsi in eachindex(factor_static)
    factor_static[fsi] = isnan(factor_static[fsi]) ? (ρ_exp_st[fsi] != 0 ? sl / ρ_exp_st[fsi] * Δ_exp_st[fsi] : 0) : factor_static[fsi]
  end
  for fdi in eachindex(factor_dynamic)
    factor_dynamic[fdi] = isnan(factor_dynamic[fdi]) ? ((ρ_exp_dy[fdi] != 0) ? sl / ρ_exp_dy[fdi] * Δ_exp_dy[fdi] : 0) : factor_dynamic[fdi]
  end

  return (factor_area * ρ_area / sl, factor_static .* ρ_exp_st / sl, factor_dynamic .* ρ_exp_dy / sl)
end


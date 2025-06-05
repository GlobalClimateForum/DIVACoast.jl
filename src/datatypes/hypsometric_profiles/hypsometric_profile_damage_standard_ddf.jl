using QuadGK

# special case ddf = d/(d+hdd)
"""
"""
function damage_bathtub_standard_ddf(hspf::HypsometricProfile{DT}, wl::DT, hdd_area::DT, hdds_other::Array{DT}) :: Tuple{DT, Vector{DT}} where {DT<:Real}
  dam = exposure(hspf, wl)
  if complete_zero(dam) return dam end

  dam = exposure(hspf, first(hspf.elevation))
  dam_area = dam[1]
  dam_other = dam[2]

  if hspf.width > 0
    for ind in 1:size(hspf.elevation, 1)-1
      if hspf.elevation[ind] > wl
        return (dam_area, dam_other)
      else
        sl = slope(hspf, ind + 1)
        wl_low = hspf.elevation[ind]
        wl_high = (hspf.elevation[ind+1] <= wl) ? hspf.elevation[ind+1] : wl

        Δ_area = (hspf.elevation[ind+1] <= wl) ? hspf.cummulativeArea[ind+1] - hspf.cummulativeArea[ind] : exposure(hspf, wl_high, :area) - hspf.cummulativeArea[ind]

        if (Δ_area != 0)
          Δ_exp_other = (hspf.elevation[ind+1] <= wl) ? (
            size(hspf.cummulativeExposure)[2] >= 1 ? hspf.cummulativeExposure[ind+1, :] - hspf.cummulativeExposure[ind, :] : Array{DT,2}(undef, 0, 0)
          ) : (
            size(hspf.cummulativeExposure)[2] >= 1 ? exposure(hspf, wl)[2] - hspf.cummulativeExposure[ind, :] : Array{DT,2}(undef, 0, 0)
          )

          ρ_area = hspf.width / 1000
          ρ_exp_other = (Δ_exp_other / (Δ_area / hspf.width)) / 1000
          dam_t = partial_damage_bathtub_standard_ddf(hspf, wl, hdd_area, hdds_other, sl, wl_low, wl_high, Δ_area, Δ_exp_st, Δ_exp_dy, ρ_area, ρ_exp_st, ρ_exp_dy)
          dam_area = dam_area + dam_t[1]
          dam_other = (size(dam_t[2], 1) > 0) ? dam_other + dam_t[2] : dam_other
        end
      end
    end
  end

  return (dam_area, dam_other)
end


function damage_bathtub_standard_ddf(hspf::HypsometricProfile{DT}, wl::DT, hdd::DT, s::Symbol)::DT where {DT<:Real}
  pos = get_position(hspf, s)
  if (pos == -1)
    return zero(DT)
  end

  dam = exposure(hspf, first(hspf.elevation), s)
  my_exposure = zeros(DT, size(hspf.elevation, 1))
  
  if (pos == 0)
    my_exposure = hspf.cummulativeArea
  else
    my_exposure = hspf.cummulativeExposure[:, pos]
  end


  if hspf.width > 0
    for ind in 1:size(hspf.elevation, 1)-1
     if hspf.elevation[ind] > wl
        return dam
      else
        sl = slope(hspf, ind + 1)
        wl_low = hspf.elevation[ind]
        wl_high = (hspf.elevation[ind+1] <= wl) ? hspf.elevation[ind+1] : wl

        Δ_exp = (hspf.elevation[ind+1] <= wl) ? my_exposure[ind+1] - my_exposure[ind] : exposure(hspf, wl_high, s) - my_exposure[ind]
        Δ_area = (hspf.elevation[ind+1] <= wl) ? hspf.cummulativeArea[ind+1] - hspf.cummulativeArea[ind] : exposure(hspf, wl_high, :area) - hspf.cummulativeArea[ind]

        if (Δ_area != 0 && Δ_exp != 0 && sl != 0)
          ρ_exp = (Δ_exp / (Δ_area / hspf.width)) / 1000
          Δ_elevation1 = wl - wl_high
          Δ_elevation2 = wl - wl_low
          Δ_elevation3 = wl_high - wl_low
          factor = (hdd > 0) ? hdd * log((hdd + Δ_elevation1) / (hdd + Δ_elevation2)) + Δ_elevation3 : ((ρ_exp > 0) ? sl / ρ_exp * Δ_exp : 0)
          dam += factor * ρ_exp / sl
        end
      end
    end
  end
  return dam
end


damage_bathtub_standard_ddf(hspf::HypsometricProfile{DT}, wl::Real, hdd_area::Real, hdds_other::Array{DT}) where {DT<:Real} = damage_bathtub_standard_ddf(hspf, convert(DT, wl), convert(DT, hdd_area), hdds_other)
damage_bathtub_standard_ddf(hspf::HypsometricProfile{DT}, wl::Real, hdd_area::Real, hdds_other::Array{T1}) where {DT<:Real,T1<:Real} = damage_bathtub_standard_ddf(hspf, convert(DT, wl), convert(DT, hdd_area), convert(Array{DT}, hdds_other))
damage_bathtub_standard_ddf(hspf::HypsometricProfile{DT}, wl::Real, hdd_area::Real, hdds_other::Vector{Any}) where {DT<:Real} =
  if (hdds_other == [])
    damage_bathtub_standard_ddf(hspf, convert(DT, wl), convert(DT, hdd_area), Matrix{DT}(undef, 0, 0))
  else
    damage_bathtub_standard_ddf(hspf, convert(DT, wl), convert(DT, hdd_area), convert(Array{DT}, hdds_other))
  end
damage_bathtub_standard_ddf(hspf::HypsometricProfile{DT}, wl::T1, hdd::T2, s::Symbol) where {DT<:Real,T1<:Real,T2<:Real} = damage_bathtub_standard_ddf(hspf, convert(DT, wl), convert(DT, hdd), s)


# @inline
function partial_damage_bathtub_standard_ddf(hspf::HypsometricProfile{DT}, wl::DT,
  hdd_area::DT, hdds_other::Array{DT},  sl::DT, wl_low::DT, wl_high::DT,
  Δ_area::DT, Δ_exp::Array{DT}, ρ_area::DT, ρ_exp::Array{DT}) where {DT<:Real}

  Δ_elevation1 = wl - wl_high
  Δ_elevation2 = wl - wl_low
  Δ_elevation3 = wl_high - wl_low
  factor_area = (hdd_area > 0) ? hdd_area * log((hdd_area + Δ_elevation1) / (hdd_area + Δ_elevation2)) + Δ_elevation3 : sl / ρ_area * Δ_area
  factor_other = map(h -> (h * log((h + Δ_elevation1) / (h + Δ_elevation2)) + Δ_elevation3), hdds_other)

  # catch all evil cases
  for fsi in eachindex(factor_other)
    factor_other[fsi] = isnan(factor_other[fsi]) ? (ρ_exp_st[fsi] != 0 ? sl / ρ_exp_st[fsi] * Δ_exp_st[fsi] : 0) : factor_other[fsi]
  end

  return (factor_area * ρ_area / sl, factor_other .* ρ_exp / sl)
end


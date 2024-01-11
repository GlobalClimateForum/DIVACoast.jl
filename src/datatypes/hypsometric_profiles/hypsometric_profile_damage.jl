### Damage
function damage(hspf::HypsometricProfile, wl::Real, protection::Real, hdds_static::Array{T1}, hdds_dynamic::Array{T2}) where {T1,T2<:Real}
  if (wl <= protection)
    return (hspf.cummulativeArea[1], hspf.cummulativeStaticExposure[1, :], hspf.cummulativeDynamicExposure[1, :])
  end

  ind::Int64 = searchsortedfirst(hspf.elevation, wl)
  @inbounds if (ind == 1)
    return (hspf.cummulativeArea[ind], hspf.cummulativeStaticExposure[ind, :], hspf.cummulativeDynamicExposure[ind, :])
  end

  @inbounds r = (DT)(wl - hspf.elevation[ind-1]) / (hspf.elevation[ind] - hspf.elevation[ind-1])

  for i in 1:(ind-1)
    dam = damage(hspf, i, i + 1, protection, hdds)
  end

  #  if (r==0)
  #  else
  #  end
end


function damage(hspf::HypsometricProfile{DT}, wl::DT, hdds_static::Array{DT}, hdds_dynamic::Array{DT}) where {DT<:Real}
  dam :: DT = exposure(hspf,first(elevation))

  for ind in 1:size(hspf.elevation)-1
     if hspf.elevation[ind]>wl 
      return dam
     else
      dam = dam + damage(hspf, i, i + 1, hdds_static, hdds_dynamic)
    end
  end

  ind::Int64 = searchsortedfirst(hspf.elevation, wl)
  @inbounds if (ind == 1)
    return (hspf.cummulativeArea[ind], hspf.cummulativeStaticExposure[ind, :], hspf.cummulativeDynamicExposure[ind, :])
  end

  @inbounds r = (DT)(wl - hspf.elevation[ind-1]) / (hspf.elevation[ind] - hspf.elevation[ind-1])

  for i in 1:(ind-1)
    dam = damage(hspf, i, i + 1, hdds_static, hdds_dynamic)
  end

  #  if (r==0)
  #  else
  #  end
end


function partial_damage(hspf::HypsometricProfile{DT}, wl::DT, i1 :: Integer, i2 :: Integer, hdds_static::Array{DT}, hdds_dynamic::Array{DT}) where {IT <:Integer, DT<:Real}
  delta_el = hspf.elevation[i2] - hspf.elevation[i1]
  factor_static = map(h -> (h * logg((h + wl - hspf.elevation[i2]) / (h + wl - hspf.elevation[i1])) + delta_el), hdd_static)
  factor_dynamic = map(h -> (h * logg((h + wl - hspf.elevation[i2]) / (h + wl - hspf.elevation[i1])) + delta_el), hdd_dynamic)

  part_exp = hspf.cummulativeStaticExposure[i2, :] - hspf.cummulativeStaticExposure[i1, :]
  # (10,20,3,8)
end
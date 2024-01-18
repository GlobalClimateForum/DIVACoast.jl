using QuadGK

function damage(hspf::HypsometricProfile{DT}, wl::DT, hdd_area::DT, hdds_static::Array{DT}, hdds_dynamic::Array{DT}) where {DT<:Real}
  dam = exposure(hspf, first(hspf.elevation))
  dam_area = dam[1]
  dam_static = dam[2]
  dam_dynamic = dam[3]

  for ind in 1:size(hspf.elevation, 1)-1
    if hspf.elevation[ind] > wl
      return (dam_area, dam_static, dam_dynamic)
    else
      if (hspf.elevation[ind+1] <= wl)
        #        println("case 1 $(hspf.elevation[ind+1]) $wl")
        dam_t = partial_damage(hspf, wl, ind, ind + 1, hdd_area, hdds_static, hdds_dynamic)
        dam_area = dam_area + dam_t[1]
        dam_static = dam_static + dam_t[2]
        dam_dynamic = dam_dynamic + dam_t[3]
      else
        if (hspf.elevation[ind] > wl)
          dam_t = partial_damage(hspf, wl, ind, hdd_area, hdds_static, hdds_dynamic)
          dam_area = dam_area + dam_t[1]
          dam_static = dam_static + dam_t[2]
          dam_dynamic = dam_dynamic + dam_t[3]
        end
      end
    end
  end

  return (dam_area, dam_static, dam_dynamic)
end

damage(hspf::HypsometricProfile{DT}, wl::Real, hdd_area::Real, hdds_static::Array{DT}, hdds_dynamic::Array{DT}) where {DT<:Real} = damage(hspf, convert(DT, wl), convert(DT, hdd_area), hdds_static, hdds_dynamic)
damage(hspf::HypsometricProfile{DT}, wl::Real, hdd_area::Real, hdds_static::Array{T1}, hdds_dynamic::Array{T2}) where {DT<:Real,T1<:Real,T2<:Real} = damage(hspf, convert(DT, wl), convert(DT, hdd_area), convert(Array{DT}, hdds_static), convert(Array{DT}, hdds_dynamic))


function damage(hspf::HypsometricProfile{DT}, wl::DT, ddf_area::Function, ddfs_static::Vector{Function}, ddfs_dynamic::Vector{Function}) where {DT<:Real}
  dam = exposure(hspf, first(hspf.elevation))
  dam_area = dam[1]
  dam_static = dam[2]
  dam_dynamic = dam[3]

  for ind in 1:size(hspf.elevation, 1)-1
    if hspf.elevation[ind] > wl
      return (dam_area, dam_static, dam_dynamic)
    else
      if (hspf.elevation[ind+1] <= wl)
        dam_t = partial_damage(hspf, wl, ind, ind + 1, ddf_area, ddfs_static, ddfs_dynamic)
        dam_area = dam_area + dam_t[1]
        dam_static = dam_static + dam_t[2]
        dam_dynamic = dam_dynamic + dam_t[3]
      else
        if (hspf.elevation[ind] > wl)
          dam_t = partial_damage(hspf, wl, ind, ddf_area, ddfs_static, ddfs_dynamic)
          dam_area = dam_area + dam_t[1]
          dam_static = dam_static + dam_t[2]
          dam_dynamic = dam_dynamic + dam_t[3]
        end
      end
    end
  end

  return (dam_area, dam_static, dam_dynamic)
end


# special case ddf = d/(d+hdd)
function partial_damage(hspf::HypsometricProfile{DT}, wl::DT, i1::Integer, i2::Integer, hdd_area::DT, hdds_static::Array{DT}, hdds_dynamic::Array{DT}) where {DT<:Real}
  # internal function for partial damage calculation
  # attention: only works for i1 < i2 and hspf.elevation[i2] <= wl -- this is not checked 
  sl = slope(hspf, i2)

  Δ_area = (hspf.cummulativeArea[i2] - hspf.cummulativeArea[i1])
  if Δ_area == 0
    return (convert(DT, 0), zeros(DT, size(hspf.staticExposureSymbols, 1)), zeros(DT, size(hspf.dynamicExposureSymbols, 1)))
  end

  Δ_exp_st = size(hspf.cummulativeStaticExposure)[2] >= 1 ? hspf.cummulativeStaticExposure[i2, :] - hspf.cummulativeStaticExposure[i1, :] : Array{DT,2}(undef, 0, 0)
  Δ_exp_dy = size(hspf.cummulativeDynamicExposure)[2] >= 1 ? hspf.cummulativeDynamicExposure[i2, :] - hspf.cummulativeDynamicExposure[i1, :] : Array{DT,2}(undef, 0, 0)
  ρ_area = hspf.width / 1000
  ρ_exp_st = (Δ_exp_st / (Δ_area / hspf.width)) / 1000
  ρ_exp_dy = (Δ_exp_dy / (Δ_area / hspf.width)) / 1000

  #  println("coastplain: $(ρ_exp_dy) $(sl)")
  return partial_damage(hspf, sl, hspf.elevation[i1], hspf.elevation[i2], wl, Δ_area, Δ_exp_st, Δ_exp_dy, ρ_area, ρ_exp_st, ρ_exp_dy, hdd_area, hdds_static, hdds_dynamic)
end

function partial_damage(hspf::HypsometricProfile{DT}, wl::DT, i1::Integer, hdd_area::DT, hdds_static::Array{DT}, hdds_dynamic::Array{DT}) where {DT<:Real}
  sl = slope(hspf, i1 + 1)

  exp_wl = exposure(hspf, wl)
  Δ_area = exp_wl[1] - hspf.cummulativeArea[i1]
  if Δ_area == 0
    return (convert(DT, 0), zeros(DT, size(hspf.staticExposureSymbols, 1)), zeros(DT, size(hspf.dynamicExposureSymbols, 1)))
  end

  Δ_exp_st = size(hspf.cummulativeStaticExposure)[2] >= 1 ? exp_wl[2] - hspf.cummulativeStaticExposure[i1, :] : Array{DT,2}(undef, 0, 0)
  Δ_exp_dy = size(hspf.cummulativeDynamicExposure)[2] >= 1 ? exp_wl[3] - hspf.cummulativeDynamicExposure[i1, :] : Array{DT,2}(undef, 0, 0)

  ρ_area = hspf.width / 1000
  ρ_exp_st = (Δ_exp_st / (Δ_area / hspf.width)) / 1000
  ρ_exp_dy = (Δ_exp_dy / (Δ_area / hspf.width)) / 1000

  #println("  partial_damage(hspf, $sl, $(hspf.elevation[i1]), $wl, $wl, $Δ_area, $Δ_exp_st, $Δ_exp_dy, $ρ_area, $ρ_exp_st, $ρ_exp_dy, $hdd_area, $hdds_static, $hdds_dynamic)")
  return partial_damage(hspf, sl, hspf.elevation[i1], wl, wl, Δ_area, Δ_exp_st, Δ_exp_dy, ρ_area, ρ_exp_st, ρ_exp_dy, hdd_area, hdds_static, hdds_dynamic)
end

# @inline
function partial_damage(hspf::HypsometricProfile{DT}, sl::DT, wl_low::DT, wl_high::DT, wl::DT,
  Δ_area::DT, Δ_exp_st::Array{DT}, Δ_exp_dy::Array{DT},
  ρ_area::DT, ρ_exp_st::Array{DT}, ρ_exp_dy::Array{DT},
  hdd_area::DT, hdds_static::Array{DT}, hdds_dynamic::Array{DT}) where {DT<:Real}

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


# General case
function partial_damage(hspf::HypsometricProfile{DT}, wl::DT, i1::Integer, i2::Integer, ddf_area::Function, ddfs_static::Vector{Function}, ddfs_dynamic::Vector{Function}) where {DT<:Real}
  # internal function for partial damage calculation
  # attention: only works for i1 < i2 and hspf.elevation[i2] <= wl -- this is not checked 
  sl = slope(hspf, i2)

  Δ_area = (hspf.cummulativeArea[i2] - hspf.cummulativeArea[i1])
  if Δ_area == 0
    return (0, zeros(size(hspf.staticExposureSymbols, 1)), zeros(size(hspf.dynamicExposureSymbols, 1)))
  end

  Δ_exp_st = size(hspf.cummulativeStaticExposure)[2] >= 1 ? hspf.cummulativeStaticExposure[i2, :] - hspf.cummulativeStaticExposure[i1, :] : Array{DT,2}(undef, 0, 0)
  Δ_exp_dy = size(hspf.cummulativeDynamicExposure)[2] >= 1 ? hspf.cummulativeDynamicExposure[i2, :] - hspf.cummulativeDynamicExposure[i1, :] : Array{DT,2}(undef, 0, 0)

  ρ_area = hspf.width / 1000
  ρ_exp_st = (Δ_exp_st / (Δ_area / hspf.width)) / 1000
  ρ_exp_dy = (Δ_exp_dy / (Δ_area / hspf.width)) / 1000

  return partial_damage(hspf, sl, hspf.elevation[i1], hspf.elevation[i2], wl, ρ_area, ρ_exp_st, ρ_exp_dy, ddf_area, ddfs_static, ddfs_dynamic)
end

function partial_damage(hspf::HypsometricProfile{DT}, wl::DT, i1::Integer, ddf_area::Function, ddfs_static::Vector{Function}, ddfs_dynamic::Vector{Function}) where {DT<:Real}
  sl = slope(hspf, i1 + 1)

  exp_wl = exposure(hspf, wl)
  Δ_area = exp_wl[1] - hspf.cummulativeArea[i1]
  if Δ_area == 0
    return (0, zeros(size(hspf.staticExposureSymbols, 1)), zeros(size(hspf.dynamicExposureSymbols, 1)))
  end

  Δ_exp_st = size(hspf.cummulativeStaticExposure)[2] >= 1 ? exp_wl[2] - hspf.cummulativeStaticExposure[i1, :] : Array{DT,2}(undef, 0, 0)
  Δ_exp_dy = size(hspf.cummulativeDynamicExposure)[2] >= 1 ? exp_wl[3] - hspf.cummulativeDynamicExposure[i1, :] : Array{DT,2}(undef, 0, 0)

  ρ_area = hspf.width / 1000
  ρ_exp_st = (Δ_exp_st / (Δ_area / hspf.width)) / 1000
  ρ_exp_dy = (Δ_exp_dy / (Δ_area / hspf.width)) / 1000

  return partial_damage(hspf, sl, hspf.elevation[i1], wl, wl, ρ_area, ρ_exp_st, ρ_exp_dy, ddf_area, ddfs_static, ddfs_dynamic)
end

# @inline
function partial_damage(hspf::HypsometricProfile{DT}, sl::DT, wl_low::DT, wl_high::DT, wl::DT,
  ρ_area::DT, ρ_exp_st::Array{DT}, ρ_exp_dy::Array{DT},
  ddf_area::Function, ddfs_static::Vector{Function}, ddfs_dynamic::Vector{Function}) where {DT<:Real}

  factor_area = quadgk(x -> ddf_area(wl - x), wl_low, wl_high)[1]
  factor_static = size(hspf.cummulativeStaticExposure)[2] >= 1 ? map(f -> (quadgk(x -> f(wl - x), wl_low, wl_high))[1], ddfs_static) : Vector{DT}()
  factor_dynamic = size(hspf.cummulativeDynamicExposure)[2] >= 1 ? map(f -> (quadgk(x -> f(wl - x), wl_low, wl_high))[1], ddfs_dynamic) : Vector{DT}()

  return (factor_area * ρ_area / sl, factor_static .* ρ_exp_st / sl, factor_dynamic .* ρ_exp_dy / sl)
end

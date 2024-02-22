using QuadGK

# General case
function damage_bathtub(hspf::HypsometricProfile{DT}, wl::DT, ddf_area::Function, ddfs_static::Vector{Function}, ddfs_dynamic::Vector{Function}) where {DT<:Real}
  dam = exposure_below(hspf, first(hspf.elevation))
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

      Δ_area = (hspf.elevation[ind+1] <= wl) ? hspf.cummulativeArea[ind+1] - hspf.cummulativeArea[ind] : exposure_below(hspf, :area, wl_high) - hspf.cummulativeArea[ind]

      if (Δ_area != 0)
        Δ_exp_st = (hspf.elevation[ind+1] <= wl) ? (
          size(hspf.cummulativeStaticExposure)[2] >= 1 ? hspf.cummulativeStaticExposure[ind+1, :] - hspf.cummulativeStaticExposure[ind, :] : Array{DT,2}(undef, 0, 0)
        ) : (
          size(hspf.cummulativeStaticExposure)[2] >= 1 ? exposure_below(hspf, wl)[2] - hspf.cummulativeStaticExposure[ind, :] : Array{DT,2}(undef, 0, 0)
        )

        Δ_exp_dy = (hspf.elevation[ind+1] <= wl) ? (
          size(hspf.cummulativeDynamicExposure)[2] >= 1 ? hspf.cummulativeDynamicExposure[ind+1, :] - hspf.cummulativeDynamicExposure[ind, :] : Array{DT,2}(undef, 0, 0)
        ) : (
          size(hspf.cummulativeDynamicExposure)[2] >= 1 ? exposure_below(hspf, wl)[3] - hspf.cummulativeDynamicExposure[ind, :] : Array{DT,2}(undef, 0, 0)
        )
        ρ_area = hspf.width / 1000
        ρ_exp_st = (Δ_exp_st / (Δ_area / hspf.width)) / 1000
        ρ_exp_dy = (Δ_exp_dy / (Δ_area / hspf.width)) / 1000

        dam_t = partial_damage_bathtub(hspf, wl, ddf_area, ddfs_static, ddfs_dynamic, sl, wl_low, wl_high, ρ_area, ρ_exp_st, ρ_exp_dy)
        dam_area = dam_area + dam_t[1]
        dam_static = (size(dam_t[2], 1) > 0) ? dam_static + dam_t[2] : dam_static
        dam_dynamic = (size(dam_t[3], 1) > 0) ? dam_dynamic + dam_t[3] : dam_dynamic
      end
    end
  end

  return (dam_area, dam_static, dam_dynamic)
end


function damage_bathtub(hspf::HypsometricProfile{DT}, s::Symbol, wl::DT, ddf::Function)::DT where {DT<:Real}
  pos = get_position(hspf, s)
  if (pos[1] == -1)
    return zero(DT)
  end

  dam = exposure_below(hspf, s, first(hspf.elevation))
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

      Δ_exp = (hspf.elevation[ind+1] <= wl) ? exposure[ind+1] - exposure[ind] : exposure_below(hspf, s, wl_high) - exposure[ind]
      Δ_area = (hspf.elevation[ind+1] <= wl) ? hspf.cummulativeArea[ind+1] - hspf.cummulativeArea[ind] : exposure_below(hspf, :area, wl_high) - hspf.cummulativeArea[ind]

      if Δ_area != 0
        ρ_exp = (Δ_exp / (Δ_area / hspf.width)) / 1000
        Δ_elevation1 = wl - wl_high
        Δ_elevation2 = wl - wl_low
        Δ_elevation3 = wl_high - wl_low
        factor = quadgk(x -> ddf(wl - x), wl_low, wl_high, rtol=1e-5)[1]
        dam += factor * ρ_exp / sl
      end
    end
  end
  return dam
end


damage_bathtub(hspf::HypsometricProfile{DT}, wl::Real, ddf_area::Function, ddfs_static::Vector{Function}, ddfs_dynamic::Vector{Function}) where {DT<:Real} = damage(hspf, convert(DT, wl), ddf_area, ddfs_static, ddfs_dynamic)
damage_bathtub(hspf::HypsometricProfile{DT}, wl::Real, ddf_area::Function, ddfs_static::Vector{Any}, ddfs_dynamic::Vector{Function}) where {DT<:Real} =
  if (ddfs_static == [])
    damage_bathtub(hspf, convert(DT, wl), ddf_area, Vector{Function}(undef, 0), ddfs_dynamic)
  else
    damage_bathtub(hspf, convert(DT, wl), ddf_area, convert(Vector{Function}, ddfs_static), ddfs_dynamic)
  end
damage_bathtub(hspf::HypsometricProfile{DT}, wl::Real, ddf_area::Function, ddfs_static::Vector{Function}, ddfs_dynamic::Vector{Any}) where {DT<:Real} =
  if (ddfs_dynamic == [])
    damage_bathtub(hspf, convert(DT, wl), ddf_area, ddfs_static, Vector{Function}(undef, 0))
  else
    damage_bathtub(hspf, convert(DT, wl), ddf_area, ddfs_static, convert(Vector{Function}, ddfs_dynamic))
  end
damage_bathtub(hspf::HypsometricProfile{DT}, wl::Real, ddf_area::Function, ddfs_static::Vector{Any}, ddfs_dynamic::Vector{Any}) where {DT<:Real} =
  if (ddfs_static == [] && ddfs_dynamic == [])
    damage_bathtub(hspf, convert(DT, wl), ddf_area, Vector{Function}(undef, 0), Vector{Function}(undef, 0))
  elseif (ddfs_static == [])
    damage_bathtub(hspf, convert(DT, wl), ddf_area, Vector{Function}(undef, 0), convert(Vector{Function}, ddfs_dynamic))
  elseif (ddfs_dynamic == [])
    damage_bathtub(hspf, convert(DT, wl), ddf_area, convert(Vector{Function}, ddfs_static), Vector{Function}(undef, 0))
  else
    damage_bathtub(hspf, convert(DT, wl), ddf_area, convert(Vector{Function}, ddfs_static), convert(Vector{Function}, ddfs_dynamic))
  end

 damage_bathtub(hspf::HypsometricProfile{DT}, s::Symbol, wl::T, ddf::Function) where {DT<:Real,T<:Real} = damage_bathtub(hspf, s, convert(DT, wl), ddf)


# @inline
function partial_damage_bathtub(hspf::HypsometricProfile{DT}, wl::DT,
  ddf_area::Function, ddfs_static::Vector{Function}, ddfs_dynamic::Vector{Function},
  sl::DT, wl_low::DT, wl_high::DT,
  ρ_area::DT, ρ_exp_st::Array{DT}, ρ_exp_dy::Array{DT}) where {DT<:Real}

  factor_area = quadgk(x -> ddf_area(wl - x), wl_low, wl_high, rtol=1e-5)[1]
  factor_static = size(hspf.cummulativeStaticExposure)[2] >= 1 ? map(f -> (quadgk(x -> f(wl - x), wl_low, wl_high, rtol=1e-5))[1], ddfs_static) : Vector{DT}()
  factor_dynamic = size(hspf.cummulativeDynamicExposure)[2] >= 1 ? map(f -> (quadgk(x -> f(wl - x), wl_low, wl_high, rtol=1e-5))[1], ddfs_dynamic) : Vector{DT}()

  return (factor_area * ρ_area / sl, factor_static .* ρ_exp_st / sl, factor_dynamic .* ρ_exp_dy / sl)
end

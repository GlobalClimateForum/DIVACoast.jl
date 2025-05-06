using QuadGK

# General case
"""
    damage_bathtub(hspf::HypsometricProfile{DT}, wl::DT, ddf_area::Function, ddfs_other::Vector{Function}) where {DT<:Real}
    damage_bathtub(hspf::HypsometricProfile{DT}, wl::DT, ddf_area::Function, ddfs_other::Vector{Any}) where {DT<:Real}
    damage_bathtub(hspf::HypsometricProfile{DT}, wl::T, ddf::Function, s::Symbol) where {DT<:Real,T<:Real}

Calculates the damage using the bathtub model for a given water level wl based on a provided damage function ddf_area and additional damage functions ddfs_other.

# Arguments
- `hspf::HypsometricProfile{DT}`: The hypsometric profile.
- `wl::DT`: The water level for which the damage is calculated.
- `ddf_area::Function`: The damage function for the area.
- `ddfs_other::Vector{Function}`: Additional damage functions for other exposures.

# Example
```julia
  damage = damage_bathtub(hspf, 1.5, (x) -> x^2, [(x) -> x, (x) -> x^3])
```
"""
function damage_bathtub(hspf::HypsometricProfile{DT}, wl::DT, ddf_area::Function, ddfs_other::Vector{Function}) where {DT<:Real}
  dam = exposure_below(hspf, wl)
  if complete_zero(dam) return dam end

  dam = exposure_below(hspf, first(hspf.elevation))
  dam_area = dam[1]
  dam_others = dam[2]

  if hspf.width > 0
    for ind in 1:size(hspf.elevation, 1)-1
      if hspf.elevation[ind] > wl
        return (dam_area, dam_others, dam_dynamic)
      else
        sl = slope(hspf, ind + 1)
        wl_low = hspf.elevation[ind]
        wl_high = (hspf.elevation[ind+1] <= wl) ? hspf.elevation[ind+1] : wl

        Δ_area = (hspf.elevation[ind+1] <= wl) ? hspf.cummulativeArea[ind+1] - hspf.cummulativeArea[ind] : exposure_below(hspf, wl_high, :area) - hspf.cummulativeArea[ind]

        if (Δ_area != 0)
          Δ_exp = (hspf.elevation[ind+1] <= wl) ? (
            size(hspf.cummulativeExposure)[2] >= 1 ? hspf.cummulativeExposure[ind+1, :] - hspf.cummulativeExposure[ind, :] : Array{DT,2}(undef, 0, 0)
          ) : (
            size(hspf.cummulativeExposure)[2] >= 1 ? exposure_below(hspf, wl)[2] - hspf.cummulativeExposure[ind, :] : Array{DT,2}(undef, 0, 0)
          )

          ρ_area = hspf.width / 1000
          ρ_exp_st = (Δ_exp_st / (Δ_area / hspf.width)) / 1000

          dam_t = partial_damage_bathtub(hspf, wl, ddf_area, ddfs_other, sl, wl_low, wl_high, ρ_area, ρ_exp_st, ρ_exp_dy)
          dam_area = dam_area + dam_t[1]
          dam_others = (size(dam_t[2], 1) > 0) ? dam_others + dam_t[2] : dam_others
        end
      end
    end
  end

  return (dam_area, dam_others, dam_dynamic)
end


function damage_bathtub(hspf::HypsometricProfile{DT}, wl::DT, ddf::Function, s::Symbol)::DT where {DT<:Real}
  pos = get_position(hspf, s)
  if (pos[1] == -1)
    return zero(DT)
  end

  dam = exposure_below(hspf, first(hspf.elevation), s)
  exposure = zeros(DT, size(hspf.elevation, 1))
  if (pos[1] == 1)
    exposure = hspf.cummulativeArea
  end
  if (pos[1] == 2)
    exposure = hspf.cummulativeExposure[:, pos[2]]
  end

  if hspf.width > 0
    for ind in 1:size(hspf.elevation, 1)-1
      if hspf.elevation[ind] > wl
        return dam
      else
        sl = slope(hspf, ind + 1)
        wl_low = hspf.elevation[ind]
        wl_high = (hspf.elevation[ind+1] <= wl) ? hspf.elevation[ind+1] : wl

        Δ_exp = (hspf.elevation[ind+1] <= wl) ? exposure[ind+1] - exposure[ind] : exposure_below(hspf, wl_high, s) - exposure[ind]
        Δ_area = (hspf.elevation[ind+1] <= wl) ? hspf.cummulativeArea[ind+1] - hspf.cummulativeArea[ind] : exposure_below(hspf, wl_high, :area) - hspf.cummulativeArea[ind]

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
  end
  return dam
end


damage_bathtub(hspf::HypsometricProfile{DT}, wl::Real, ddf_area::Function, ddfs_other::Vector{Function}) where {DT<:Real} = damage(hspf, convert(DT, wl), ddf_area, ddfs_other)
damage_bathtub(hspf::HypsometricProfile{DT}, wl::Real, ddf_area::Function, ddfs_other::Vector{Any}) where {DT<:Real} =
  if (ddfs_other == [])
    damage_bathtub(hspf, convert(DT, wl), ddf_area, Vector{Function}(undef, 0))
  else
    damage_bathtub(hspf, convert(DT, wl), ddf_area, convert(Vector{Function}, ddfs_other))
  end

damage_bathtub(hspf::HypsometricProfile{DT}, wl::T, ddf::Function, s::Symbol) where {DT<:Real,T<:Real} = damage_bathtub(hspf, s, convert(DT, wl), ddf)


# @inline
function partial_damage_bathtub(hspf::HypsometricProfile{DT}, wl::DT,
  ddf_area::Function, ddfs_other::Vector{Function},
  sl::DT, wl_low::DT, wl_high::DT,
  ρ_area::DT, ρ_exp_other::Array{DT}) where {DT<:Real}

  factor_area = quadgk(x -> ddf_area(wl - x), wl_low, wl_high, rtol=1e-5)[1]
  factor_other = size(hspf.cummulativeExposure)[2] >= 1 ? map(f -> (quadgk(x -> f(wl - x), wl_low, wl_high, rtol=1e-5))[1], ddfs_other) : Vector{DT}()

  return (factor_area * ρ_area / sl, factor_other .* ρ_exp_other / sl)
end

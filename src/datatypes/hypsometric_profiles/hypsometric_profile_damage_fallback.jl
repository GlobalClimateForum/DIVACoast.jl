
function damage(hspf::HypsometricProfile{DT}, wl::DT, s::Array{String}, ddfs::Vector{Function}, im::IM = BathtubInundation()) where {DT<:Real, IM<:InundationModel}
  dam = exposure(hspf, wl, s, im)
  if complete_zero(dam) return dam end

  dam = exposure(hspf, first(hspf.elevation), s, im)

  if hspf.width > 0
    for ind in 1:size(hspf.elevation, 1)-1
      if hspf.elevation[ind] > wl
        return (dam)
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

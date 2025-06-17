
function damage(hspf::HypsometricProfile{DT}, wl::Real, s::Array{String}, ddfs::Vector{Function}, im::IM=BathtubInundation()) where {DT<:Real,IM<:InundationModel}
  # test: size(s,1) = size(ddfs,1)
  inds = map(x -> get_position(hspf, x), s)
  dam = exposure(hspf, wl, inds, im)
  if complete_zero(dam)
    return dam
  end

  dam = exposure(hspf, first(hspf.elevation), inds, im)
  water_levels = inundate(hspf, wl, im)
  max_water_level = last(water_levels[2])

  if hspf.width > 0
    for ind in 1:size(water_levels[1], 1)-1
      #println("ind: ",ind)
      sl = slope(hspf, ind + 1)
      wl_low = water_levels[2][ind]
      wl_high = water_levels[2][ind+1]
      el_low = water_levels[1][ind]
      el_high = water_levels[1][ind+1]
      exposure_low_area = exposure(hspf, el_low, :area)
      exposure_high_area = exposure(hspf, el_high, :area)
      exposure_low = exposure(hspf, el_low, inds)
      exposure_high = exposure(hspf, el_high, inds)

      Δ_area = exposure_high_area - exposure_low_area
      if (Δ_area != 0)
        Δ_exp = exposure_high - exposure_low
        ρ_area = hspf.width / 1000
        ρ_exp = (Δ_exp / (Δ_area / hspf.width)) / 1000

        dam_t = partial_damage(hspf, ddfs, el_low, el_high, wl, wl_low, wl_high, sl, ρ_area, ρ_exp, im)
        dam += dam_t
      end
      dam
    end
  end

  return (dam)
end

function partial_damage(hspf::HypsometricProfile{DT}, ddfs::Vector{Function},
  el_low::DT, el_high::DT, wl::Real, wl_low::DT, wl_high::DT, sl::DT, ρ_area::DT, ρ_exp::Array{DT}, im::IM) where {DT<:Real,IM<:BathtubInundation}
  factors = map(f -> (quadgk(d -> f(d), wl_high - el_high, wl_low - el_low, rtol=1e-4))[1], ddfs)
  return (factors .* (ρ_exp / sl))
end

function partial_damage(hspf::HypsometricProfile{DT}, ddfs::Vector{Function},
  el_low::DT, el_high::DT, wl::Real, wl_low::DT, wl_high::DT, sl::DT, ρ_area::DT, ρ_exp::Array{DT}, im::IM) where {DT<:Real,IM<:InundationModel}
  factors = map(f -> (quadgk(el -> f(water_depth(hspf,wl,el,im)), el_low, el_high, rtol=1e-4))[1], ddfs)
  return (factors .* (ρ_exp / sl))
end
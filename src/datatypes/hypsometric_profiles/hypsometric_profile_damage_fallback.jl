"""
    damage(hspf::HypsometricProfile{DT}, wl::Real, s::Array{String}, ddfs::Vector{Function}, im::IM=BathtubInundation()) where {DT<:Real,IM<:InundationModel}

Calculates the flood damage for a given water level wl based on provided damage functions ddfs for all exposure variables in s.
The default inundation model is the bathtub model, if not specified.

# Arguments
- `hspf::HypsometricProfile{DT}`: The hypsometric profile.
- `wl::Real`: The water level for which the damage is calculated.
- `s::Array{String}`: An array of exposure variable names for which the damage is calculated. If only one variable is needed, it has to be a single string/symbol.
- `ddfs::Vector{Function}`: A vector of damage functions corresponding to the exposure variables in s. StandardDDF(h) can be used for a standard depth-damage function $ f(d)= \frac{d}{d+h}$ .
- `im::IM`: The inundation model to be used, default is BathtubInundation().


# Example
```julia
  damage(hspf, 2.0, ["assets"], [d -> d/(d+1)])
  damage(hspf, 2.0, ["population","assets"], [d -> 1, d -> d/(d+1)])
  damage(hspf, 2.0, [:population,:assets], [StandardDDF(0.0), StandardDDF(1.0)])
```
"""
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

        dam_t = partial_damage(hspf, ddfs, el_low, el_high, wl_low, wl_high, sl, ρ_area, ρ_exp)
        dam += dam_t
      end
      dam
    end
  end

  return (dam)
end

function partial_damage(hspf::HypsometricProfile{DT}, ddfs::Vector{Function},
  el_low::DT, el_high::DT, wl_low::DT, wl_high::DT, sl::DT, ρ_area::DT, ρ_exp::Array{DT}) where {DT<:Real}

  factors = map(f -> (quadgk(d -> f(d), wl_high - el_high, wl_low - el_low, rtol=1e-4))[1], ddfs)
  return (factors .* (ρ_exp / sl))
end

"""
    damage(hspf::HypsometricProfile{DT}, wl::Real, s::Array{}, ddfs::Vector{Function}, im::IM=BathtubInundation()) where {DT<:Real,IM<:InundationModel}
    ...

Calculates the flood damage for a given water level wl based on provided damage functions ddfs for all exposure variables in s.
The default inundation model (if not specified otherwise) is bathtub inundation.

# Arguments
- `hspf::HypsometricProfile{DT}`: The hypsometric profile.
- `wl::Real`: The water level for which the damage is calculated.
- `s::String or s::Symbol or s::Array{String} or Array{Symbol}`: An array of exposure variable names for which the damage is calculated. If only one variable is used please use the version with a single variable instaed of an array (the latter one might cause problems then).
- `ddfs::Vector{Function}`: A vector of damage functions corresponding to the exposure variables in s. 
  StandardDDF(h) can be used for a standard depth-damage function 
`f(d)= d/(d+h)`
- `im::IM`: The inundation model to be used, default is BathtubInundation().


# Example
```julia
  damage(hspf, 2.0, "assets", d -> d/(d+1))   # returns a number
  damage(hspf, 4.5, ["population","assets"], [d -> 1, d -> d/(d+1)])    # returns a 2-elment Array
  damage(hspf, 4.5, [:population,:assets], [StandardDDF(0.0), StandardDDF(1.0)])    # returns a 2-elment Array
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
  el_low::DT, el_high::DT, wl::Real, wl_low::DT, wl_high::DT, sl::DT, ρ_area::DT, ρ_exp::Array{DT}, im::BathtubInundation) where {DT<:Real}
  factors = map(f -> (quadgk(d -> f(d), wl_high - el_high, wl_low - el_low, rtol=1e-4))[1], ddfs)
  return (factors .* (ρ_exp / sl))
end

function partial_damage(hspf::HypsometricProfile{DT}, ddfs::Vector{Function},
  el_low::DT, el_high::DT, wl::Real, wl_low::DT, wl_high::DT, sl::DT, ρ_area::DT, ρ_exp::Array{DT}, im::LinearDistanceAttenuatedInundation) where {DT<:Real}
  factors = map(f -> (quadgk(d -> f(d), wl_high - el_high, wl_low - el_low, rtol=1e-4))[1], ddfs)
  return (factors .* (ρ_exp / (sl+(im.attenuation_rate/1000))))
end

function partial_damage(hspf::HypsometricProfile{DT}, ddfs::Vector{Function},
  el_low::DT, el_high::DT, wl::Real, wl_low::DT, wl_high::DT, sl::DT, ρ_area::DT, ρ_exp::Array{DT}, im::IM) where {DT<:Real,IM<:InundationModel}
  factors = map(f -> (quadgk(el -> f(water_depth(hspf,wl,el,im)), el_low, el_high, rtol=1e-4))[1], ddfs)
  return (factors .* (ρ_exp / sl))
end
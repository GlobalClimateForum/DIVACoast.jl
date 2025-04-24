"""
    exposure(hspf::HypsometricProfile{DT}, wl::Real, im::IM) where {DT<:Real, IM<:InundationModel}

Calculate the cumulative area, static exposure, and dynamic exposure below elevation (`e`) for a hypsometric profile. The function handles different cases based on the elevation's presence in the profile and its position.
# Arguments
`hspf::HypsometricProfile{DT}`: The hypsometric profile with elevation, area and exposure data.
`e::Real`: The elevation threshold for which exposure is calculated (everything underneath this elevation).
`im::IM`: the inundationmodel used to .


# Returns
Exposed area and exposure for elevations smaller than `e`.

"""
function exposure(hspf::HypsometricProfile{DT}, wl::Number, im::IM = BathtubInundation()) where {DT<:Real, IM<:InundationModel}
  water_levels = inundate(hspf, wl, im)

  #println(water_levels)
  max_water_level = last(water_levels[2])
  ind::Int64 = searchsortedfirst(hspf.elevation, max_water_level)

  if (max_water_level in hspf.elevation)
    @inbounds ea = hspf.cummulativeArea[ind]
    @inbounds eo = (size(hspf.cummulativeExposure, 1) > 0) ? hspf.cummulativeExposure[ind, :] : Array{DT}(undef, 0)
    return (ea, eo)
  else
    if (ind == 1)
      @inbounds ea = hspf.cummulativeArea[ind]
      @inbounds eo = (size(hspf.cummulativeExposure, 1) > 0) ? hspf.cummulativeExposure[ind, :] : Array{DT}(undef, 0)
      return (ea, eo)
    end
    if (ind > size(hspf.elevation, 1))
      @inbounds ea = hspf.cummulativeArea[size(hspf.elevation, 1)]
      @inbounds eo = (size(hspf.cummulativeExposure, 1) > 0) ? hspf.cummulativeExposure[size(hspf.elevation, 1), :] : Array{DT}(undef, 0)
      return (ea, eo)
    end
    @inbounds r = (max_water_level - hspf.elevation[ind-1]) / (hspf.elevation[ind] - hspf.elevation[ind-1])
    @inbounds ea = convert(DT,hspf.cummulativeArea[ind-1] + ((hspf.cummulativeArea[ind] - hspf.cummulativeArea[ind-1]) * r))
    @inbounds eo = convert(Array{DT},(size(hspf.cummulativeExposure, 1) > 0) ? hspf.cummulativeExposure[ind-1, :] + ((hspf.cummulativeExposure[ind, :] - hspf.cummulativeExposure[ind-1, :]) * r) : Array{DT}(undef, 0))
    return (ea, eo)
  end

end

function exposure(hspf::HypsometricProfile{DT}, wl::Real, s::Symbol, im::IM = BathtubInundation()) where {DT<:Real, IM<:InundationModel}
  p = get_position(hspf, s)
  exposure = zeros(DT, size(hspf.elevation,1))
  if (p[1]==1)
    exposure = hspf.cummulativeArea
  end
  if (p[1]==2)
    exposure = hspf.cummulativeExposure[:, p[2]]
  end

  water_levels = inundate(hspf, wl, im)
  max_water_level = last(water_levels[2])
  ind::Int64 = searchsortedfirst(hspf.elevation, wl)

  if (wl in hspf.elevation)
    @inbounds e = exposure[ind]
    return e
  else
    if (ind == 1)
      @inbounds e = exposure[ind]
      return e
    end
    if (ind > size(hspf.elevation, 1))
      e = exposure[size(hspf.elevation, 1)]
      return e
    end
    @inbounds r = (wl - hspf.elevation[ind-1]) / (hspf.elevation[ind] - hspf.elevation[ind-1])
    @inbounds e = convert(DT,exposure[ind-1] + (exposure[ind] - exposure[ind-1]) * r)
    return e
  end

end

function exposure(hspf::HypsometricProfile{DT}, wl::Real, s::Array{Symbol}, im::IM = BathtubInundation()) where {DT<:Real, IM<:InundationModel}
  map(x -> exposure(hspf, x, wl, im), s)
end

exposure(hspf::HypsometricProfile{DT}, wl::Real, s::String, im::IM = BathtubInundation()) where {DT<:Real, IM<:InundationModel} = exposure(hspf, wl, Symbol(s), im)
exposure(hspf::HypsometricProfile{DT}, wl::Real, s::Array{String}, im::IM = BathtubInundation()) where {DT<:Real, IM<:InundationModel} = exposure(hspf, wl, map(x -> Symbol(x),s), im)


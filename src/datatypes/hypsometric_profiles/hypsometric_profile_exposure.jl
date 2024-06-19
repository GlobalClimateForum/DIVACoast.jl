"""
    exposure_below_bathtub(hspf::HypsometricProfile{DT}, e::Real) where {DT<:Real}

Calculate the cumulative area, static exposure, and dynamic exposure below elevation (`e`) for a hypsometric profile. The function handles different cases based on the elevation's presence in the profile and its position.
# Arguments
`hspf::HypsometricProfile{DT}`: The hypsometric profile with elevation, area and exposure data.
`e::Real`: The elevation threshold for which exposure is calculated (everything underneath this elevation).

# Returns
Exposed area, static and dynamic exposure for elevations smaller than `e`.

"""
function exposure_below_bathtub(hspf::HypsometricProfile{DT}, e::Real) where {DT<:Real}
  ind::Int64 = searchsortedfirst(hspf.elevation, e)
  if (e in hspf.elevation)
    @inbounds ea = hspf.cummulativeArea[ind]
    @inbounds es = (size(hspf.cummulativeStaticExposure, 1) > 0) ? hspf.cummulativeStaticExposure[ind, :] : Array{DT,2}(undef, 0, 0)
    @inbounds ed = (size(hspf.cummulativeDynamicExposure, 1) > 0) ? hspf.cummulativeDynamicExposure[ind, :] : Array{DT,2}(undef, 0, 0)
    return (ea, es, ed)
  else
    if (ind == 1)
      @inbounds ea = hspf.cummulativeArea[ind]
      @inbounds es = (size(hspf.cummulativeStaticExposure, 1) > 0) ? hspf.cummulativeStaticExposure[ind, :] : Array{DT,2}(undef, 0, 0)
      @inbounds ed = (size(hspf.cummulativeDynamicExposure, 1) > 0) ? hspf.cummulativeDynamicExposure[ind, :] : Array{DT,2}(undef, 0, 0)
      return (ea, es, ed)
    end
    if (ind > size(hspf.elevation, 1))
      @inbounds ea = hspf.cummulativeArea[size(hspf.elevation, 1)]
      @inbounds es = (size(hspf.cummulativeStaticExposure, 1) > 0) ? hspf.cummulativeStaticExposure[size(hspf.elevation, 1), :] : Array{DT,2}(undef, 0, 0)
      @inbounds ed = (size(hspf.cummulativeDynamicExposure, 1) > 0) ? hspf.cummulativeDynamicExposure[size(hspf.elevation, 1), :] : Array{DT,2}(undef, 0, 0)
      return (ea, es, ed)
    end
    @inbounds r = (e - hspf.elevation[ind-1]) / (hspf.elevation[ind] - hspf.elevation[ind-1])
    @inbounds ea = convert(DT,hspf.cummulativeArea[ind-1] + ((hspf.cummulativeArea[ind] - hspf.cummulativeArea[ind-1]) * r))
    @inbounds es = convert(Array{DT},(size(hspf.cummulativeStaticExposure, 1) > 0) ? hspf.cummulativeStaticExposure[ind-1, :] + ((hspf.cummulativeStaticExposure[ind, :] - hspf.cummulativeStaticExposure[ind-1, :]) * r) : Array{DT,2}(undef, 0, 0))
    @inbounds ed = convert(Array{DT},(size(hspf.cummulativeDynamicExposure, 1) > 0) ? hspf.cummulativeDynamicExposure[ind-1, :] + ((hspf.cummulativeDynamicExposure[ind, :] - hspf.cummulativeDynamicExposure[ind-1, :]) * r) : Array{DT,2}(undef, 0, 0))
    return (ea, es, ed)
  end
end

function exposure_below_bathtub(hspf::HypsometricProfile{DT}, e::Real, s::Symbol) where {DT<:Real}
  p = get_position(hspf, s)

  exposure = zeros(DT, size(hspf.elevation,1))
  if (p[1]==1)
    exposure = hspf.cummulativeArea
  end
  if (p[1]==2)
    exposure = hspf.cummulativeStaticExposure[:, p[2]]
  end
  if (p[1]==3)
    exposure = hspf.cummulativeDynamicExposure[:, p[2]] 
  end

  ind::Int64 = searchsortedfirst(hspf.elevation, e)
  if (e in hspf.elevation)
    return exposure[ind]
  else
    if (ind == 1)
      return convert(DT,exposure[ind])
    end
    if (ind > size(hspf.elevation, 1))
      return convert(DT,exposure[size(hspf.elevation, 1)])
    end
    @inbounds r = (e - hspf.elevation[ind-1]) / (hspf.elevation[ind] - hspf.elevation[ind-1])
    return convert(DT,exposure[ind-1] + ((exposure[ind] - exposure[ind-1]) * r))
  end
end

function exposure_below_bathtub(hspf::HypsometricProfile{DT}, e::Real, s::Array{Symbol}) where {DT<:Real}
  map(x -> exposure_below_bathtub(hspf, x, e), s)
end

function exposure_below_bathtub_named(hspf::HypsometricProfile, e::Real)
  ex = exposure_below_bathtub(hspf, e)
  @inbounds return (NamedTuple{Symbol("area")}(ex[1]), NamedTuple{hspf.staticExposureSymbols}(ex[2]), NamedTuple{hspf.dynamicExposureSymbols}(ex[3]))
end

"""
    exposure_below_attenuated(hspf::HypsometricProfile{DT}, e::Real, att_rates :: Array{<:Real}) where {DT<:Real}
    exposure_below_attenuated(hspf::HypsometricProfile{DT}, e::Real, att_rate :: Real) where {DT<:Real}

Calculate the cumulative area, static exposure, and dynamic exposure below elevation (`e`) for a hypsometric profile, taking into account attenuation.
# Arguments
`hspf::HypsometricProfile{DT}`: The hypsometric profile with elevation, area and exposure data.
`e::Real`: The elevation threshold for which exposure is calculated (everything underneath this elevation).
`att_rates` :: Array{<:Real}`: an array of attenuation rates, each given in m/km. A value of 0.3 stands for an attenuation of 0.3m per km of flood extend. 
`att_rate` :: Real`: an attenuation rate, given in m/km. 

If attenuation rates are given as array, the array dimension has to much the array dimension of the elevation array of hspf.

# Returns
Exposed area, static and dynamic exposure for elevations smaller than `e``, taking into account attenuation.


"""
exposure_below_attenuated(hspf::HypsometricProfile{DT}, e::Real, att_rates :: Array{<:Real}) where {DT<:Real} = exposure_below_bathtub(hspf, attenuate(hspf, e, att_rates))
exposure_below_attenuated(hspf::HypsometricProfile{DT}, e::Real, att_rate :: Real) where {DT<:Real} = exposure_below_attenuated(hspf, e, map(x->att_rate, hspf.elevation))
  
"""
    attenuate(hspf::HypsometricProfile{DT}, wl::Real, att_rates :: Array{<:Real}) where {DT<:Real}
    attenuate(hspf::HypsometricProfile{DT}, wl::Real, att_rate :: Real) where {DT<:Real}

Attenuate waterlevel wl for a hypsometric profile.
# Arguments
`hspf::HypsometricProfile{DT}`: The hypsometric profile with elevation, area and exposure data.
`wl::Real`: The elevation threshold for which exposure is calculated (everything underneath this elevation).
`att_rates` :: Array{<:Real}`: an array of attenuation rates, each given in m/km. A value of 0.3 stands for an attenuation of 0.3m per km of flood extend. 
`att_rate` :: Real`: an attenuation rate, given in m/km. 

If attenuation rates are given as array, the array dimension has to much the array dimension of the elevation array of hspf.

# Returns
The attenuated waterlevel.

"""
function attenuate(hspf::HypsometricProfile{DT}, wl::Real, att_rates :: Array{<:Real}) where {DT<:Real}
  if (size(hspf.elevation, 1)!= size(att_rates, 1)) 
    return wl
  end

  if (wl<=hspf.elevation[1]) return wl end

  wl_attenuated = 0
  ind = 2
  Δ_wl_att_part = (distance(hspf, hspf.elevation[ind]) - distance(hspf,hspf.elevation[ind-1])) * att_rates[ind]
  Δ_wl = (hspf.elevation[ind] - hspf.elevation[ind-1])

  while ((Δ_wl_att_part + Δ_wl <= wl) && (ind < size(hspf.elevation, 1)))
    wl = wl - (Δ_wl_att_part + Δ_wl)
    wl_attenuated += Δ_wl
    ind += 1 
    Δ_wl_att_part = (distance(hspf, hspf.elevation[ind]) - distance(hspf, hspf.elevation[ind-1])) * att_rates[ind]
    Δ_wl = (hspf.elevation[ind] - hspf.elevation[ind-1])
  end

  
  if (ind <= size(hspf.elevation, 1))
    Δ_wl_att_part = (distance(hspf, hspf.elevation[ind] + wl) - distance(hspf, hspf.elevation[ind])) * att_rates[ind]
    wl_attenuated += Δ_wl_att_part 
  end
  
  wl_attenuated
end

attenuate(hspf::HypsometricProfile{DT}, wl::Real, att_rate :: Real) where {DT<:Real} = attenuate(hspf, wl, map(x->att_rate, hspf.elevation))

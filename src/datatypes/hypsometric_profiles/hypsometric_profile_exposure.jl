function exposure_below(hspf::HypsometricProfile{DT}, e::Real) where {DT<:Real}
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
    @inbounds ea = hspf.cummulativeArea[ind-1] + ((hspf.cummulativeArea[ind] - hspf.cummulativeArea[ind-1]) * r)
    @inbounds es = (size(hspf.cummulativeStaticExposure, 1) > 0) ? hspf.cummulativeStaticExposure[ind-1, :] + ((hspf.cummulativeStaticExposure[ind, :] - hspf.cummulativeStaticExposure[ind-1, :]) * r) : Array{DT,2}(undef, 0, 0)
    @inbounds ed = (size(hspf.cummulativeDynamicExposure, 1) > 0) ? hspf.cummulativeDynamicExposure[ind-1, :] + ((hspf.cummulativeDynamicExposure[ind, :] - hspf.cummulativeDynamicExposure[ind-1, :]) * r) : Array{DT,2}(undef, 0, 0)
    return (ea, es, ed)
  end
end

function exposure_below_named(hspf::HypsometricProfile, e::Real)
  ex = exposure_below(hspf, e)
  @inbounds return (ex[1], NamedTuple{hspf.staticExposureSymbols}(ex[2]), NamedTuple{hspf.dynamicExposureSymbols}(ex[3]))
end



using Main.ExtendedLogging
using Logging


export exposure, sed, sed_above, sed_below, remove_below, add_above, add_between


mutable struct HypsometricProfileFixedArray
  width        :: Float32
  minElevation :: Float32
  maxElevation :: Float32
  delta        :: Float32
  elevation    :: Array{Float32}
  cummulativeArea             :: Array{Float32}
  cummulativeStaticExposure   :: Array{Float32,2}
  cummulativeDynamicExposure  :: Array{Float32,2}
  cummulativeStaticExposureNames  :: Array{String}
  cummulativeDynamicExposureNames :: Array{String}
  logger     :: ExtendedLogging.ExtendedLogger

  function HypsometricProfileFixedArray(w, elevations, areas,s_exposure, d_exposure, d_exposure_names, s_exposure_names, logger)
    if (length(elevations)!=size(d_exposure,2)) Main.ExtendedLogging.log(logger,Logging.Error,@__FILE__,"\n length(elevations) != size(d_exposure,2) as length($elevations) != size($d_exposure,2) as $(length(elevations)) != $(size(d_exposure,2))") end
    if (length(elevations)!=size(s_exposure,2)) Main.ExtendedLogging.log(logger,Logging.Error,@__FILE__,"\n length(elevations) != size(s_exposure,2) as length($elevations) != size($s_exposure,2) as $(length(elevations)) != $(size(s_exposure,2))") end

    if (length(elevations) < 2)  Main.ExtendedLogging.log(logger,Logging.Error,@__FILE__,"\n length(elevations) = length($elevations) = $(length(elevations)) < 2 which is not allowed") end

    delta = elevations[2] - elevations[1]
    for x in 2:(length(elevations)) 
      if ((elevations[x]-elevations[x-1])!=delta) Main.ExtendedLogging.log(logger,Logging.Error,@__FILE__,"\n unequal delta: elevations[$x]-elevations[$(x-1)] = $(elevations[x])-$(elevations[x-1]) = $(elevations[x]-elevations[x-1]) != $delta") end
    end

    if (!issorted(elevations)) Main.ExtendedLogging.log(logger,Logging.Error,@__FILE__,"\n elevations is not sorted: $elevations") end
    if (areas[1] != 0) Main.ExtendedLogging.log(logger,Logging.Error,@__FILE__,"\n area[1] should be zero, but its not: $areas") end
    if (s_exposure[:,1] != zeros(size(s_exposure,1))) Main.ExtendedLogging.log(logger,Logging.Error,@__FILE__,"\n s_exposure first column should be zero, but its not: $s_exposure") end
    if (d_exposure[:,1] != zeros(size(d_exposure,1))) Main.ExtendedLogging.log(logger,Logging.Error,@__FILE__,"\n d_exposure first column should be zero, but its not: $d_exposure") end

    new(w,elevations[1],elevations[length(elevations)], delta, elevations, cumsum(areas), cumsum(s_exposure,dims=2), cumsum(d_exposure,dims=2), s_exposure_names, d_exposure_names, logger)
  end

end


function exposure(hspf :: HypsometricProfileFixedArray, e) 
  if (e < hspf.minElevation) return (hspf.cummulativeArea[1], hspf.cummulativeStaticExposure[:, 1], hspf.cummulativeDynamicExposure[:, 1]) end
  if (e > hspf.maxElevation) return (hspf.cummulativeArea[length(hspf.cummulativeArea)], hspf.cummulativeStaticExposure[:, size(hspf.cummulativeStaticExposure,2)], hspf.cummulativeDynamicExposure[:, size(hspf.cummulativeDynamicExposure,2)]) end

  i = floor(Int, (e-hspf.minElevation) / hspf.delta) + 1
  @inbounds r = (Float32)(e - hspf.elevation[i]) / hspf.delta
  
  @inbounds return ( hspf.cummulativeArea[i] + (hspf.cummulativeArea[i+1] - hspf.cummulativeArea[i]*r),
                     hspf.cummulativeStaticExposure[:, i] + (hspf.cummulativeStaticExposure[:, i+1] - hspf.cummulativeStaticExposure[:, i]*r),
                     hspf.cummulativeDynamicExposure[:, i] + (hspf.cummulativeDynamicExposure[:, i+1] - hspf.cummulativeDynamicExposure[:, i]*r) )
end


function sed(hspf :: HypsometricProfileFixedArray, factors)
  if (size(hspf.cummulativeDynamicExposure,1)!=length(factors)) Main.ExtendedLogging.log(hspf.logger, Logging.Error,@__FILE__,"\n size(hspf.cummulativeDynamicExposure,1)!=length(factors) as size($hspf.cummulativeDynamicExposure,1)!=length($factors) as $(size(hspf.cummulativeDynamicExposure,1))!=$(length(factors))") end

  for i in 1:(size(hspf.cummulativeDynamicExposure,1))
    hspf.cummulativeDynamicExposure[i,:] *= factors[i]
  end
end 


function sed_above(hspf, above, factors)
  if (above < hspf.minElevation) 
    sed(hspf, factors) 
    return 
  end
  if (above > hspf.maxElevation) 
    return 
  end

  if (size(hspf.cummulativeDynamicExposure,1)!=length(factors)) Main.ExtendedLogging.log(hspf.logger, Logging.Error,@__FILE__,"\n size(hspf.cummulativeDynamicExposure,1)!=length(factors) as size($hspf.cummulativeDynamicExposure,1)!=length($factors) as $(size(hspf.cummulativeDynamicExposure,1))!=$(length(factors))") end

  s = floor(Int, (above-hspf.minElevation) / hspf.delta) + 2

  for i in s:(size(hspf.cummulativeDynamicExposure,2))
    for j in 1:(size(hspf.cummulativeDynamicExposure,1))
      hspf.cummulativeDynamicExposure[j,i] *= factors[j]
    end
  end
end 


function sed_below(hspf, below, factors)
  if (below < hspf.minElevation) 
    return 
  end
  if (below > hspf.maxElevation) 
    sed(hspf, popfactor, assetfactor) 
    return 
  end

  if (size(hspf.cummulativeDynamicExposure,1)!=length(factors)) Main.ExtendedLogging.log(hspf.logger, Logging.Error,@__FILE__,"\n size(hspf.cummulativeDynamicExposure,1)!=length(factors) as size($hspf.cummulativeDynamicExposure,1)!=length($factors) as $(size(hspf.cummulativeDynamicExposure,1))!=$(length(factors))") end

  s = floor(Int, (below-hspf.minElevation) / hspf.delta) + 1


  for i in 1:s
    for j in 1:(size(hspf.cummulativeDynamicExposure,1))
      hspf.cummulativeDynamicExposure[j,i] *= factors[j]
    end
  end

  for i in (s+1):(size(hspf.cummulativeDynamicExposure,2))
    for j in 1:(size(hspf.cummulativeDynamicExposure,1))
      hspf.cummulativeDynamicExposure[j,i] += (hspf.cummulativeDynamicExposure[j,s] - (hspf.cummulativeDynamicExposure[j,s] / factors[j]))
    end
  end
end 


function remove_below(hspf, below)
  if (below < hspf.minElevation) 
    return (hspf.cummulativeDynamicExposure[:, 1])
  end

  removed = hspf.cummulativeDynamicExposure[:, 1]

  if (below >= hspf.maxElevation) 
    removed = hspf.cummulativeDynamicExposure[:, size(hspf.cummulativeDynamicExposure,2)]

    for j in 1:(size(hspf.cummulativeDynamicExposure,1))
	hspf.cummulativeDynamicExposure = zeros(size(hspf.cummulativeDynamicExposure,1),size(hspf.cummulativeDynamicExposure,2))
    end
    return removed
  end

  s = floor(Int, (below-hspf.minElevation) / hspf.delta) 

  removed = hspf.cummulativeDynamicExposure[:, s]

  for i in 1:s
    for j in 1:(size(hspf.cummulativeDynamicExposure,1))
      hspf.cummulativeDynamicExposure[j,i] = 0f0
    end 
  end

  for i in (s+1):length(hspf.elevation)
    for j in 1:(size(hspf.cummulativeDynamicExposure,1))
      hspf.cummulativeDynamicExposure[j,i] -= removed[j]
    end
  end

  return (removed_pop,removed_assets)
end


function add_above(hspf, above, pop, assets)
  if (above > hspf.maxElevation) 
    return 
  end
 
  s = floor(Int, (above-hspf.minElevation) / hspf.delta) + 1
  if (s<2) s=2 end

  for i in s:(length(hspf.elevation))
    hspf.cummulativePopulation[i] += ((1+i-s) *  pop    / (1 + length(hspf.elevation) - s))
    hspf.cummulativeAssets[i]     += ((1+i-s) *  assets / (1 + length(hspf.elevation) - s))
  end  
end


function add_between(hspf, above, below, pop, assets)
  if (above > below) 
    return 
  end

  s1 = floor(Int, (above-hspf.minElevation) / hspf.delta) + 1
  if (s1<2) s1=2 end

  s2 = floor(Int, (below-hspf.minElevation) / hspf.delta) + 1
  if (s2>length(hspf.elevation)) 
    s2=length(hspf.elevation) 
  end
  if (s2<s1) 
    s2=s1 
  end

  for i in s1:s2
    hspf.cummulativePopulation[i] += ((1+i-s1) *  pop    / (1 + s2 - s1))
    hspf.cummulativeAssets[i]     += ((1+i-s1) *  assets / (1 + s2 - s1))
  end  

  for i in (s2+1):(length(hspf.elevation))
    hspf.cummulativePopulation[i] += pop 
    hspf.cummulativeAssets[i]     += assets
  end  

end


using Main.ExtendedLogging
using Logging


export exposure, sed, sed_above, sed_below, remove_below, add_above, add_between


mutable struct HypsometricProfileFixedArray
  width        :: Float32
  minElevation :: Float32
  maxElevation :: Float32
  delta        :: Float32
  elevation    :: Array{Float32}
  cummulativeImmobileExposure :: Array{Float32,2}
  cummulativeMobileExposure   :: Array{Float32,2}
  cummulativeImmobileExposureNames :: Array{String}
  cummulativeMobileExposureNames   :: Array{String}
  logger     :: ExtendedLogging.ExtendedLogger

  function HypsometricProfileFixedArray(w, elevations, imexp, mexp, imexp_names, mexp_names, logger)
    if (length(elevations)!=size(imexp,2)) Main.ExtendedLogging.log(logger,Logging.Error,@__FILE__,"\n length(elevations) != size(imexp,2) as length($elevations) != size($imexp,2) as $(length(elevations)) != $(size(imexp,2))") end
    if (length(elevations)!=size(mexp,2))  Main.ExtendedLogging.log(logger,Logging.Error,@__FILE__,"\n length(elevations) != size(mexp,2)  as length($elevations) != size($mexp,2)  as $(length(elevations)) != $(size(mexp,2))") end

    if (length(elevations) < 2)  Main.ExtendedLogging.log(logger,Logging.Error,@__FILE__,"\n length(elevations) = length($elevations) = $(length(elevations)) < 2 which is not allowed") end

    delta = elevations[2] - elevations[1]
    for x in 2:(length(elevations)) 
      if ((elevations[x]-elevations[x-1])!=delta) Main.ExtendedLogging.log(logger,Logging.Error,@__FILE__,"\n unequal delta: elevations[$x]-elevations[$(x-1)] = $(elevations[x])-$(elevations[x-1]) = $(elevations[x]-elevations[x-1]) != $delta") end
    end

    if (!issorted(elevations)) Main.ExtendedLogging.log(logger,Logging.Error,@__FILE__,"\n elevations is not sorted: $elevations") end
    if (imexp[:,1] != zeros(size(imexp,1))) Main.ExtendedLogging.log(logger,Logging.Error,@__FILE__,"\n imexp first column should be zero, but its not: $imexp") end
    if (mexp[:,1] != zeros(size(mexp,1)))   Main.ExtendedLogging.log(logger,Logging.Error,@__FILE__,"\n mexp first column should be zero, but its not: $mexp")   end

    new(w,elevations[1],elevations[length(elevations)], delta, elevations, cumsum(imexp,dims=2), cumsum(mexp,dims=2), imexp_names, mexp_names, logger)
  end

end


function exposure(hspf :: HypsometricProfileFixedArray, e) 
  if (e < hspf.minElevation) return (hspf.cummulativeImmobileExposure[:, 1], hspf.cummulativeMobileExposure[:, 1]) end
  if (e > hspf.maxElevation) return (hspf.cummulativeImmobileExposure[:, size(hspf.cummulativeImmobileExposure,2)], hspf.cummulativeMobileExposure[:, size(hspf.cummulativeMobileExposure,2)]) end

  i = floor(Int, (e-hspf.minElevation) / hspf.delta) + 1
  @inbounds r = (Float32)(e - hspf.elevation[i]) / hspf.delta
  
  @inbounds return ( hspf.cummulativeImmobileExposure[:, i] + (hspf.cummulativeImmobileExposure[:, i+1] - hspf.cummulativeImmobileExposure[:, 1]*r),
                     hspf.cummulativeMobileExposure[:, i] + (hspf.cummulativeMobileExposure[:, i+1] - hspf.cummulativeMobileExposure[:, 1]*r) )
end


function sed(hspf :: HypsometricProfileFixedArray, factors)
  if (size(hspf.cummulativeMobileExposure,1)!=length(factors)) Main.ExtendedLogging.log(hspf.logger, Logging.Error,@__FILE__,"\n size(hspf.cummulativeMobileExposure,1)!=length(factors) as size($hspf.cummulativeMobileExposure,1)!=length($factors) as $(size(hspf.cummulativeMobileExposure,1))!=$(length(factors))") end

  for i in 1:(size(hspf.cummulativeMobileExposure,1))
    hspf.cummulativeMobileExposure[i,:] *= factors[i]
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

  if (size(hspf.cummulativeMobileExposure,1)!=length(factors)) Main.ExtendedLogging.log(hspf.logger, Logging.Error,@__FILE__,"\n size(hspf.cummulativeMobileExposure,1)!=length(factors) as size($hspf.cummulativeMobileExposure,1)!=length($factors) as $(size(hspf.cummulativeMobileExposure,1))!=$(length(factors))") end

  s = floor(Int, (above-hspf.minElevation) / hspf.delta) + 2

  for i in s:(size(hspf.cummulativeMobileExposure,2))
    for j in 1:(size(hspf.cummulativeMobileExposure,1))
      hspf.cummulativeMobileExposure[j,i] *= factors[j]
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

  if (size(hspf.cummulativeMobileExposure,1)!=length(factors)) Main.ExtendedLogging.log(hspf.logger, Logging.Error,@__FILE__,"\n size(hspf.cummulativeMobileExposure,1)!=length(factors) as size($hspf.cummulativeMobileExposure,1)!=length($factors) as $(size(hspf.cummulativeMobileExposure,1))!=$(length(factors))") end

  s = floor(Int, (below-hspf.minElevation) / hspf.delta) + 1


  for i in 1:s
    for j in 1:(size(hspf.cummulativeMobileExposure,1))
      hspf.cummulativeMobileExposure[j,i] *= factors[j]
    end
  end

  for i in (s+1):(size(hspf.cummulativeMobileExposure,2))
    for j in 1:(size(hspf.cummulativeMobileExposure,1))
      hspf.cummulativeMobileExposure[j,i] += (hspf.cummulativeMobileExposure[j,s] - (hspf.cummulativeMobileExposure[j,s] / factors[j]))
    end
  end
end 


function remove_below(hspf, below)
  if (below < hspf.minElevation) 
    return (hspf.cummulativeMobileExposure[:, 1])
  end

  removed = hspf.cummulativeMobileExposure[:, 1]

  if (below >= hspf.maxElevation) 
    removed = hspf.cummulativeMobileExposure[:, size(hspf.cummulativeMobileExposure,2)]

    for j in 1:(size(hspf.cummulativeMobileExposure,1))
	hspf.cummulativeMobileExposure = zeros(size(hspf.cummulativeMobileExposure,1),size(hspf.cummulativeMobileExposure,2))
    end
    return removed
  end

  s = floor(Int, (below-hspf.minElevation) / hspf.delta) 

  removed = hspf.cummulativeMobileExposure[:, s]

  for i in 1:s
    for j in 1:(size(hspf.cummulativeMobileExposure,1))
      hspf.cummulativeMobileExposure[j,i] = 0f0
    end 
  end

  for i in (s+1):length(hspf.elevation)
    for j in 1:(size(hspf.cummulativeMobileExposure,1))
      hspf.cummulativeMobileExposure[j,i] -= removed[j]
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


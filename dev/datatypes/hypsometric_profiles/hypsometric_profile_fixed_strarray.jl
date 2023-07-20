using Main.ExtendedLogging
using Logging
using StructArrays


export exposure, sed, sed_above, sed_below, remove_below, add_above, add_between

mutable struct HypsometricProfileFixedStrarray{T1,T2}
  width        :: Float32
  minElevation :: Float32
  maxElevation :: Float32
  delta        :: Float32
  elevation    :: Array{Float32}
  area         :: Array{Float32}
  cummulativeImmobileExposure :: StructArray{T1}
  cummulativeMobileExposure   :: StructArray{T2}
  logger     :: ExtendedLogging.ExtendedLogger

  function HypsometricProfileFixedStrarray(w, m, elevations, area, imexp :: StructArray{T1}, mexp :: StructArray{T2}, logger) where {T1,T2}
    if (length(elevations)!=length(area))  Main.ExtendedLogging.log(logger,Logging.Error,@__FILE__,"\n length(elevations) != length(area) as length($elevations) != length($area) as $(length(elevations)) != $(length(area))") end
    if (length(elevations)!=size(imexp,1)) Main.ExtendedLogging.log(logger,Logging.Error,@__FILE__,"\n length(elevations) != size(imexp,1) as length($elevations) != size($imexp,1) as $(length(elevations)) != $(size(imexp,1))") end
    if (length(elevations)!=size(mexp,1))  Main.ExtendedLogging.log(logger,Logging.Error,@__FILE__,"\n length(elevations) != size(mexp,1)  as length($elevations) != size($mexp,1)  as $(length(elevations)) != $(size(mexp,1))") end
    if (length(elevations) < 1)  Main.ExtendedLogging.log(logger,Logging.Error,@__FILE__,"\n length(elevations) = length($elevations) = $(length(elevations)) < 2 which is not allowed") end
    if (elevations[1] < m)       Main.ExtendedLogging.log(logger,Logging.Error,@__FILE__,"\n elevations[1] = $(elevations[1]) < minimum elevation m = $m which is not allowed") end

    delta = elevations[1] - m
    for x in 2:(length(elevations)) 
      if ((elevations[x]-elevations[x-1])!=delta) Main.ExtendedLogging.log(logger,Logging.Error,@__FILE__,"\n unequal delta: elevations[$x]-elevations[$(x-1)] = $(elevations[x])-$(elevations[x-1]) = $(elevations[x]-elevations[x-1]) != $delta") end
    end

    if (!issorted(elevations)) Main.ExtendedLogging.log(logger,Logging.Error,@__FILE__,"\n elevations is not sorted: $elevations") end
#=
    imexp_new = zeros(size(imexp,1),size(imexp,2)+1)
    mexp_new =  zeros(size(mexp,1), size(mexp,2)+1)
    moveInto(imexp,imexp_new)
    moveInto(mexp, mexp_new)
=#
    new{T1,T2}(w,m,elevations[length(elevations)], delta, pushfirst!(elevations,m), cumsum(pushfirst!(area,0)), imexp, mexp, logger)
  end

end

#=
function moveInto(a,b)
  for i in 1:(size(b,1))
    for j in 2:(size(b,2))
      b[i,j] = a[i,j-1]
    end
  end
end


function exposure(hspf :: HypsometricProfileFixed, e) 
  if (e < hspf.minElevation) return (0f0,0f0,0f0) end
  if (e > hspf.maxElevation) return (hspf.cummulativeArea[length(hspf.cummulativeArea)], hspf.cummulativePopulation[length(hspf.cummulativePopulation)], hspf.cummulativeAssets[length(hspf.cummulativeAssets)]) end

  i = floor(Int, (e-hspf.minElevation) / hspf.delta) + 1
  @inbounds r = (e - hspf.elevation[i]) / hspf.delta
  
  @inbounds return ( Float32(hspf.cummulativeArea[i] + (hspf.cummulativeArea[i+1] - hspf.cummulativeArea[i])*r),
                     Float32(hspf.cummulativePopulation[i] + (hspf.cummulativePopulation[i+1] - hspf.cummulativePopulation[i])*r),
                     Float32(hspf.cummulativeAssets[i] + (hspf.cummulativeAssets[i+1] - hspf.cummulativeAssets[i])*r)  )
end


function sed(hspf, popfactor, assetfactor)
  hspf.cummulativePopulation *= popfactor
  hspf.cummulativeAssets *= assetfactor
end 


function sed_above(hspf, above, popfactor, assetfactor)
  if (above < hspf.minElevation) 
    sed(hspf, popfactor, assetfactor) 
    return 
  end
  if (above > hspf.maxElevation) 
    return 
  end

  s = floor(Int, (above-hspf.minElevation) / hspf.delta) + 2

  for i in s:(length(hspf.elevation))
    hspf.cummulativePopulation[i] *= popfactor
    hspf.cummulativeAssets[i] *= assetfactor
  end
end 


function sed_below(hspf, below, popfactor, assetfactor)
  if (below < hspf.minElevation) 
    return 
  end
  if (below > hspf.maxElevation) 
    sed(hspf, popfactor, assetfactor) 
    return 
  end

  s = floor(Int, (below-hspf.minElevation) / hspf.delta) + 1

  for i in 1:s
    hspf.cummulativePopulation[i] *= popfactor
    hspf.cummulativeAssets[i] *= assetfactor
  end

  for i in (s+1):length(hspf.elevation)
    hspf.cummulativePopulation[i] += (hspf.cummulativePopulation[s] - (hspf.cummulativePopulation[s] / popfactor))
    hspf.cummulativeAssets[i] += (hspf.cummulativeAssets[s] - (hspf.cummulativeAssets[s] / assetfactor))
  end
end 


function remove_below(hspf, below)
  if (below < hspf.minElevation) 
    return (0.0f0,0.0f0)
  end

  removed_pop = 0.0f0
  removed_assets = 0.0f0

  if (below >= hspf.maxElevation) 
    removed_pop = hspf.cummulativePopulation[length(hspf.cummulativePopulation)]
    removed_assets = hspf.cummulativeAssets[length(hspf.cummulativeAssets)]

    hspf.cummulativePopulation = zeros(length(hspf.cummulativePopulation))
    hspf.cummulativeAssets = zeros(length(hspf.cummulativeAssets))
    return (removed_pop,removed_assets)
  end

  s = floor(Int, (below-hspf.minElevation) / hspf.delta) 

  removed_pop    = hspf.cummulativePopulation[s]
  removed_assets = hspf.cummulativeAssets[s]

  for i in 1:s
    hspf.cummulativePopulation[i] = 0.0
    hspf.cummulativeAssets[i] = 0.0
  end

  for i in (s+1):length(hspf.elevation)
    hspf.cummulativePopulation[i] -= removed_pop
    hspf.cummulativeAssets[i] -= removed_assets
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
=#

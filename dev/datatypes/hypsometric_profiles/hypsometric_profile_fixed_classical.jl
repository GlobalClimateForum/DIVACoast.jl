using Main.ExtendedLogging
using Logging

export exposure, sed, sed_above, sed_below, remove_below, add_above, add_between

mutable struct HypsometricProfileFixedClassical
  width        :: Float32
  minElevation :: Float32
  maxElevation :: Float32
  delta        :: Float32
  elevation    :: Array{Float32}
  cummulativeArea       :: Array{Float32}
  cummulativePopulation :: Array{Float32}
  cummulativeAssets     :: Array{Float32}

  function HypsometricProfileFixedClassical(w,x1,x2,x3,x4,logger)
    if (length(x1)!=length(x2)) Main.ExtendedLogging.log(logger,Logging.Error,@__FILE__,"\n length(x1) != length(x2) as length($x1) != length($x2) as $(length(x1)) != $(length(x2))") end
    if (length(x1)!=length(x3)) Main.ExtendedLogging.log(logger,Logging.Error,@__FILE__,"\n length(x1) != length(x3) as length($x1) != length($x3) as $(length(x1)) != $(length(x3))") end
    if (length(x1)!=length(x4)) Main.ExtendedLogging.log(logger,Logging.Error,@__FILE__,"\n length(x1) != length(x4) as length($x1) != length($x4) as $(length(x1)) != $(length(x4))") end

    if (length(x1) < 2) Main.ExtendedLogging.log(logger,Logging.Error,@__FILE__,"\n length(x1) = length($x1) = $(length(x1)) < 2 which is not allowed") end

    delta = x1[2] - x1[1]
    for x in 2:(length(x1)) 
      if ((x1[x]-x1[x-1])!=delta) Main.ExtendedLogging.log(logger,Logging.Error,@__FILE__,"\n unequal delta: x1[$x]-x1[$(x-1)] = $(x1[x])-$(x1[x-1]) = $(x1[x]-x1[x-1]) != $delta") end
    end

    if (!issorted(x1)) Main.ExtendedLogging.log(logger,Logging.Error,@__FILE__,"\n x1 is not sorted: $x1") end

    if (x2[1]!=0) Main.ExtendedLogging.log(logger,Logging.Error,@__FILE__,"\n x2[1] should be zero, but is not: $x2") end
    if (x3[1]!=0) Main.ExtendedLogging.log(logger,Logging.Error,@__FILE__,"\n x3[1] should be zero, but is not: $x3") end
    if (x4[1]!=0) Main.ExtendedLogging.log(logger,Logging.Error,@__FILE__,"\n x4[1] should be zero, but is not: $x4") end

    new(w,x1[1],x1[length(x1)], delta, pushfirst!(x1), cumsum(pushfirst!(x2)), cumsum(pushfirst!(x3)), cumsum(pushfirst!(x4)))
  end

end


function exposure(hspf :: HypsometricProfileFixedClassical, e) 
  if (e < hspf.minElevation) return (0f0,0f0,0f0) end
  if (e > hspf.maxElevation) return (hspf.cummulativeArea[length(hspf.cummulativeArea)], hspf.cummulativePopulation[length(hspf.cummulativePopulation)], hspf.cummulativeAssets[length(hspf.cummulativeAssets)]) end

  i = floor(Int, (e-hspf.minElevation) / hspf.delta) + 1
  @inbounds r = (e - hspf.elevation[i]) / hspf.delta
  
  @inbounds return ( Float32(hspf.cummulativeArea[i] + (hspf.cummulativeArea[i+1] - hspf.cummulativeArea[i])*r),
                     Float32(hspf.cummulativePopulation[i] + (hspf.cummulativePopulation[i+1] - hspf.cummulativePopulation[i])*r),
                     Float32(hspf.cummulativeAssets[i] + (hspf.cummulativeAssets[i+1] - hspf.cummulativeAssets[i])*r)  )
end


function sed(hspf :: HypsometricProfileFixedClassical, popfactor, assetfactor)
  hspf.cummulativePopulation *= popfactor
  hspf.cummulativeAssets *= assetfactor
end 


function sed_above(hspf :: HypsometricProfileFixedClassical, above, popfactor, assetfactor)
  if (above < hspf.minElevation) 
    sed(hspf, popfactor, assetfactor) 
    return 
  end
  if (above > hspf.maxElevation) 
    return 
  end

  s = floor(Int, (above-hspf.minElevation) / hspf.delta) + 1

  for i in s:(length(hspf.elevation))
    hspf.cummulativePopulation[i] *= popfactor
    hspf.cummulativeAssets[i] *= assetfactor
  end
end 


function sed_below(hspf :: HypsometricProfileFixedClassical, below, popfactor, assetfactor)
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


function remove_below(hspf :: HypsometricProfileFixedClassical, below)
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


function add_above(hspf :: HypsometricProfileFixedClassical, above, pop, assets)
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


function add_between(hspf :: HypsometricProfileFixedClassical, above, below, pop, assets)
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

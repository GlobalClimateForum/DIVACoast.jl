using Main.ExtendedLogging
using Logging

export exposure, sed, sed_above, sed_below, remove_below, add_above, add_between

mutable struct HypsometricProfileFixed
  width        :: Float64
  minElevation :: Float64
  maxElevation :: Float64
  delta        :: Float64
  elevation  :: Array{Float64}
  area       :: Array{Float64}
  population :: Array{Float64}
  assets     :: Array{Float64}
  cummulativeArea       :: Array{Float64}
  cummulativePopulation :: Array{Float64}
  cummulativeAssets     :: Array{Float64}
  logger     :: ExtendedLogging.ExtendedLogger
  #  map :: Dict{(Int64,Int64),Int64}

  function HypsometricProfileFixed(w,m,x1,x2,x3,x4,logger)
    if (length(x1)!=length(x2)) Main.ExtendedLogging.log(logger,Logging.Error,@__FILE__,"\n length(x1) != length(x2) as length($x1) != length($x2) as $(length(x1)) != $(length(x2))") end
    if (length(x1)!=length(x3)) Main.ExtendedLogging.log(logger,Logging.Error,@__FILE__,"\n length(x1) != length(x3) as length($x1) != length($x3) as $(length(x1)) != $(length(x3))") end
    if (length(x1)!=length(x4)) Main.ExtendedLogging.log(logger,Logging.Error,@__FILE__,"\n length(x1) != length(x4) as length($x1) != length($x4) as $(length(x1)) != $(length(x4))") end

    if (length(x1) < 1) Main.ExtendedLogging.log(logger,Logging.Error,@__FILE__,"\n length(x1) = length($x1) = $(length(x1)) < 2 which is not allowed") end
    if (x1[1] < m) Main.ExtendedLogging.log(logger,Logging.Error,@__FILE__,"\n x1[1] = $(x1[1]) < minimum elevation m = $m which is not allowed") end

    delta = x1[1] - m
    for x in 2:(length(x1)) 
      if ((x1[x]-x1[x-1])!=delta) Main.ExtendedLogging.log(logger,Logging.Error,@__FILE__,"\n unequal delta: x1[$x]-x1[$(x-1)] = $(x1[x])-$(x1[x-1]) = $(x1[x]-x1[x-1]) != $delta") end
    end

    if (!issorted(x1)) Main.ExtendedLogging.log(logger,Logging.Error,@__FILE__,"\n x1 is not sorted: $x1") end
    new(w,m,x1[length(x1)],delta,pushfirst!(x1,m),pushfirst!(x2,0),pushfirst!(x3,0),pushfirst!(x4,0), cumsum(x2), cumsum(x3), cumsum(x4), logger)
  end

end


function exposure(hspf :: HypsometricProfileFixed, e) 
  if (e < hspf.minElevation) return (0,0,0) end
  if (e > hspf.maxElevation) return (hspf.cummulativeArea[length(hspf.cummulativeArea)], hspf.cummulativePopulation[length(hspf.cummulativePopulation)], hspf.cummulativeAssets[length(hspf.cummulativeAssets)]) end

  i = floor(Int, (e-hspf.minElevation) / hspf.delta) + 1
  @inbounds r = (e - hspf.elevation[i]) / hspf.delta
  
  @inbounds return ( hspf.cummulativeArea[i] + (hspf.cummulativeArea[i+1] - hspf.cummulativeArea[i])*r,
                     hspf.cummulativePopulation[i] + (hspf.cummulativePopulation[i+1] - hspf.cummulativePopulation[i])*r,
                     hspf.cummulativeAssets[i] + (hspf.cummulativeAssets[i+1] - hspf.cummulativeAssets[i])*r  )
end


function sed(hspf, popfactor, assetfactor)
  hspf.population *= popfactor
  hspf.assets *= assetfactor
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

  s = floor(Int, (above-hspf.minElevation) / hspf.delta) + 1

  for i in s:(length(hspf.elevation))
    hspf.population[i] *= popfactor
    hspf.assets[i] *= assetfactor
  end
  hspf.cummulativePopulation = cumsum(hspf.population)
  hspf.cummulativeAssets     = cumsum(hspf.assets)
end 


function sed_below(hspf, below, popfactor, assetfactor)
  if (below < hspf.minElevation) 
    return 
  end
  if (below > hspf.maxElevation) 
    sed(hspf, popfactor, assetfactor) 
    return 
  end

  s = floor(Int, (below-hspf.minElevation) / hspf.delta) 

  for i in 1:s
    hspf.population[i] *= popfactor
    hspf.assets[i] *= assetfactor
  end
  hspf.cummulativePopulation = cumsum(hspf.population)
  hspf.cummulativeAssets     = cumsum(hspf.assets)
end 


function remove_below(hspf, below)
  if (below < hspf.minElevation) 
    return (0.0,0.0)
  end

  removed_pop = 0.0
  removed_assets = 0.0

  if (below >= hspf.maxElevation) 
    removed_pop = hspf.cummulativePopulation[length(hspf.cummulativePopulation)]
    removed_assets = hspf.cummulativeAssets[length(hspf.cummulativeAssets)]
    hspf.population = zeros(length(hspf.population))
    hspf.assets = zeros(length(hspf.assets))

    hspf.cummulativePopulation = zeros(length(hspf.cummulativePopulation))
    hspf.cummulativeAssets = zeros(length(hspf.cummulativeAssets))
    return (removed_pop,removed_assets)
  end

  s = floor(Int, (below-hspf.minElevation) / hspf.delta) 

  for i in 1:s
    if (hspf.elevation[i]<below)
      removed_pop += hspf.population[i] 
      hspf.population[i] = 0.0
      removed_assets += hspf.assets[i] 
      hspf.assets[i] = 0.0
    end
  end
  hspf.cummulativePopulation = cumsum(hspf.population)
  hspf.cummulativeAssets     = cumsum(hspf.assets)

  return (removed_pop,removed_assets)
end


function add_above(hspf, above, pop, assets)
  if (above > hspf.maxElevation) 
    return 
  end
 
  s = floor(Int, (above-hspf.minElevation) / hspf.delta) + 1
  if (s<2) s=2 end

  for i in s:(length(hspf.elevation))
    hspf.population[i] +=  pop    / (1 + length(hspf.elevation) - s)
    hspf.assets[i]     +=  assets / (1 + length(hspf.elevation) - s)
  end  

  hspf.cummulativePopulation = cumsum(hspf.population)
  hspf.cummulativeAssets     = cumsum(hspf.assets)
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
    hspf.population[i] +=  pop    / (1 + s2 - s1)
    hspf.assets[i]     +=  assets / (1 + s2 - s1)
  end  

  hspf.cummulativePopulation = cumsum(hspf.population)
  hspf.cummulativeAssets     = cumsum(hspf.assets)
end


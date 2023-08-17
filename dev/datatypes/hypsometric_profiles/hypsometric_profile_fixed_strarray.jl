using Main.ExtendedLogging
using Logging

import Pkg; Pkg.add("StructArrays")
using StructArrays


export exposure, sed, sed_above, sed_below, remove_below, add_above, add_between


mutable struct HypsometricProfileFixedStrarray{T1,T2}
  width        :: Float32
  minElevation :: Float32
  maxElevation :: Float32
  delta        :: Float32
  elevation    :: Array{Float32}
  cummulativeArea              :: Array{Float32}
  cummulativeStaticExposure    :: StructArray{T1}
  cummulativeDynamicExposure   :: StructArray{T2}
  logger       :: ExtendedLogging.ExtendedLogger

  function HypsometricProfileFixedStrarray(w::Float32, elevations::Vector{Float32}, area::Vector{Float32}, s_exposure :: StructArray{T1}, d_exposure :: StructArray{T2}, logger :: ExtendedLogging.ExtendedLogger) where {T1,T2}
    if (length(elevations)!=length(area))  Main.ExtendedLogging.log(logger,Logging.Error,@__FILE__,"\n length(elevations) != length(area) as length($elevations) != length($area) as $(length(elevations)) != $(length(area))") end
    if (length(elevations)!=size(s_exposure,1)) Main.ExtendedLogging.log(logger,Logging.Error,@__FILE__,"\n length(elevations) != size(s_exposure,1) as length($elevations) != size($s_exposure,1) as $(length(elevations)) != $(size(s_exposure,1))") end
    if (length(elevations)!=size(d_exposure,1))  Main.ExtendedLogging.log(logger,Logging.Error,@__FILE__,"\n length(elevations) != size(d_exposure,1)  as length($elevations) != size($d_exposure,1)  as $(length(elevations)) != $(size(d_exposure,1))") end
    if (length(elevations) < 2)  Main.ExtendedLogging.log(logger,Logging.Error,@__FILE__,"\n length(elevations) = length($elevations) = $(length(elevations)) < 2 which is not allowed") end

    delta = elevations[2] - elevations[1]
    for x in 2:(length(elevations)) 
      if ((elevations[x]-elevations[x-1])!=delta) Main.ExtendedLogging.log(logger,Logging.Error,@__FILE__,"\n unequal delta: elevations[$x]-elevations[$(x-1)] = $(elevations[x])-$(elevations[x-1]) = $(elevations[x]-elevations[x-1]) != $delta") end
    end

    if (!issorted(elevations)) Main.ExtendedLogging.log(logger,Logging.Error,@__FILE__,"\n elevations is not sorted: $elevations") end
    if (area[1] != 0) Main.ExtendedLogging.log(logger,Logging.Error,@__FILE__,"\n area[1] should be zero, but its not: $area") end
    if (values(s_exposure[1]) != tuple(zeros(length(s_exposure[1]))...)) 
      println(values(s_exposure[1]))
      println(tuple(zeros(length(s_exposure[1])...)))
      Main.ExtendedLogging.log(logger,Logging.Error,@__FILE__,"\n s_exposure first column should be zero, but its not: $s_exposure") 
    end
    if (values(d_exposure[1]) != tuple(zeros(length(d_exposure[1]))...)) Main.ExtendedLogging.log(logger,Logging.Error,@__FILE__,"\n d_exposure first column should be zero, but its not: $d_exposure") end

    # cumulate - should be possible easier
    for i in 2:(length(s_exposure))
      for j in 1:(length(s_exposure[i]))
        fieldarrays(s_exposure)[j][i] += fieldarrays(s_exposure)[j][i-1]
      end
    end
    for i in 2:(length(d_exposure))
      for j in 1:(length(d_exposure[i]))
        fieldarrays(d_exposure)[j][i] += fieldarrays(d_exposure)[j][i-1]
      end
    end

    new{T1,T2}(w, elevations[1], elevations[length(elevations)], delta, elevations, cumsum(area), s_exposure, d_exposure, logger)
  end
end


function exposure(hspf :: HypsometricProfileFixedStrarray{T1,T2}, e)  where {T1,T2}
  if (e < hspf.minElevation) return (hspf.cummulativeArea[1], hspf.cummulativeStaticExposure[1], hspf.cummulativeDynamicExposure[1]) end
  if (e > hspf.maxElevation) return (hspf.cummulativeArea[length(hspf.cummulativeArea)], hspf.cummulativeStaticExposure[size(hspf.cummulativeStaticExposure,1)], hspf.cummulativeDynamicExposure[size(hspf.cummulativeDynamicExposure,1)]) end

  i = floor(Int, (e-hspf.minElevation) / hspf.delta) + 1
  @inbounds r = (Float32)(e - hspf.elevation[i]) / hspf.delta
  
  st_exp = values(hspf.cummulativeStaticExposure[i]) .+ ((values(hspf.cummulativeStaticExposure[i+1]) .- values(hspf.cummulativeStaticExposure[i])) .* r)
  dy_exp = values(hspf.cummulativeDynamicExposure[i]) .+ ((values(hspf.cummulativeDynamicExposure[i+1]) .- values(hspf.cummulativeDynamicExposure[i])) .* r)

  @inbounds return ( hspf.cummulativeArea[i] + (hspf.cummulativeArea[i+1] - hspf.cummulativeArea[i])*r, NamedTuple{keys(hspf.cummulativeStaticExposure[i])}(st_exp), NamedTuple{keys(hspf.cummulativeDynamicExposure[i])}(dy_exp))
end


function sed(hspf :: HypsometricProfileFixedStrarray{T1,T2}, factors::Vector{Float32}) where {T1,T2}
  if (length(hspf.cummulativeDynamicExposure[1])!=length(factors)) Main.ExtendedLogging.log(hspf.logger, Logging.Error,@__FILE__,"\n size(hspf.cummulativeDynamicExposure,1)!=length(factors) as size($hspf.cummulativeDynamicExposure,1)!=length($factors) as $(size(hspf.cummulativeDynamicExposure,1))!=$(length(factors))") end

  for i in 1:(length(factors))
    for j in 1:(length(fieldarrays(hspf.cummulativeDynamicExposure)[i]))
      fieldarrays(hspf.cummulativeDynamicExposure)[i][j] *= factors[i]
    end
  end
end 


function sed_above(hspf :: HypsometricProfileFixedStrarray{T1,T2}, factors::Vector{Float32}, above) where {T1,T2}
  if (above < hspf.minElevation) 
    sed(hspf, factors) 
    return 
  end
  if (above > hspf.maxElevation) 
    return 
  end

  if (length(hspf.cummulativeDynamicExposure[1])!=length(factors)) Main.ExtendedLogging.log(hspf.logger, Logging.Error,@__FILE__,"\n size(hspf.cummulativeDynamicExposure,1)!=length(factors) as size($hspf.cummulativeDynamicExposure,1)!=length($factors) as $(size(hspf.cummulativeDynamicExposure,1))!=$(length(factors))") end
  s = floor(Int, (above-hspf.minElevation) / hspf.delta) + 1

  for i in 1:(length(factors))
    if (s>1)
      for j in s:(length(fieldarrays(hspf.cummulativeDynamicExposure)[i]))
        fieldarrays(hspf.cummulativeDynamicExposure)[i][j] = fieldarrays(hspf.cummulativeDynamicExposure)[i][j] - fieldarrays(hspf.cummulativeDynamicExposure)[i][s-1]
      end
    end
    for j in s:(length(fieldarrays(hspf.cummulativeDynamicExposure)[i]))
      fieldarrays(hspf.cummulativeDynamicExposure)[i][j] *= factors[i]
    end
    if (s>1)
      for j in s:(length(fieldarrays(hspf.cummulativeDynamicExposure)[i]))
        fieldarrays(hspf.cummulativeDynamicExposure)[i][j] = fieldarrays(hspf.cummulativeDynamicExposure)[i][j] + fieldarrays(hspf.cummulativeDynamicExposure)[i][s-1]
      end
    end
  end
end 


function sed_below(hspf :: HypsometricProfileFixedStrarray{T1,T2}, factors::Vector{Float32}, below) where {T1,T2}
  if (below < hspf.minElevation) 
    return 
  end
  if (below > hspf.maxElevation) 
    sed(hspf, popfactor, assetfactor) 
    return 
  end

  if (length(hspf.cummulativeDynamicExposure[1])!=length(factors)) Main.ExtendedLogging.log(hspf.logger, Logging.Error,@__FILE__,"\n size(hspf.cummulativeDynamicExposure,1)!=length(factors) as size($hspf.cummulativeDynamicExposure,1)!=length($factors) as $(size(hspf.cummulativeDynamicExposure,1))!=$(length(factors))") end

  s = floor(Int, (below-hspf.minElevation) / hspf.delta) + 1

  for i in 1:(length(factors))
    for j in 1:s
      fieldarrays(hspf.cummulativeDynamicExposure)[i][j] *= factors[i]
    end
  end

  for i in 1:(length(factors))
    for j in (s+1):(length(fieldarrays(hspf.cummulativeDynamicExposure)[i]))
      fieldarrays(hspf.cummulativeDynamicExposure)[i][j] += (fieldarrays(hspf.cummulativeDynamicExposure)[i][s] - (fieldarrays(hspf.cummulativeDynamicExposure)[i][s] / factors[i]))
    end
  end
end 


function remove_below(hspf :: HypsometricProfileFixedStrarray{T1,T2}, below) where {T1,T2}
  if (below < hspf.minElevation) 
    return hspf.cummulativeDynamicExposure[1]
  end

  removed = hspf.cummulativeDynamicExposure[1]

  if (below >= hspf.maxElevation) 
    removed = hspf.cummulativeDynamicExposure[size(hspf.cummulativeDynamicExposure,1)]

    for i in 1:(length(fieldarrays(hspf.cummulativeDynamicExposure)))
      for j in 1:(length(fieldarrays(hspf.cummulativeDynamicExposure)[i]))
        fieldarrays(hspf.cummulativeDynamicExposure)[i][j] = 0f0
      end
    end
    return removed
  end

  s = floor(Int, (below-hspf.minElevation) / hspf.delta) + 2

  removed = hspf.cummulativeDynamicExposure[s]

  for i in 1:s
    for j in 1:(length(hspf.cummulativeDynamicExposure[i]))
      fieldarrays(hspf.cummulativeDynamicExposure)[j][i] = 0f0
    end 
  end

  for i in (s+1):length(hspf.elevation)
    for j in 1:(length(hspf.cummulativeDynamicExposure[i]))
      fieldarrays(hspf.cummulativeDynamicExposure)[j][i] -= removed[j]
    end
  end

  return removed
end


function add_above(hspf :: HypsometricProfileFixedStrarray{T1,T2}, above, values) where {T1,T2}
  if (length(hspf.cummulativeDynamicExposure[1])!=length(values)) Main.ExtendedLogging.log(hspf.logger, Logging.Error,@__FILE__,"\n size(hspf.cummulativeDynamicExposure,1)!=length(values) as size($hspf.cummulativeDynamicExposure,1)!=length($values) as $(size(hspf.cummulativeDynamicExposure,1))!=$(length(values))") end
  if (above > hspf.maxElevation) 
    return 
  end
 
  s = floor(Int, (above-hspf.minElevation) / hspf.delta) + 2
  if (s<2) s=2 end

  for i in s:length(hspf.elevation)
    for j in 1:(length(hspf.cummulativeDynamicExposure[i]))
      fieldarrays(hspf.cummulativeDynamicExposure)[j][i] += ((1+i-s) * values[j] / (1 + length(hspf.elevation) - s))
    end
  end
end


function add_between(hspf :: HypsometricProfileFixedStrarray{T1,T2}, above :: Float32, below :: Float32, values) where {T1,T2}
  if (below < above) 
    return 
  end

  s1 = floor(Int, (above-hspf.minElevation) / hspf.delta) + 1
  if (s1<1) s1=1 end

  s2 = floor(Int, (below-hspf.minElevation) / hspf.delta) + 1
  if (s2>length(hspf.elevation)) 
    s2=length(hspf.elevation) 
  end
  if (s2<s1) 
    s2=s1 
  end

  for i in (s1+1):s2
    for j in 1:(length(hspf.cummulativeDynamicExposure[i]))
      fieldarrays(hspf.cummulativeDynamicExposure)[j][i] += ((1+i-s1) * values[j] / (1 + s2 - s1))
    end
  end  

  for i in (s2+1):(length(hspf.elevation))
    for j in 1:(length(hspf.cummulativeDynamicExposure[i]))
      fieldarrays(hspf.cummulativeDynamicExposure)[j][i] += values[j] 
    end
  end  
end

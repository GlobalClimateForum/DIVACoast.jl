using Main.ExtendedLogging
using Logging
using StructArrays


export exposure, sed, sed_above, sed_below, remove_below, add_above, add_between


mutable struct HypsometricProfileFixed
  width        :: Float32
  minElevation :: Float32
  maxElevation :: Float32
  delta        :: Float32
  elevation    :: Array{Float32}
  cummulativeArea            :: Array{Float32}
  cummulativeStaticExposure  :: Array{Float32,2}
  cummulativeDynamicExposure :: Array{Float32,2}
#  cummulativeStaticSymbols   :: NTuple{N, Symbol}
#  cummulativeDynamicSymbols  :: NTuple{N, Symbol}
  cummulativeStaticSymbols   
  cummulativeDynamicSymbols  
  logger     :: ExtendedLogging.ExtendedLogger

#=
  function HypsometricProfileFixedArray(w::Float32, elevations::Vector{Float32}, area::Vector{Float32},s_exposure, d_exposure, d_exposure_names, s_exposure_names, logger)
    if (length(elevations)!=size(d_exposure,2)) Main.ExtendedLogging.log(logger,Logging.Error,@__FILE__,String(nameof(var"#self#")),"\n length(elevations) != size(d_exposure,2) as length($elevations) != size($d_exposure,2) as $(length(elevations)) != $(size(d_exposure,2))") end
    if (length(elevations)!=size(s_exposure,2)) Main.ExtendedLogging.log(logger,Logging.Error,@__FILE__,String(nameof(var"#self#")),"\n length(elevations) != size(s_exposure,2) as length($elevations) != size($s_exposure,2) as $(length(elevations)) != $(size(s_exposure,2))") end
    if (length(elevations) < 2)  Main.ExtendedLogging.log(logger,Logging.Error,@__FILE__,String(nameof(var"#self#")),"\n length(elevations) = length($elevations) = $(length(elevations)) < 2 which is not allowed") end
    if (!issorted(elevations)) Main.ExtendedLogging.log(logger,Logging.Error,@__FILE__,"\n elevations is not sorted: $elevations") end

    delta = elevations[2] - elevations[1]
    for x in 2:(length(elevations)) 
      if ((elevations[x]-elevations[x-1])!=delta) Main.ExtendedLogging.log(logger,Logging.Error,@__FILE__,String(nameof(var"#self#")),"\n unequal delta: elevations[$x]-elevations[$(x-1)] = $(elevations[x])-$(elevations[x-1]) = $(elevations[x]-elevations[x-1]) != $delta") end
    end

    if (area[1] != 0) Main.ExtendedLogging.log(logger,Logging.Error,@__FILE__,"\n area[1] should be zero, but its not: $area") end
    if (s_exposure[:,1] != zeros(size(s_exposure,1))) Main.ExtendedLogging.log(logger,Logging.Error,@__FILE__,String(nameof(var"#self#")),"\n s_exposure first column should be zero, but its not: $s_exposure") end
    if (d_exposure[:,1] != zeros(size(d_exposure,1))) Main.ExtendedLogging.log(logger,Logging.Error,@__FILE__,String(nameof(var"#self#")),"\n d_exposure first column should be zero, but its not: $d_exposure") end

    new(w,elevations[1],elevations[length(elevations)], delta, elevations, cumsum(area), cumsum(s_exposure,dims=2), cumsum(d_exposure,dims=2), s_exposure_names, d_exposure_names, logger)
  end
=#

  # Constructor
  function HypsometricProfileFixed(w::Float32, elevations::Vector{Float32}, area::Vector{Float32}, s_exposure :: StructArray{T1}, d_exposure :: StructArray{T2}, logger :: ExtendedLogging.ExtendedLogger) where {T1,T2}
    if (length(elevations)!=length(area))  Main.ExtendedLogging.log(logger,Logging.Error,@__FILE__,String(nameof(var"#self#")),"\n length(elevations) != length(area) as length($elevations) != length($area) as $(length(elevations)) != $(length(area))") end
    if (length(elevations)!=size(s_exposure,1)) Main.ExtendedLogging.log(logger,Logging.Error,@__FILE__,String(nameof(var"#self#")),"\n length(elevations) != size(s_exposure,1) as length($elevations) != size($s_exposure,1) as $(length(elevations)) != $(size(s_exposure,1))") end
    if (length(elevations)!=size(d_exposure,1))  Main.ExtendedLogging.log(logger,Logging.Error,@__FILE__,String(nameof(var"#self#")),"\n length(elevations) != size(d_exposure,1)  as length($elevations) != size($d_exposure,1)  as $(length(elevations)) != $(size(d_exposure,1))") end
    if (length(elevations) < 2)  Main.ExtendedLogging.log(logger,Logging.Error,@__FILE__,String(nameof(var"#self#")),"\n length(elevations) = length($elevations) = $(length(elevations)) < 2 which is not allowed") end
    if (!issorted(elevations)) Main.ExtendedLogging.log(logger,Logging.Error,@__FILE__,"\n elevations is not sorted: $elevations") end

    delta = elevations[2] - elevations[1]
    for x in 2:(length(elevations)) 
      if ((elevations[x]-elevations[x-1])!=delta) Main.ExtendedLogging.log(logger,Logging.Error,@__FILE__,"\n unequal delta: elevations[$x]-elevations[$(x-1)] = $(elevations[x])-$(elevations[x-1]) = $(elevations[x]-elevations[x-1]) != $delta") end
    end

    if (!issorted(elevations)) Main.ExtendedLogging.log(logger,Logging.Error,@__FILE__,"\n elevations is not sorted: $elevations") end
    if (area[1] != 0) Main.ExtendedLogging.log(logger,Logging.Error,@__FILE__,"\n area[1] should be zero, but its not: $area") end
    if (values(s_exposure[1]) != tuple(zeros(length(s_exposure[1]))...)) Main.ExtendedLogging.log(logger,Logging.Error,@__FILE__,String(nameof(var"#self#")),"\n d_exposure first column should be zero, but its not: $s_exposure") end
    if (values(d_exposure[1]) != tuple(zeros(length(d_exposure[1]))...)) Main.ExtendedLogging.log(logger,Logging.Error,@__FILE__,String(nameof(var"#self#")),"\n d_exposure first column should be zero, but its not: $d_exposure") end

    s_exposure_arrays = private_convert_strarray_to_array(s_exposure)
    d_exposure_arrays = private_convert_strarray_to_array(d_exposure)

    new(w, elevations[1], elevations[length(elevations)], delta, elevations, cumsum(area), cumsum(s_exposure_arrays,dims=1), cumsum(s_exposure_arrays,dims=1), keys(fieldarrays(s_exposure)), keys(fieldarrays(d_exposure)), logger)
  end
end


function exposure(hspf :: HypsometricProfileFixed, e :: Real) 
  if (e < hspf.minElevation) return (hspf.cummulativeArea[1], hspf.cummulativeStaticExposure[1,:], hspf.cummulativeDynamicExposure[1,:]) end
  if (e > hspf.maxElevation) return (hspf.cummulativeArea[length(hspf.cummulativeArea)], hspf.cummulativeStaticExposure[size(hspf.cummulativeStaticExposure,1),:], hspf.cummulativeDynamicExposure[size(hspf.cummulativeDynamicExposure,1),:]) end

  i = floor(Int, (e-hspf.minElevation) / hspf.delta) + 1

  @inbounds r = (Float32)(e - hspf.elevation[i]) / hspf.delta
  @inbounds return ( hspf.cummulativeArea[i] + ((hspf.cummulativeArea[i+1] - hspf.cummulativeArea[i])*r),
                     hspf.cummulativeStaticExposure[i, :] + ((hspf.cummulativeStaticExposure[i+1, :] - hspf.cummulativeStaticExposure[i, :])*r),
                     hspf.cummulativeDynamicExposure[i, :] + ((hspf.cummulativeDynamicExposure[i+1, :] - hspf.cummulativeDynamicExposure[i, :])*r) )
end


function exposure_named(hspf :: HypsometricProfileFixed, e :: Real) 
  if (e < hspf.minElevation) return (hspf.cummulativeArea[1], NamedTuple{hspf.cummulativeStaticSymbols}(hspf.cummulativeStaticExposure[1,:]), NamedTuple{hspf.cummulativeDynamicSymbols}(hspf.cummulativeDynamicExposure[1,:])) end
  if (e > hspf.maxElevation) return (hspf.cummulativeArea[length(hspf.cummulativeArea)], NamedTuple{hspf.cummulativeStaticSymbols}(hspf.cummulativeStaticExposure[size(hspf.cummulativeStaticExposure,1),:]), NamedTuple{hspf.cummulativeDynamicSymbols}(hspf.cummulativeDynamicExposure[size(hspf.cummulativeDynamicExposure,1),:])) end

  i = floor(Int, (e-hspf.minElevation) / hspf.delta) + 1
  @inbounds r = (Float32)(e - hspf.elevation[i]) / hspf.delta
  
  @inbounds return ( hspf.cummulativeArea[i] + ((hspf.cummulativeArea[i+1] - hspf.cummulativeArea[i])*r),
                     NamedTuple{hspf.cummulativeStaticSymbols}(hspf.cummulativeStaticExposure[i, :] + ((hspf.cummulativeStaticExposure[i+1, :] - hspf.cummulativeStaticExposure[i, :])*r)),
                     NamedTuple{hspf.cummulativeDynamicSymbols}(hspf.cummulativeDynamicExposure[i, :] + ((hspf.cummulativeDynamicExposure[i+1, :] - hspf.cummulativeDynamicExposure[i, :])*r)) )
end


function sed(hspf :: HypsometricProfileFixed, factors :: Array{T}) where {T <: Real}
  if (size(hspf.cummulativeDynamicExposure,2)!=length(factors)) Main.ExtendedLogging.log(hspf.logger, Logging.Error,@__FILE__,String(nameof(var"#self#")),"\n size(hspf.cummulativeDynamicExposure,2)!=length(factors) as size($hspf.cummulativeDynamicExposure,2)!=length($factors) as $(size(hspf.cummulativeDynamicExposure,2))!=$(length(factors))") end

  for j in 1:(size(hspf.cummulativeDynamicExposure,2))
    hspf.cummulativeDynamicExposure[:,j] *= factors[j]
  end
end 


function sed(hspf :: HypsometricProfileFixed, factors) 
  if (size(hspf.cummulativeDynamicExposure,2)!=length(factors)) Main.ExtendedLogging.log(hspf.logger, Logging.Error,@__FILE__,String(nameof(var"#self#")),"\n size(hspf.cummulativeDynamicExposure,2)!=length(factors) as size($hspf.cummulativeDynamicExposure,2)!=length($factors) as $(size(hspf.cummulativeDynamicExposure,2))!=$(length(factors))") end

  fac_array :: Array{Float32} = private_match_factors(hspf, factors)
  sed(hspf, fac_array)
end 


function sed_above(hspf :: HypsometricProfileFixed, above :: Real, factors :: Array{T}) where {T <: Real}
  if (size(hspf.cummulativeDynamicExposure,2)!=length(factors)) Main.ExtendedLogging.log(hspf.logger, Logging.Error,@__FILE__,String(nameof(var"#self#")),"\n size(hspf.cummulativeDynamicExposure,2)!=length(factors) as size($hspf.cummulativeDynamicExposure,2)!=length($factors) as $(size(hspf.cummulativeDynamicExposure,2))!=$(length(factors))") end
  if (above < hspf.minElevation) 
    sed(hspf, factors) 
    return 
  end
  if (above > hspf.maxElevation) 
    return 
  end

  s = floor(Int, (above-hspf.minElevation) / hspf.delta) + 2
  for i in s:(size(hspf.cummulativeDynamicExposure,1))
    for j in 1:(size(hspf.cummulativeDynamicExposure,2))
      hspf.cummulativeDynamicExposure[i,j] *= factors[j]
    end
  end
end 


function sed_above(hspf :: HypsometricProfileFixed, above :: Real, factors)
  if (size(hspf.cummulativeDynamicExposure,2)!=length(factors)) Main.ExtendedLogging.log(hspf.logger, Logging.Error,@__FILE__,String(nameof(var"#self#")),"\n size(hspf.cummulativeDynamicExposure,2)!=length(factors) as size($hspf.cummulativeDynamicExposure,2)!=length($factors) as $(size(hspf.cummulativeDynamicExposure,2))!=$(length(factors))") end

  fac_array :: Array{Float32} = private_match_factors(hspf, factors)
  sed_above(hspf, above, fac_array)
end 


function sed_below(hspf :: HypsometricProfileFixed, below :: Real, factors :: Array{T}) where {T <: Real}
  if (size(hspf.cummulativeDynamicExposure,2)!=length(factors)) Main.ExtendedLogging.log(hspf.logger, Logging.Error,@__FILE__,String(nameof(var"#self#")),"\n size(hspf.cummulativeDynamicExposure,2)!=length(factors) as size($hspf.cummulativeDynamicExposure,2)!=length($factors) as $(size(hspf.cummulativeDynamicExposure,2))!=$(length(factors))") end

  if (below < hspf.minElevation) 
    return 
  end
  if (below > hspf.maxElevation) 
    sed(hspf, factors) 
    return 
  end

  s = floor(Int, (below-hspf.minElevation) / hspf.delta) + 1

  for j in 1:(size(hspf.cummulativeDynamicExposure,2))
    for i in 1:s
      hspf.cummulativeDynamicExposure[i,j] *= factors[j]
    end
  end

  for j in 1:(size(hspf.cummulativeDynamicExposure,2))
    for i in (s+1):(size(hspf.cummulativeDynamicExposure,1))
      hspf.cummulativeDynamicExposure[i,j] += hspf.cummulativeDynamicExposure[s,j] - (hspf.cummulativeDynamicExposure[s,j] / factors[j])
    end
  end
end 


function sed_below(hspf :: HypsometricProfileFixed, below, factors)
  if (size(hspf.cummulativeDynamicExposure,2)!=length(factors)) Main.ExtendedLogging.log(hspf.logger, Logging.Error,@__FILE__,String(nameof(var"#self#")),"\n size(hspf.cummulativeDynamicExposure,2)!=length(factors) as size($hspf.cummulativeDynamicExposure,2)!=length($factors) as $(size(hspf.cummulativeDynamicExposure,2))!=$(length(factors))") end

  fac_array :: Array{Float32} = private_match_factors(hspf, factors)
  sed_below(hspf, below, fac_array)
end 


function remove_below(hspf :: HypsometricProfileFixed, below :: Real) :: Array{Float32}
  if (below < hspf.minElevation) 
    return (hspf.cummulativeDynamicExposure[1,:])
  end

  #removed = hspf.cummulativeDynamicExposure[:, 1]

  if (below >= hspf.maxElevation) 
    removed = hspf.cummulativeDynamicExposure[size(hspf.cummulativeDynamicExposure,1),:]

    hspf.cummulativeDynamicExposure = zeros(size(hspf.cummulativeDynamicExposure,1),size(hspf.cummulativeDynamicExposure,2))
    return removed
  end

  s = floor(Int, (below-hspf.minElevation) / hspf.delta) + 2
  removed = hspf.cummulativeDynamicExposure[s,:]

  for i in 1:s
    for j in 1:size(hspf.cummulativeDynamicExposure,2)
      hspf.cummulativeDynamicExposure[i,j] = 0f0
    end 
  end

  for i in (s+1):size(hspf.cummulativeDynamicExposure,1)
    for j in 1:size(hspf.cummulativeDynamicExposure,2)
      hspf.cummulativeDynamicExposure[i,j] -= removed[j]
    end
  end

  return removed
end


function remove_below_named(hspf :: HypsometricProfileFixed, below :: Real) 
   return NamedTuple{hspf.cummulativeDynamicSymbols}(remove_below(hspf, below))
end


function add_above(hspf :: HypsometricProfileFixed, above :: Real, values :: Array{T}) where {T <: Real}
  if (size(hspf.cummulativeDynamicExposure,2)!=length(values)) Main.ExtendedLogging.log(hspf.logger, Logging.Error,@__FILE__,String(nameof(var"#self#")),"\n size(hspf.cummulativeDynamicExposure,2)!=length(values) as size($hspf.cummulativeDynamicExposure,2)!=length($values) as $(size(hspf.cummulativeDynamicExposure,2))!=$(length(values))") end

  if (above > hspf.maxElevation) 
    return 
  end
 
  s = floor(Int, (above-hspf.minElevation) / hspf.delta) + 1
  if (s<2) s=2 end

  for i in s:size(hspf.cummulativeDynamicExposure,1)
    for j in 1:size(hspf.cummulativeDynamicExposure,2)
      hspf.cummulativeDynamicExposure[i,j] += ((1+i-s) * values[j] / (1 + size(hspf.cummulativeDynamicExposure,1) - s))
    end
  end  
end


function add_between(hspf :: HypsometricProfileFixed, above :: Real, below :: Real, values :: Array{T}) where {T <: Real}
  if (below < above) 
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
    for j in 1:size(hspf.cummulativeDynamicExposure,2)
      hspf.cummulativeDynamicExposure[i,j] += ((1+i-s1) *  values[j]    / (1 + s2 - s1))
    end 
  end

  for i in (s2+1):(length(hspf.elevation))
    for j in 1:size(hspf.cummulativeDynamicExposure,2)
      hspf.cummulativeDynamicExposure[i,j] += values[j]
    end
  end
end


function named(hspf :: HypsometricProfileFixed, f, args...) 
  return NamedTuple{hspf.cummulativeDynamicSymbols}(f(hspf, args...))
end


function private_convert_strarray_to_array(sarr :: StructArray{T1}) :: Array{Float32} where{T1} 
  ret :: Array{Float32,2} = Array{Float32, 2}(undef, length(sarr), length(fieldarrays(sarr))) 
  for i in 1:size(ret,1)
    for j in 1:size(ret,2)
      ret[i,j]=convert(Float32,fieldarrays(sarr)[j][i])
    end 
  end
  return ret
end


function private_match_factors(hspf :: HypsometricProfileFixed, factors) :: Array{Float32} 
  if (size(hspf.cummulativeDynamicExposure,2)!=length(factors)) Main.ExtendedLogging.log(hspf.logger, Logging.Error,@__FILE__,"\n size(hspf.cummulativeDynamicExposure,2)!=length(factors) as size($hspf.cummulativeDynamicExposure,2)!=length($factors) as $(size(hspf.cummulativeDynamicExposure,2))!=$(length(factors))") end

  fac_array :: Array{Float32} = fill(1.0f0, size(hspf.cummulativeDynamicExposure,2))

  for k in keys(factors)
    for i in 1:length(hspf.cummulativeDynamicSymbols)
      if (k==hspf.cummulativeDynamicSymbols[i])
        fac_array[i] = factors[k]
      end
    end
  end

  return fac_array
end 

using StructArrays

export HypsometricProfileFlex, exposure, sed, sed_above, sed_below, remove_below, add_above, add_between

mutable struct HypsometricProfileFlex
  width        :: Float32
  elevation    :: Array{Float32}
  cummulativeArea            :: Array{Float32}
  cummulativeStaticExposure  :: Array{Float32,2}
  cummulativeDynamicExposure :: Array{Float32,2}
  cummulativeStaticSymbols   
  cummulativeDynamicSymbols  
  logger     :: ExtendedLogger

  # Constructors
  function HypsometricProfileFlex(w::Float32, elevations::Vector{Float32}, area::Vector{Float32}, s_exposure :: StructArray{T1}, d_exposure :: StructArray{T2}, logger :: ExtendedLogger = ExtendedLogger()) where {T1,T2}
    if (length(elevations)!=length(area))  logg(logger,Logging.Error,@__FILE__,String(nameof(var"#self#")),"\n length(elevations) != length(area) as length($elevations) != length($area) as $(length(elevations)) != $(length(area))") end
    if (length(elevations)!=size(s_exposure,1)) logg(logger,Logging.Error,@__FILE__,String(nameof(var"#self#")),"\n length(elevations) != size(s_exposure,1) as length($elevations) != size($s_exposure,1) as $(length(elevations)) != $(size(s_exposure,1))") end
    if (length(elevations)!=size(d_exposure,1))  logg(logger,Logging.Error,@__FILE__,String(nameof(var"#self#")),"\n length(elevations) != size(d_exposure,1)  as length($elevations) != size($d_exposure,1)  as $(length(elevations)) != $(size(d_exposure,1))") end
    if (length(elevations) < 2)  logg(logger,Logging.Error,@__FILE__,String(nameof(var"#self#")),"\n length(elevations) = length($elevations) = $(length(elevations)) < 2 which is not allowed") end
    if (!issorted(elevations)) logg(logger,Logging.Error,@__FILE__,String(nameof(var"#self#")),"\n elevations is not sorted: $elevations") end

    if (area[1] != 0) logg(logger,Logging.Error,@__FILE__,String(nameof(var"#self#")),"\n area[1] should be zero, but its not: $area") end
    if (values(s_exposure[1]) != tuple(zeros(length(s_exposure[1]))...)) logg(logger,Logging.Error,@__FILE__,String(nameof(var"#self#")),"\n d_exposure first column should be zero, but its not: $s_exposure") end
    if (values(d_exposure[1]) != tuple(zeros(length(d_exposure[1]))...)) logg(logger,Logging.Error,@__FILE__,String(nameof(var"#self#")),"\n d_exposure first column should be zero, but its not: $d_exposure") end

    s_exposure_arrays = private_convert_strarray_to_array(s_exposure)
    d_exposure_arrays = private_convert_strarray_to_array(d_exposure)

    new(w, elevations, cumsum(area), cumsum(s_exposure_arrays,dims=1), cumsum(d_exposure_arrays,dims=1), keys(fieldarrays(s_exposure)), keys(fieldarrays(d_exposure)), logger)
  end
 
 function HypsometricProfileFlex(w::Float32, elevations::Vector{Float32}, area::Vector{Float32}, s_exposure :: Array{Float32,2}, d_exposure :: Array{Float32,2}, logger :: ExtendedLogger = ExtendedLogger())
    # String(nameof(var"#self#"))
    if (length(elevations)!=length(area))  logg(logger,Logging.Error,@__FILE__,"","\n length(elevations) != length(area) as length($elevations) != length($area) as $(length(elevations)) != $(length(area))") end
    if (length(elevations)!=size(s_exposure,1)) logg(logger,Logging.Error,@__FILE__,"","\n length(elevations) != size(s_exposure,1) as length($elevations) != size($s_exposure,1) as $(length(elevations)) != $(size(s_exposure,1))") end
    if (length(elevations)!=size(d_exposure,1))  logg(logger,Logging.Error,@__FILE__,"","\n length(elevations) != size(d_exposure,1)  as length($elevations) != size($d_exposure,1)  as $(length(elevations)) != $(size(d_exposure,1))") end
    if (length(elevations) < 2)  logg(logger,Logging.Error,@__FILE__,"","\n length(elevations) = length($elevations) = $(length(elevations)) < 2 which is not allowed") end
    if (!issorted(elevations)) logg(logger,Logging.Error,@__FILE__,"","\n elevations is not sorted: $elevations") end

    if (area[1] != 0) logg(logger,Logging.Error,@__FILE__,String(nameof(var"#self#")),"\n area[1] should be zero, but its not: $area") end
    #if (values(s_exposure[1]) != tuple(zeros(length(s_exposure[1]))...)) logg(logger,Logging.Error,@__FILE__,String(nameof(var"#self#")),"\n d_exposure first column should be zero, but its not: $s_exposure") end
    #if (values(d_exposure[1]) != tuple(zeros(length(d_exposure[1]))...)) logg(logger,Logging.Error,@__FILE__,String(nameof(var"#self#")),"\n d_exposure first column should be zero, but its not: $d_exposure") end

    new(w, elevations, cumsum(area), cumsum(s_exposure,dims=1), cumsum(d_exposure,dims=1), ntuple(i ->  Symbol("dexposure_name_$i"), size(s_exposure, 2)), ntuple(i ->  Symbol("dexposure_name_$i"), size(s_exposure, 2)), logger)
  end

end


function exposure(hspf :: HypsometricProfileFlex, e :: Real) 
  ind :: Int64 = searchsortedfirst(hspf.elevation, e)
  if (e in hspf.elevation) 
    return (hspf.cummulativeArea[ind], hspf.cummulativeStaticExposure[ind,:], hspf.cummulativeDynamicExposure[ind,:])
  else
    @inbounds if (ind == 1) return (hspf.cummulativeArea[ind], hspf.cummulativeStaticExposure[ind,:], hspf.cummulativeDynamicExposure[ind,:]) end
    @inbounds if (ind > size(hspf.elevation,1)) return (hspf.cummulativeArea[size(hspf.elevation,1)], hspf.cummulativeStaticExposure[size(hspf.elevation,1),:], hspf.cummulativeDynamicExposure[size(hspf.elevation,1),:]) end
    @inbounds r = (Float32)(e-hspf.elevation[ind-1]) / (hspf.elevation[ind]-hspf.elevation[ind-1])

    @inbounds return ( hspf.cummulativeArea[ind-1] + ((hspf.cummulativeArea[ind] - hspf.cummulativeArea[ind-1])*r),
                       hspf.cummulativeStaticExposure[ind-1, :] + ((hspf.cummulativeStaticExposure[ind, :] - hspf.cummulativeStaticExposure[ind-1, :])*r),
                       hspf.cummulativeDynamicExposure[ind-1, :] + ((hspf.cummulativeDynamicExposure[ind, :] - hspf.cummulativeDynamicExposure[ind-1, :])*r) )
  end
end


function exposure_named(hspf :: HypsometricProfileFlex, e :: Real) 
  ex = exposure(hspf, e)
  @inbounds return (ex[1], NamedTuple{hspf.cummulativeStaticSymbols}(ex[2]), NamedTuple{hspf.cummulativeDynamicSymbols}(ex[3]))
end


function distance(hspf :: HypsometricProfileFlex, e :: Real) :: Float32
  ind :: Int64 = searchsortedfirst(hspf.elevation, e)

  if (e in hspf.elevation) 
    return cos(asin(hspf.elevation[i]/(hspf.cummulativeArea[ind]/hspf.width)))*(hspf.cummulativeArea[ind]/hspf.width)
  else 
    @inbounds if (ind == 1) return 0.0f0 end
    @inbounds if (ind >= size(hspf.elevation,1)) cos(asin(hspf.elevation[size(hspf.elevation,1)]/(hspf.cummulativeArea[size(hspf.elevation,1)]/hspf.width)))*(hspf.cummulativeArea[size(hspf.elevation,1)]/hspf.width) end
    @inbounds r = (Float32)(e-hspf.elevation[ind-1]) / (hspf.elevation[ind]-hspf.elevation[ind-1])

    @inbounds return cos(asin(hspf.elevation[ind-1] + ((hspf.elevation[ind] - hspf.elevation[ind-1])*r)/(hspf.cummulativeArea[ind-1] + ((hspf.cummulativeArea[ind] - hspf.cummulativeArea[ind-1])*r)/hspf.width)))*(hspf.cummulativeArea[ind-1] + ((hspf.cummulativeArea[ind] - hspf.cummulativeArea[ind-1])*r)/hspf.width)
  end
end


function sed(hspf :: HypsometricProfileFlex, factors :: Array{T}) where {T <: Real}
  if (size(hspf.cummulativeDynamicExposure,2)!=length(factors)) logg(hspf.logger, Logging.Error,@__FILE__,String(nameof(var"#self#")),"\n size(hspf.cummulativeDynamicExposure,2)!=length(factors) as size($hspf.cummulativeDynamicExposure,2)!=length($factors) as $(size(hspf.cummulativeDynamicExposure,2))!=$(length(factors))") end

  for j in 1:(size(hspf.cummulativeDynamicExposure,2))
    hspf.cummulativeDynamicExposure[:,j] *= factors[j]
  end
end 


function sed(hspf :: HypsometricProfileFlex, factors) 
  if (size(hspf.cummulativeDynamicExposure,2)!=length(factors)) logg(hspf.logger, Logging.Error,@__FILE__,String(nameof(var"#self#")),"\n size(hspf.cummulativeDynamicExposure,2)!=length(factors) as size($hspf.cummulativeDynamicExposure,2)!=length($factors) as $(size(hspf.cummulativeDynamicExposure,2))!=$(length(factors))") end

  fac_array :: Array{Float32} = private_match_factors(hspf, factors)
  sed(hspf, fac_array)
end 


function sed_above(hspf :: HypsometricProfileFlex, above :: Real, factors :: Array{T}) where {T <: Real}
  if (size(hspf.cummulativeDynamicExposure,2)!=length(factors)) logg(hspf.logger, Logging.Error,@__FILE__,String(nameof(var"#self#")),"\n size(hspf.cummulativeDynamicExposure,2)!=length(factors) as size($hspf.cummulativeDynamicExposure,2)!=length($factors) as $(size(hspf.cummulativeDynamicExposure,2))!=$(length(factors))") end

  if (above < hspf.elevation[1]) 
    sed(hspf, factors) 
    return 
  end
  if (above > hspf.elevation[size(hspf.elevation,1)]) 
    return 
  end

  ind :: Int64 = searchsortedfirst(hspf.elevation, above)

  if !(above in hspf.elevation) 
    private_insert_elevation_point(hspf, above, ind)
  end

  for i in (ind+1):(size(hspf.cummulativeDynamicExposure,1))
    for j in 1:(size(hspf.cummulativeDynamicExposure,2))
      hspf.cummulativeDynamicExposure[i,j] *= factors[j]
    end
  end
end 


function sed_above(hspf :: HypsometricProfileFlex, above :: Real, factors)
  if (size(hspf.cummulativeDynamicExposure,2)!=length(factors)) logg(hspf.logger, Logging.Error,@__FILE__,String(nameof(var"#self#")),"\n size(hspf.cummulativeDynamicExposure,2)!=length(factors) as size($hspf.cummulativeDynamicExposure,2)!=length($factors) as $(size(hspf.cummulativeDynamicExposure,2))!=$(length(factors))") end

  fac_array :: Array{Float32} = private_match_factors(hspf, factors)
  sed_above(hspf, above, fac_array)
end 


function sed_below(hspf :: HypsometricProfileFlex, below :: Real, factors :: Array{T}) where {T <: Real}
  if (size(hspf.cummulativeDynamicExposure,2)!=length(factors)) logg(hspf.logger, Logging.Error,@__FILE__,String(nameof(var"#self#")),"\n size(hspf.cummulativeDynamicExposure,2)!=length(factors) as size($hspf.cummulativeDynamicExposure,2)!=length($factors) as $(size(hspf.cummulativeDynamicExposure,2))!=$(length(factors))") end

  if (below < hspf.elevation[1]) 
    return 
  end
  if (below > hspf.elevation[size(hspf.elevation,1)]) 
    sed(hspf, factors) 
    return 
  end

  ind :: Int64 = searchsortedfirst(hspf.elevation, below)

  if !(below in hspf.elevation) 
    private_insert_elevation_point(hspf, below, ind)
  end

  for i in 1:ind
    for j in 1:size(hspf.cummulativeDynamicExposure,2)
      hspf.cummulativeDynamicExposure[i,j] *= factors[j]
    end
  end

  for i in (ind+1):size(hspf.cummulativeDynamicExposure,1)
    for j in 1:size(hspf.cummulativeDynamicExposure,2)
      hspf.cummulativeDynamicExposure[i,j] *= hspf.cummulativeDynamicExposure[i,j] + (hspf.cummulativeDynamicExposure[ind,j]  - (1/factors[j])*hspf.cummulativeDynamicExposure[ind,j]) 
    end
  end
end 


function sed_below(hspf :: HypsometricProfileFlex, below, factors)
  if (size(hspf.cummulativeDynamicExposure,2)!=length(factors)) logg(hspf.logger, Logging.Error,@__FILE__,String(nameof(var"#self#")),"\n size(hspf.cummulativeDynamicExposure,2)!=length(factors) as size($hspf.cummulativeDynamicExposure,2)!=length($factors) as $(size(hspf.cummulativeDynamicExposure,2))!=$(length(factors))") end

  fac_array :: Array{Float32} = private_match_factors(hspf, factors)
  sed_below(hspf, below, fac_array)
end 


function remove_below(hspf :: HypsometricProfileFlex, below :: Real) :: Array{Float32}
  if (below < hspf.elevation[1]) 
    return (hspf.cummulativeDynamicExposure[1,:])
  end

  if (below >= hspf.elevation[size(hspf.elevation,1)]) 
    removed = hspf.cummulativeDynamicExposure[size(hspf.cummulativeDynamicExposure,1),:]

    hspf.cummulativeDynamicExposure = zeros(size(hspf.cummulativeDynamicExposure,1),size(hspf.cummulativeDynamicExposure,2))
    return removed
  end

  ind :: Int64 = searchsortedfirst(hspf.elevation, below)

  if !(below in hspf.elevation) 
    private_insert_elevation_point(hspf, below, ind)
  end

  removed = exposure(hspf, hspf.elevation[ind])[3]

  for i in 1:ind
    for j in 1:size(hspf.cummulativeDynamicExposure,2)
      hspf.cummulativeDynamicExposure[i,j] = 0f0
    end 
  end

  for i in (ind+1):size(hspf.cummulativeDynamicExposure,1)
    for j in 1:size(hspf.cummulativeDynamicExposure,2)
      hspf.cummulativeDynamicExposure[i,j] -= removed[j]
    end
  end

  private_clean_up(hspf)

  return removed
end


function remove_below_named(hspf :: HypsometricProfileFlex, below :: Real) 
   return NamedTuple{hspf.cummulativeDynamicSymbols}(remove_below(hspf, below))
end


function add_above(hspf :: HypsometricProfileFlex, above :: Real, values :: Array{T}) where {T <: Real}
  if (size(hspf.cummulativeDynamicExposure,2)!=length(values)) logg(hspf.logger, Logging.Error,@__FILE__,String(nameof(var"#self#")),"\n size(hspf.cummulativeDynamicExposure,2)!=length(values) as size($hspf.cummulativeDynamicExposure,2)!=length($values) as $(size(hspf.cummulativeDynamicExposure,2))!=$(length(values))") end

  if (above > hspf.elevation[size(hspf.elevation,1)]) 
    return 
  end

  ind :: Int64 = searchsortedfirst(hspf.elevation, above)

  if !(above in hspf.elevation) 
    private_insert_elevation_point(hspf, above, ind)
  end
 
  for i in (ind+1):size(hspf.cummulativeDynamicExposure,1)
    for j in 1:size(hspf.cummulativeDynamicExposure,2)
      hspf.cummulativeDynamicExposure[i,j] += ((1+i-(ind+1)) * values[j] / (1 + size(hspf.cummulativeDynamicExposure,1) - (ind+1)))
    end
  end  

  private_clean_up(hspf)
end


function add_between(hspf :: HypsometricProfileFlex, above :: Real, below :: Real, values :: Array{T}) where {T <: Real}
  if (below < above) 
    return 
  end

  ind1 :: Int64 = searchsortedfirst(hspf.elevation, above)
  if !(above in hspf.elevation) 
    private_insert_elevation_point(hspf, above, ind1)
  end

  ind2 :: Int64 = searchsortedfirst(hspf.elevation, below)
  if !(below in hspf.elevation) 
    private_insert_elevation_point(hspf, below, ind2)
  end

  for i in (ind1+1):ind2
    for j in 1:size(hspf.cummulativeDynamicExposure,2)
      hspf.cummulativeDynamicExposure[i,j] += (((i-ind1)/(ind2-ind1)) *  values[j])
    end 
  end

  for i in (ind2+1):size(hspf.cummulativeDynamicExposure,1)
    for j in 1:size(hspf.cummulativeDynamicExposure,2)
      hspf.cummulativeDynamicExposure[i,j] += values[j]
    end
  end

  private_clean_up(hspf)
end


### Damage
function damage(hspf :: HypsometricProfileFlex, wl :: Real, protection :: Real, hdds_static :: Array{T1}, hdds_dynamic :: Array{T2}) where {T1,T2 <: Real} 
  if (wl <= protection) return (hspf.cummulativeArea[1], hspf.cummulativeStaticExposure[1,:], hspf.cummulativeDynamicExposure[1,:]) end

  ind :: Int64 = searchsortedfirst(hspf.elevation, wl)
  @inbounds if (ind == 1) return (hspf.cummulativeArea[ind], hspf.cummulativeStaticExposure[ind,:], hspf.cummulativeDynamicExposure[ind,:]) end

  @inbounds r = (Float32)(wl-hspf.elevation[ind-1]) / (hspf.elevation[ind]-hspf.elevation[ind-1])

  for i in 1:(ind-1)
    dam = damage(hspf, i, i+1, protection, hdds)
  end

#  if (r==0)
#  else
#  end
end 


function damage(hspf :: HypsometricProfileFlex, wl :: Real, i1 :: Int64, i2 :: Int64, hdds_static :: Array{T1}, hdds_dynamic :: Array{T2}) where {T1,T2 <: Real} 
  delta_el = hspf.elevation[i2] - hspf.elevation[i1]
  factor_static = map(h -> (h * logg((h+wl-hspf.elevation[i2])/(h+wl-hspf.elevation[i1])) + delta_el), hdd_static)
  factor_dynamic = map(h -> (h * logg((h+wl-hspf.elevation[i2])/(h+wl-hspf.elevation[i1])) + delta_el), hdd_dynamic)

  part_exp = hspf.cummulativeStaticExposure[i2, :] - hspf.cummulativeStaticExposure[i1, :]
# (10,20,3,8)
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


function private_match_factors(hspf :: HypsometricProfileFlex, factors) :: Array{Float32} 
  if (size(hspf.cummulativeDynamicExposure,2)!=length(factors)) logg(hspf.logger, Logging.Error,@__FILE__,"\n size(hspf.cummulativeDynamicExposure,2)!=length(factors) as size($hspf.cummulativeDynamicExposure,2)!=length($factors) as $(size(hspf.cummulativeDynamicExposure,2))!=$(length(factors))") end

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


function private_insert_elevation_point(hspf :: HypsometricProfileFlex, el :: Real, ind :: Int64)
  ex = exposure(hspf, el)
  insert!(hspf.elevation,       ind, el)
  insert!(hspf.cummulativeArea, ind, ex[1])
  # probably not efficient
  r :: Array{Float32,2} = hspf.cummulativeStaticExposure[ind:end,1:end]
  hspf.cummulativeStaticExposure = vcat(vcat(hspf.cummulativeStaticExposure[1:ind-1,1:end],ex[2]'),r)

  r = hspf.cummulativeDynamicExposure[ind:end,1:end]
  hspf.cummulativeDynamicExposure = vcat(vcat(hspf.cummulativeDynamicExposure[1:ind-1,1:end],ex[3]'),r)
end


function private_clean_up(hspf :: HypsometricProfileFlex)
  for i in 3:size(hspf.cummulativeDynamicExposure,1)-1
    if private_colinear_lines(hspf,i-1,i,i+1) private_remove_line(hpsf, i) end
  end
end


function private_colinear_lines(hspf :: HypsometricProfileFlex, i1 :: Int64, i2 :: Int64, i3 :: Int64) :: Bool
  ex1 = exposure(hspf, hspf.elevation[i1])
  ex2 = exposure(hspf, hspf.elevation[i2])
  ex3 = exposure(hspf, hspf.elevation[i3])
  r = (hspf.elevation[i2]-hspf.elevation[i1])/(hspf.elevation[i3]-hspf.elevation[i1])
  return isapprox(ex2[1],ex1[1]+r*(ex2[1]-ex1[1])) && isapprox(ex2[2],ex1[2]+r*(ex2[2]-ex1[2])) && isapprox(ex2[3],ex1[3]+r*(ex2[3]-ex1[3])) 
end


function private_remove_line(hspf :: HypsometricProfileFlex, i)
  # probably not efficient
  newarray = hspf.elevation[1:end .!= (i), :]
  hpsf.elevation = newarray
  newarray = hspf.cummulativeArea[1:end .!= (i), :]
  hpsf.cummulativeArea = newarray
  newarray = hspf.cummulativeStaticExposure[1:end .!= (i), :]
  hspf.cummulativeStaticExposure = newarray
  newarray = hspf.cummulativeDynamicExposure[1:end .!= (i), :]
  hspf.cummulativeDynamicExposure = newarray
end


function private_slope(hspf :: HypsometricProfileFlex, i :: Int64) :: Float32
  if (i<=1) return Inf end
  if (i>size(hspf.elevation,1)) return (hspf.elevation[size(hspf.elevation,1)]-hspf.elevation[size(hspf.elevation,1)-1]) * (hspf.width/hspf.cummulativeArea[size(hspf.elevation,1)]) end
  return (hspf.elevation[i]-hspf.elevation[i-1]) * (hspf.width/hspf.cummulativeArea[i])
end


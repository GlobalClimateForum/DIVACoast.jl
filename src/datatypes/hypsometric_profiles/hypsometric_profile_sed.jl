function sed(hspf::HypsometricProfile, factors::Array{T}) where {T<:Real}
  if (size(hspf.cummulativeDynamicExposure, 2) != length(factors))
    logg(hspf.logger, Logging.Error, @__FILE__, String(nameof(var"#self#")), "\n size(hspf.cummulativeDynamicExposure,2)!=length(factors) as size($hspf.cummulativeDynamicExposure,2)!=length($factors) as $(size(hspf.cummulativeDynamicExposure,2))!=$(length(factors))")
  end

  for j in 1:(size(hspf.cummulativeDynamicExposure, 2))
    hspf.cummulativeDynamicExposure[:, j] *= factors[j]
  end
end


function sed(hspf::HypsometricProfile{DT}, factors) where {DT<:Real}
  if (size(hspf.cummulativeDynamicExposure, 2) != length(factors))
    logg(hspf.logger, Logging.Error, @__FILE__, String(nameof(var"#self#")), "\n size(hspf.cummulativeDynamicExposure,2)!=length(factors) as size($hspf.cummulativeDynamicExposure,2)!=length($factors) as $(size(hspf.cummulativeDynamicExposure,2))!=$(length(factors))")
  end

  fac_array :: Array{DT} = private_match_factors(hspf, factors)
  sed(hspf, fac_array)
end


function sed_above(hspf::HypsometricProfile, above::Real, factors::Array{DT}) where {DT<:Real}
  if (size(hspf.cummulativeDynamicExposure, 2) != length(factors))
    logg(hspf.logger, Logging.Error, @__FILE__, String(nameof(var"#self#")), "\n size(hspf.cummulativeDynamicExposure,2)!=length(factors) as size($hspf.cummulativeDynamicExposure,2)!=length($factors) as $(size(hspf.cummulativeDynamicExposure,2))!=$(length(factors))")
  end

  if (above < hspf.elevation[1])
    sed(hspf, factors)
    return
  end
  if (above > hspf.elevation[size(hspf.elevation, 1)])
    return
  end

  ind::Int64 = searchsortedfirst(hspf.elevation, above)

  if !(above in hspf.elevation)
    private_insert_elevation_point(hspf, above, ind)
  end

  for i in (ind+1):(size(hspf.cummulativeDynamicExposure, 1))
    for j in 1:(size(hspf.cummulativeDynamicExposure, 2))
      hspf.cummulativeDynamicExposure[i, j] *= factors[j]
    end
  end
end


function sed_above(hspf::HypsometricProfile, above::Real, factors)
  if (size(hspf.cummulativeDynamicExposure, 2) != length(factors))
    logg(hspf.logger, Logging.Error, @__FILE__, String(nameof(var"#self#")), "\n size(hspf.cummulativeDynamicExposure,2)!=length(factors) as size($hspf.cummulativeDynamicExposure,2)!=length($factors) as $(size(hspf.cummulativeDynamicExposure,2))!=$(length(factors))")
  end

  fac_array::Array{DT} = private_match_factors(hspf, factors)
  sed_above(hspf, above, fac_array)
end


function sed_below(hspf::HypsometricProfile, below::Real, factors::Array{T}) where {T<:Real}
  if (size(hspf.cummulativeDynamicExposure, 2) != length(factors))
    logg(hspf.logger, Logging.Error, @__FILE__, String(nameof(var"#self#")), "\n size(hspf.cummulativeDynamicExposure,2)!=length(factors) as size($hspf.cummulativeDynamicExposure,2)!=length($factors) as $(size(hspf.cummulativeDynamicExposure,2))!=$(length(factors))")
  end

  if (below < hspf.elevation[1])
    return
  end
  if (below > hspf.elevation[size(hspf.elevation, 1)])
    sed(hspf, factors)
    return
  end

  ind::Int64 = searchsortedfirst(hspf.elevation, below)

  if !(below in hspf.elevation)
    private_insert_elevation_point(hspf, below, ind)
  end

  for i in 1:ind
    for j in 1:size(hspf.cummulativeDynamicExposure, 2)
      hspf.cummulativeDynamicExposure[i, j] *= factors[j]
    end
  end

  for i in (ind+1):size(hspf.cummulativeDynamicExposure, 1)
    for j in 1:size(hspf.cummulativeDynamicExposure, 2)
      hspf.cummulativeDynamicExposure[i, j] *= hspf.cummulativeDynamicExposure[i, j] + (hspf.cummulativeDynamicExposure[ind, j] - (1 / factors[j]) * hspf.cummulativeDynamicExposure[ind, j])
    end
  end
end


function sed_below(hspf::HypsometricProfile{DT}, below, factors) where {DT<:Real}
  if (size(hspf.cummulativeDynamicExposure, 2) != length(factors))
    logg(hspf.logger, Logging.Error, @__FILE__, String(nameof(var"#self#")), "\n size(hspf.cummulativeDynamicExposure,2)!=length(factors) as size($hspf.cummulativeDynamicExposure,2)!=length($factors) as $(size(hspf.cummulativeDynamicExposure,2))!=$(length(factors))")
  end

  fac_array::Array{DT} = private_match_factors(hspf, factors)
  sed_below(hspf, below, fac_array)
end


function remove_below(hspf::HypsometricProfile{DT}, below::Real) :: Array{DT}  where {DT<:Real}
  if (below < hspf.elevation[1])
    return (hspf.cummulativeDynamicExposure[1, :])
  end

  if (below >= hspf.elevation[size(hspf.elevation, 1)])
    removed = hspf.cummulativeDynamicExposure[size(hspf.cummulativeDynamicExposure, 1), :]

    hspf.cummulativeDynamicExposure = zeros(size(hspf.cummulativeDynamicExposure, 1), size(hspf.cummulativeDynamicExposure, 2))
    return removed
  end

  ind::Int64 = searchsortedfirst(hspf.elevation, below)

  if !(below in hspf.elevation)
    private_insert_elevation_point(hspf, below, ind)
  end

  removed = exposure(hspf, hspf.elevation[ind])[3]

  for i in 1:ind
    for j in 1:size(hspf.cummulativeDynamicExposure, 2)
      hspf.cummulativeDynamicExposure[i, j] = 0.0f0
    end
  end

  for i in (ind+1):size(hspf.cummulativeDynamicExposure, 1)
    for j in 1:size(hspf.cummulativeDynamicExposure, 2)
      hspf.cummulativeDynamicExposure[i, j] -= removed[j]
    end
  end

  compress!(hspf)

  return removed
end


function remove_below_named(hspf::HypsometricProfile, below::Real)
  return NamedTuple{hspf.dynamicExposureSymbols}(remove_below(hspf, below))
end


function add_above(hspf::HypsometricProfile, above::Real, values::Array{T}) where {T<:Real}
  if (size(hspf.cummulativeDynamicExposure, 2) != length(values))
    logg(hspf.logger, Logging.Error, @__FILE__, String(nameof(var"#self#")), "\n size(hspf.cummulativeDynamicExposure,2)!=length(values) as size($hspf.cummulativeDynamicExposure,2)!=length($values) as $(size(hspf.cummulativeDynamicExposure,2))!=$(length(values))")
  end

  if (above > hspf.elevation[size(hspf.elevation, 1)])
    return
  end

  ind::Int64 = searchsortedfirst(hspf.elevation, above)

  if !(above in hspf.elevation)
    private_insert_elevation_point(hspf, above, ind)
  end

  for i in (ind+1):size(hspf.cummulativeDynamicExposure, 1)
    for j in 1:size(hspf.cummulativeDynamicExposure, 2)
      hspf.cummulativeDynamicExposure[i, j] += ((1 + i - (ind + 1)) * values[j] / (1 + size(hspf.cummulativeDynamicExposure, 1) - (ind + 1)))
    end
  end

  compress!(hspf)
end


function add_between(hspf::HypsometricProfile, above::Real, below::Real, values::Array{T}) where {T<:Real}
  if (below < above)
    return
  end

  ind1::Int64 = searchsortedfirst(hspf.elevation, above)
  if !(above in hspf.elevation)
    private_insert_elevation_point(hspf, above, ind1)
  end

  ind2::Int64 = searchsortedfirst(hspf.elevation, below)
  if !(below in hspf.elevation)
    private_insert_elevation_point(hspf, below, ind2)
  end

  for i in (ind1+1):ind2
    for j in 1:size(hspf.cummulativeDynamicExposure, 2)
      hspf.cummulativeDynamicExposure[i, j] += (((i - ind1) / (ind2 - ind1)) * values[j])
    end
  end

  for i in (ind2+1):size(hspf.cummulativeDynamicExposure, 1)
    for j in 1:size(hspf.cummulativeDynamicExposure, 2)
      hspf.cummulativeDynamicExposure[i, j] += values[j]
    end
  end

  compress!(hspf)
end


function private_match_factors(hspf::HypsometricProfile{DT}, factors) :: Array{DT} where {DT<:Real}
  if (size(hspf.cummulativeDynamicExposure, 2) != length(factors))
    logg(hspf.logger, Logging.Error, @__FILE__, "\n size(hspf.cummulativeDynamicExposure,2)!=length(factors) as size($hspf.cummulativeDynamicExposure,2)!=length($factors) as $(size(hspf.cummulativeDynamicExposure,2))!=$(length(factors))")
  end

  fac_array :: Array{DT} = fill(1.0f0, size(hspf.cummulativeDynamicExposure, 2))

  for k in keys(factors)
    for i in 1:length(hspf.dynamicExposureSymbols)
      if (k == hspf.dynamicExposureSymbols[i])
        fac_array[i] = factors[k]
      end
    end
  end

  return fac_array
end


function private_insert_elevation_point(hspf::HypsometricProfile{DT}, el::Real, ind::Int64) where {DT<:Real}
  ex = exposure(hspf, el)
  insert!(hspf.elevation, ind, el)
  insert!(hspf.cummulativeArea, ind, ex[1])
  # probably not efficient
  r::Array{DT,2} = hspf.cummulativeStaticExposure[ind:end, 1:end]
  hspf.cummulativeStaticExposure = vcat(vcat(hspf.cummulativeStaticExposure[1:ind-1, 1:end], ex[2]'), r)

  r = hspf.cummulativeDynamicExposure[ind:end, 1:end]
  hspf.cummulativeDynamicExposure = vcat(vcat(hspf.cummulativeDynamicExposure[1:ind-1, 1:end], ex[3]'), r)
end


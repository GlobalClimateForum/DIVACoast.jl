"""
Applies a factor all dimensions of exposure (can be uexposure_growth for socio-economic development).
"""
function exposure_growth!(hspf::HypsometricProfile{DT}, factors::Array{T}) where {DT<:Real, T<:Real}
  if (size(hspf.cummulativeExposure, 2) != length(factors))
    @error "size(hspf.cummulativeExposure,2)!=length(factors) \n as $(size(hspf.cummulativeExposure,2)) != $(length(factors))"
  end

  for j in 1:(size(hspf.cummulativeExposure, 2))
    hspf.cummulativeExposure[:, j] *= factors[j]
  end
end

function exposure_growth!(hspf::HypsometricProfile{DT}, factors) where {DT<:Real}
  if (size(hspf.cummulativeExposure, 2) != length(factors))
    @error "size(hspf.cummulativeExposure,2)!=length(factors) \n as $(size(hspf.cummulativeExposure,2)) != $(length(factors))"
  end

  fac_array::Array{DT} = match_factors(hspf, factors)
  exposure_growth!(hspf, fac_array)
end

function exposure_growth!(hspf::HypsometricProfile{DT}, factor::T, s::Symbol) where {DT<:Real, T<:Real}
  p = get_position(hspf, s)
  if (p[1] == 2)
    hspf.cummulativeExposure[:, p[2]] *= factor
  end
end

exposure_growth!(hspf::HypsometricProfile{DT}, factor::T, s::String) where {DT<:Real, T<:Real} = exposure_growth!(hspf, Symbol(s))


"""
Applies socio-economic development (factor) above a certain elevation.
"""
function exposure_growth_above!(hspf::HypsometricProfile, above::Real, factors::Array{DT}) where {DT<:Real}
  if (size(hspf.cummulativeExposure, 2) != length(factors))
    @error "size(hspf.cummulativeExposure,2)!=length(factors) \n as $(size(hspf.cummulativeExposure,2)) != $(length(factors))"
  end

  if (above < hspf.elevation[1])
    exposure_growth!(hspf, factors)
    return
  end
  if (above > hspf.elevation[size(hspf.elevation, 1)])
    return
  end

  ind::Int64 = searchsortedfirst(hspf.elevation, above)

  if !(above in hspf.elevation)
    insert_elevation_point(hspf, above, ind)
  end

  for i in (ind+1):(size(hspf.cummulativeExposure, 1))
    for j in 1:(size(hspf.cummulativeExposure, 2))
      hspf.cummulativeExposure[i, j] *= factors[j]
    end
  end
end


function exposure_growth_above!(hspf::HypsometricProfile, above::Real, factors)
  if (size(hspf.cummulativeExposure, 2) != length(factors))
    @error "size(hspf.cummulativeExposure,2)!=length(factors) \n as $(size(hspf.cummulativeExposure,2)) != $(length(factors))"
  end

  fac_array::Array{DT} = match_factors(hspf, factors)
  exposure_growth_above!(hspf, above, fac_array)
end

"""
Applies socio-economic development (factor) below a certain elevation.
"""
function exposure_growth_below!(hspf::HypsometricProfile, below::Real, factors::Array{T}) where {T<:Real}
  if (size(hspf.cummulativeExposure, 2) != length(factors))
    @error "size(hspf.cummulativeExposure,2)!=length(factors) \n as $(size(hspf.cummulativeExposure,2)) != $(length(factors))"
  end

  if (below < hspf.elevation[1])
    return
  end
  if (below > hspf.elevation[size(hspf.elevation, 1)])
    exposure_growth!(hspf, factors)
    return
  end

  ind::Int64 = searchsortedfirst(hspf.elevation, below)

  if !(below in hspf.elevation)
    insert_elevation_point(hspf, below, ind)
  end

  for i in 1:ind
    for j in 1:size(hspf.cummulativeExposure, 2)
      hspf.cummulativeExposure[i, j] *= factors[j]
    end
  end

  for i in (ind+1):size(hspf.cummulativeExposure, 1)
    for j in 1:size(hspf.cummulativeExposure, 2)
      hspf.cummulativeExposure[i, j] *= hspf.cummulativeExposure[i, j] + (hspf.cummulativeExposure[ind, j] - (1 / factors[j]) * hspf.cummulativeExposure[ind, j])
    end
  end
end


function exposure_growth_below!(hspf::HypsometricProfile{DT}, below, factors) where {DT<:Real}
  if (size(hspf.cummulativeExposure, 2) != length(factors))
    @error "size(hspf.cummulativeExposure,2)!=length(factors) \n as $(size(hspf.cummulativeExposure,2)) != $(length(factors))"
  end

  fac_array::Array{DT} = match_factors(hspf, factors)
  exposure_growth_below!(hspf, below, fac_array)
end

"""
Removes expoexposure_growth assets / population below a certain elevation.
"""
function remove_exposure_below!(hspf::HypsometricProfile{DT}, below::Real)::Array{DT} where {DT<:Real}
  if (below < hspf.elevation[1])
    return (hspf.cummulativeExposure[1, :])
  end

  if (below >= hspf.elevation[size(hspf.elevation, 1)])
    removed = hspf.cummulativeExposure[size(hspf.cummulativeExposure, 1), :]

    hspf.cummulativeExposure = zeros(size(hspf.cummulativeExposure, 1), size(hspf.cummulativeExposure, 2))
    return removed
  end

  ind::Int64 = searchsortedfirst(hspf.elevation, below)

  if !(below in hspf.elevation)
    insert_elevation_point(hspf, below, ind)
  end

  removed = exposure_below_bathtub(hspf, hspf.elevation[ind])[3]

  for i in 1:ind
    for j in 1:size(hspf.cummulativeExposure, 2)
      hspf.cummulativeExposure[i, j] = 0.0f0
    end
  end

  for i in (ind+1):size(hspf.cummulativeExposure, 1)
    for j in 1:size(hspf.cummulativeExposure, 2)
      hspf.cummulativeExposure[i, j] -= removed[j]
    end
  end

  compress!(hspf)

  return removed
end


function remove_exposure_below_named!(hspf::HypsometricProfile, below::Real)
  return NamedTuple{hspf.exposureSymbols}(remove_below(hspf, below))
end

"""
Adds assets / population above a certain elevation.
"""
function add_exposure_above!(hspf::HypsometricProfile, above::Real, values::Array{T}) where {T<:Real}
  if (size(hspf.cummulativeExposure, 2) != length(values))
    logg(hspf.logger, Logging.Error, @__FILE__, String(nameof(var"#self#")), "\n size(hspf.cummulativeExposure,2)!=length(values) as size($hspf.cummulativeExposure,2)!=length($values) as $(size(hspf.cummulativeExposure,2))!=$(length(values))")
  end

  if (above > hspf.elevation[size(hspf.elevation, 1)])
    return
  end

  ind::Int64 = searchsortedfirst(hspf.elevation, above)

  if !(above in hspf.elevation)
    insert_elevation_point(hspf, above, ind)
  end

  for i in (ind+1):size(hspf.cummulativeExposure, 1)
    for j in 1:size(hspf.cummulativeExposure, 2)
      hspf.cummulativeExposure[i, j] += ((1 + i - (ind + 1)) * values[j] / (1 + size(hspf.cummulativeExposure, 1) - (ind + 1)))
    end
  end

  compress!(hspf)
end

"""
Adds assets / population between certain elevations.
"""
function add_exposure_between!(hspf::HypsometricProfile, above::Real, below::Real, values::Array{T}) where {T<:Real}
  if (below < above)
    return
  end

  ind1::Int64 = searchsortedfirst(hspf.elevation, above)
  if !(above in hspf.elevation)
    insert_elevation_point(hspf, above, ind1)
  end

  ind2::Int64 = searchsortedfirst(hspf.elevation, below)
  if !(below in hspf.elevation)
    insert_elevation_point(hspf, below, ind2)
  end

  for i in (ind1+1):ind2
    for j in 1:size(hspf.cummulativeExposure, 2)
      hspf.cummulativeExposure[i, j] += (((i - ind1) / (ind2 - ind1)) * values[j])
    end
  end

  for i in (ind2+1):size(hspf.cummulativeExposure, 1)
    for j in 1:size(hspf.cummulativeExposure, 2)
      hspf.cummulativeExposure[i, j] += values[j]
    end
  end

  compress!(hspf)
end


function match_factors(hspf::HypsometricProfile{DT}, factors)::Array{DT} where {DT<:Real}
  if (size(hspf.cummulativeExposure, 2) != length(factors))
    @error "\n size(hspf.cummulativeExposure,2)!=length(factors) as size($hspf.cummulativeExposure,2)!=length($factors) as $(size(hspf.cummulativeExposure,2))!=$(length(factors))"
  end

  fac_array::Array{DT} = fill(1.0f0, size(hspf.cummulativeExposure, 2))

  for k in keys(factors)
    for i in 1:length(hspf.exposureSymbols)
      if (k == hspf.exposureSymbols[i])
        fac_array[i] = factors[k]
      end
    end
  end

  return fac_array
end


function insert_elevation_point(hspf::HypsometricProfile{DT}, el::Real, ind::Int64) where {DT<:Real}
  ex = exposure_below_bathtub(hspf, el)
  insert!(hspf.elevation, ind, el)
  insert!(hspf.cummulativeArea, ind, ex[1])
  # probably not efficient
  r::Array{DT,2} = hspf.cummulativeStaticExposure[ind:end, 1:end]
  hspf.cummulativeStaticExposure = vcat(vcat(hspf.cummulativeStaticExposure[1:ind-1, 1:end], ex[2]'), r)

  r = hspf.cummulativeExposure[ind:end, 1:end]
  hspf.cummulativeExposure = vcat(vcat(hspf.cummulativeExposure[1:ind-1, 1:end], ex[3]'), r)
end


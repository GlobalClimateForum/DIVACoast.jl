"""
  function multiply_exposure!(hspf::HypsometricProfile{DT}, factors::Array{T}) where {DT<:Real,T<:Real}
  function multiply_exposure!(hspf::HypsometricProfile{DT}, factor::T, s::Symbol) where {DT<:Real,T<:Real}
  function multiply_exposure!(hspf::HypsometricProfile{DT}, factor::T, s::String)

  The `multiply_exposure!` function applies factors to all exposure data of a HypsometricProfile, where different factors 
  for different variables are possible. This can be used to implement soci-economic growth. Versions for single varaibles exist.

# Arguments
- `hspf::HypsometricProfile`: the hypsometric profile to modify
- factors: an array of factors, one for each variable of the profile
- factor: one factor for a specific exposure variable
- s: The name of the exposure variable to modify (apply the factor to)

# Example
```julia
function multiply_exposure!(hspf, [1.0, 1.1])
function multiply_exposure!(hspf, 1.0, :assets)
function multiply_exposure!(hspf, 1.1, "population")
```
"""
function multiply_exposure!(hspf::HypsometricProfile{DT}, factors::Array{T}) where {DT<:Real,T<:Real}
  if (size(hspf.cummulativeExposure, 2) != length(factors))
    @error "size(hspf.cummulativeExposure,2)!=length(factors) \n as $(size(hspf.cummulativeExposure,2)) != $(length(factors))"
  end

  for j in 1:(size(hspf.cummulativeExposure, 2))
    hspf.cummulativeExposure[:, j] *= factors[j]
  end
end

function multiply_exposure!(hspf::HypsometricProfile{DT}, factor::T, s::Symbol) where {DT<:Real,T<:Real}
  p = get_position(hspf, s)
  if (p[1] == 2)
    hspf.cummulativeExposure[:, p[2]] *= factor
  end
  if (p[1] == -1)
    @error "profile ($hspf) has no variable $(s)"
  end
end

multiply_exposure!(hspf::HypsometricProfile{DT}, factor::T, s::String) where {DT<:Real,T<:Real} = multiply_exposure!(hspf, Symbol(s))


"""
  function multiply_exposure_above!(hspf::HypsometricProfile{DT}, above::Real, factors::Array{T}) where {DT<:Real,T<:Real}
  function multiply_exposure_above!(hspf::HypsometricProfile{DT}, above::Real, factor::T, s::Symbol) where {DT<:Real,T<:Real}
  function multiply_exposure_above!(hspf::HypsometricProfile{DT}, above::Real, factor::T, s::String)

  The `multiply_exposure!` function applies factors to all exposure data above a given elevation of a HypsometricProfile, 
  where different factors for different variables are possible. Versions for single varaibles exist.

# Arguments
- `hspf::HypsometricProfile`: the hypsometric profile to modify
- above: the elvation, only exposure above this elevation is affected
- factors: an array of factors, one for each variable of the profile
- factor: one factor for a specific exposure variable
- s: The name of the exposure variable to modify (apply the factor to)

# Example
```julia
function multiply_exposure_above!(hspf, [1.0, 1.1])
function multiply_exposure_above!(hspf, 1.0, :assets)
function multiply_exposure_above!(hspf, 1.1, "population")
```
"""
function multiply_exposure_above!(hspf::HypsometricProfile, above::Real, factors::Array{DT}) where {DT<:Real}
  if (size(hspf.cummulativeExposure, 2) != length(factors))
    @error "size(hspf.cummulativeExposure,2)!=length(factors) \n as $(size(hspf.cummulativeExposure,2)) != $(length(factors))"
  end

  if (above < hspf.elevation[1])
    multiply_exposure!(hspf, factors)
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

function multiply_exposure_above!(hspf::HypsometricProfile, above::Real, factors::Real, s::Symbol)
  p = get_position(hspf, s)
  if (p[1] == -1)
    @error "profile ($hspf) has no variable $(s)"
  end
  if (p[1] == 2)
    if (above < hspf.elevation[1])
      multiply_exposure!(hspf, factors)
      return
    end
    if (above > hspf.elevation[size(hspf.elevation, 1)])
      return
    end

    ind::Int64 = searchsortedfirst(hspf.elevation, above)

    if !(above in hspf.elevation)
      insert_elevation_point(hspf, above, ind)
    end

    for j in 1:(size(hspf.cummulativeExposure, 2))
      hspf.cummulativeExposure[p[2], j] *= factors[j]
    end
  end
end


function multiply_exposure_above!(hspf::HypsometricProfile, above::Real, factors)
  if (size(hspf.cummulativeExposure, 2) != length(factors))
    @error "size(hspf.cummulativeExposure,2)!=length(factors) \n as $(size(hspf.cummulativeExposure,2)) != $(length(factors))"
  end

  fac_array::Array{DT} = match_factors(hspf, factors)
  multiply_exposure_above!(hspf, above, fac_array)
end



"""
Applies socio-economic development (factor) below a certain elevation.
"""
function multiply_exposure_below!(hspf::HypsometricProfile, below::Real, factors::Array{T}) where {T<:Real}
  if (size(hspf.cummulativeExposure, 2) != length(factors))
    @error "size(hspf.cummulativeExposure,2)!=length(factors) \n as $(size(hspf.cummulativeExposure,2)) != $(length(factors))"
  end

  if (below < hspf.elevation[1])
    return
  end
  if (below > hspf.elevation[size(hspf.elevation, 1)])
    multiply_exposure!(hspf, factors)
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


function multiply_exposure_below!(hspf::HypsometricProfile{DT}, below, factors) where {DT<:Real}
  if (size(hspf.cummulativeExposure, 2) != length(factors))
    @error "size(hspf.cummulativeExposure,2)!=length(factors) \n as $(size(hspf.cummulativeExposure,2)) != $(length(factors))"
  end

  fac_array::Array{DT} = match_factors(hspf, factors)
  multiply_exposure_below!(hspf, below, fac_array)
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

  removed = exposure_below(hspf, hspf.elevation[ind])[3]

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
  ex = exposure_below(hspf, el)
  insert!(hspf.elevation, ind, el)
  insert!(hspf.cummulativeArea, ind, ex[1])
  # probably not efficient
  r::Array{DT,2} = hspf.cummulativeStaticExposure[ind:end, 1:end]
  hspf.cummulativeStaticExposure = vcat(vcat(hspf.cummulativeStaticExposure[1:ind-1, 1:end], ex[2]'), r)

  r = hspf.cummulativeExposure[ind:end, 1:end]
  hspf.cummulativeExposure = vcat(vcat(hspf.cummulativeExposure[1:ind-1, 1:end], ex[3]'), r)
end


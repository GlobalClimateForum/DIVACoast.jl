"""
    function multiply_exposure!(hspf::HypsometricProfile{DT}, factors::Array{T}) where {DT<:Real,T<:Real}
    function multiply_exposure!(hspf::HypsometricProfile{DT}, factor::T, s::Symbol) where {DT<:Real,T<:Real}
    function multiply_exposure!(hspf::HypsometricProfile{DT}, factor::T, s::String)

  The `multiply_exposure!` function applies factors to all exposure data of a HypsometricProfile, where different factors 
  for different variables are possible. This can be used to implement soci-economic growth. Versions for single variables exist.

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
  if (size(hspf.cumulativeExposure, 2) != length(factors))
    @error "size(hspf.cumulativeExposure,2)!=length(factors) \n as $(size(hspf.cumulativeExposure,2)) != $(length(factors))"
  end

  for j in 1:(size(hspf.cumulativeExposure, 2))
    hspf.cumulativeExposure[:, j] *= factors[j]
  end
end

function multiply_exposure!(hspf::HypsometricProfile{DT}, named_factors::NamedTuple) where {DT<:Real}
  for field in keys(named_factors)
    factor = named_factors[field]
    multiply_exposure!(hspf, factor, field)
  end
end

function multiply_exposure!(hspf::HypsometricProfile{DT}, factor::T, s::Symbol) where {DT<:Real,T<:Real}
  p = get_position(hspf, s)
  if (p > 0)
    hspf.cumulativeExposure[:, p] *= factor
  end
  if (p == -1)
    @error "profile ($hspf) has no variable $(s)"
  end
end

multiply_exposure!(hspf::HypsometricProfile{DT}, factor::T, s::String) where {DT<:Real,T<:Real} = multiply_exposure!(hspf, factor, Symbol(s))


"""
    function multiply_exposure_above!(hspf::HypsometricProfile{DT}, above::Real, factors::Array{T}) where {DT<:Real,T<:Real}
    function multiply_exposure_above!(hspf::HypsometricProfile{DT}, above::Real, factor::T, s::Symbol) where {DT<:Real,T<:Real}
    function multiply_exposure_above!(hspf::HypsometricProfile{DT}, above::Real, factor::T, s::String)

  The `multiply_exposure_above!` function applies factors to all exposure data above a given elevation of a HypsometricProfile, 
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
  if (size(hspf.cumulativeExposure, 2) != length(factors))
    @error "size(hspf.cumulativeExposure,2)!=length(factors) \n as $(size(hspf.cumulativeExposure,2)) != $(length(factors))"
  end

  if (above < hspf.elevation[1])
    multiply_exposure!(hspf, factors)
    return
  end
  if (above > hspf.elevation[size(hspf.elevation, 1)])
    return
  end

  ind::Int64 = searchsortedfirst(hspf.elevation, above)
  insert_elevation_point(hspf, above, ind)

  for j in 1:(size(hspf.cumulativeExposure, 2))
    sum = 0
    for i in (ind+1):(size(hspf.cumulativeExposure, 1))
      step = (hspf.cumulativeExposure[i, j] - sum - hspf.cumulativeExposure[i-1, j])
      step_mult = step * factors[j]
      sum += (step - step_mult)
      hspf.cumulativeExposure[i, j] = hspf.cumulativeExposure[i-1, j] + step_mult
    end
  end
end

function multiply_exposure_above!(hspf::HypsometricProfile{DT}, above::Real, factors) where {DT<:Real}
  if (size(hspf.cumulativeExposure, 2) != length(factors))
    @error "size(hspf.cumulativeExposure,2)!=length(factors) \n as $(size(hspf.cumulativeExposure,2)) != $(length(factors))"
  end

  fac_array::Array{DT} = match_factors(hspf, factors)
  multiply_exposure_above!(hspf, above, fac_array)
end

function multiply_exposure_above!(hspf::HypsometricProfile, above::Real, s::String, factor::Real)
  p = get_position(hspf, s)
  if (p == -1)
    @error "profile ($hspf) has no variable $(s)"
  end

  if p > 0
    factors = ones(size(hspf.cumulativeExposure, 2))
    factors[p] = factor
    multiply_exposure_above!(hspf, above, factors)
  end
end

multiply_exposure_above!(hspf::HypsometricProfile{DT}, above::Real, s::Symbol, factor::T) where {DT<:Real,T<:Real} = multiply_exposure_above!(hspf, above, String(s), factor)



"""
    function multiply_exposure_below!(hspf::HypsometricProfile{DT}, below::Real, factors::Array{T}) where {DT<:Real,T<:Real}
    function multiply_exposure_below!(hspf::HypsometricProfile{DT}, below::Real, factor::T, s::Symbol) where {DT<:Real,T<:Real}
    function multiply_exposure_below!(hspf::HypsometricProfile{DT}, below::Real, factor::T, s::String)

  The `multiply_exposure_below!` function applies factors to all exposure data below a given elevation of a HypsometricProfile, 
  where different factors for different variables are possible. Versions for single varaibles exist.

# Arguments
- `hspf::HypsometricProfile`: the hypsometric profile to modify
- below: the elvation, only exposure above this elevation is affected
- factors: an array of factors, one for each variable of the profile
- factor: one factor for a specific exposure variable
- s: The name of the exposure variable to modify (apply the factor to)

# Example
```julia
function multiply_exposure_below!(hspf, 2.0, [1.0, 1.1])
function multiply_exposure_below!(hspf, 2.0, 1.0, :assets)
function multiply_exposure_below!(hspf, 2.0, 1.1, "population")
```
"""
function multiply_exposure_below!(hspf::HypsometricProfile, below::Real, factors::Array{T}) where {T<:Real}
  if (size(hspf.cumulativeExposure, 2) != length(factors))
    @error "size(hspf.cumulativeExposure,2)!=length(factors) \n as $(size(hspf.cumulativeExposure,2)) != $(length(factors))"
  end

  if (below < hspf.elevation[1])
    return
  end
  if (below > hspf.elevation[size(hspf.elevation, 1)])
    multiply_exposure!(hspf, factors)
    return
  end

  ind::Int64 = searchsortedfirst(hspf.elevation, below)
  insert_elevation_point(hspf, below, ind)

  before = hspf.cumulativeExposure[ind, :]
  for i in 1:ind
    for j in 1:size(hspf.cumulativeExposure, 2)
      hspf.cumulativeExposure[i, j] *= factors[j]
    end
  end
  after = hspf.cumulativeExposure[ind, :]

  for i in (ind+1):size(hspf.cumulativeExposure, 1)
    hspf.cumulativeExposure[i, :] += (after - before)
  end
end

function multiply_exposure_below!(hspf::HypsometricProfile, below::Real, factor::Real, s::Symbol)
  p = get_position(hspf, s)
  if (p[1] == -1)
    @error "profile ($hspf) has no variable $(s)"
  end
  if (p[1] == 2)
    if (below < hspf.elevation[1])
      return
    end
    if (below > hspf.elevation[size(hspf.elevation, 1)])
      multiply_exposure!(hspf, factor)
      return
    end

    ind::Int64 = searchsortedfirst(hspf.elevation, below)

    if !(below in hspf.elevation)
      insert_elevation_point(hspf, below, ind)
    end

    for i in 1:ind
      hspf.cumulativeExposure[i, p[2]] *= factor
    end
  end
end

function multiply_exposure_below!(hspf::HypsometricProfile{DT}, below, factors) where {DT<:Real}
  if (size(hspf.cumulativeExposure, 2) != length(factors))
    @error "size(hspf.cumulativeExposure,2)!=length(factors) \n as $(size(hspf.cumulativeExposure,2)) != $(length(factors))"
  end

  fac_array::Array{DT} = match_factors(hspf, factors)
  multiply_exposure_below!(hspf, below, fac_array)
end

function multiply_exposure_below!(hspf::HypsometricProfile, below::Real, s::String, factor::Real)
  p = get_position(hspf, s)
  if (p == -1)
    @error "profile ($hspf) has no variable $(s)"
  end

  if p > 0
    factors = ones(size(hspf.cumulativeExposure, 2))
    factors[p] = factor
    multiply_exposure_below!(hspf, below, factors)
  end
end

multiply_exposure_below!(hspf::HypsometricProfile{DT}, below::Real, s::Symbol, factor::T) where {DT<:Real,T<:Real} = multiply_exposure_below!(hspf, below, String(s), factor)




"""
    function remove_exposure_below!(hspf::HypsometricProfile{DT}, below::Real) where {DT<:Real}

  The `remove_exposure_below!` function removes exposure (assets and population) below a certain elevation.

# Arguments
- `hspf::HypsometricProfile`: the hypsometric profile to modify
- below: the elvation, only exposure below this elevation is removed

# Example
```julia
function remove_exposure_below!(hspf, 2.0)
```
"""
function remove_exposure_below!(hspf::HypsometricProfile{DT}, below::Real)::Array{DT} where {DT<:Real}
  if (below < hspf.elevation[1])
    return (hspf.cumulativeExposure[1, :])
  end

  if (below >= hspf.elevation[size(hspf.elevation, 1)])
    removed = hspf.cumulativeExposure[size(hspf.cumulativeExposure, 1), :]

    hspf.cumulativeExposure = zeros(size(hspf.cumulativeExposure, 1), size(hspf.cumulativeExposure, 2))
    return removed
  end

  ind::Int64 = searchsortedfirst(hspf.elevation, below)
  insert_elevation_point(hspf, below, ind)

  removed = exposure(hspf, hspf.elevation[ind])[2]

  for i in 1:ind
    for j in 1:size(hspf.cumulativeExposure, 2)
      hspf.cumulativeExposure[i, j] = 0.0f0
    end
  end

  for i in (ind+1):size(hspf.cumulativeExposure, 1)
    for j in 1:size(hspf.cumulativeExposure, 2)
      hspf.cumulativeExposure[i, j] -= removed[j]
    end
  end

  compress!(hspf)

  return removed
end

function remove_exposure_below_named!(hspf::HypsometricProfile, below::Real)
  return NamedTuple{map(x -> Symbol(x), hspf.exposureNames)}(remove_below(hspf, below))
end

"""
    function add_exposure_above!(hspf::HypsometricProfile{DT}, above::Real, values::Array{T}) where {T<:Real}

  The `add_exposure_above!` function adds exposure (assets / population) above a certain elevation.

# Arguments
- `hspf::HypsometricProfile`: the hypsometric profile to modify
- above: the elvation, exposure gets only added above this elevation
- values: the exposure values that get added

# Example
```julia
function add_exposure_above!(hspf, 2.0, [1000, 250000])
```
"""
function add_exposure_above!(hspf::HypsometricProfile, above::Real, values::Array{T}) where {T<:Real}
  if (size(hspf.cumulativeExposure, 2) != length(values))
    logg(hspf.logger, Logging.Error, @__FILE__, String(nameof(var"#self#")), "\n size(hspf.cumulativeExposure,2)!=length(values) as size($hspf.cumulativeExposure,2)!=length($values) as $(size(hspf.cumulativeExposure,2))!=$(length(values))")
  end

  if (above > hspf.elevation[size(hspf.elevation, 1)])
    return
  end

  ind::Int64 = searchsortedfirst(hspf.elevation, above)

  if !(above in hspf.elevation)
    insert_elevation_point(hspf, above, ind)
  end

  for i in (ind+1):size(hspf.cumulativeExposure, 1)
    for j in 1:size(hspf.cumulativeExposure, 2)
      hspf.cumulativeExposure[i, j] += ((1 + i - (ind + 1)) * values[j] / (1 + size(hspf.cumulativeExposure, 1) - (ind + 1)))
    end
  end

  #i think the adding part is missing here, compared to function below?

  compress!(hspf)
end

"""
    function add_exposure_between!(hspf::HypsometricProfile{DT}, above::Real, below::Real, values::Array{T}) where {T<:Real}

  The `add_exposure_between!` function adds assets / population between certain elevations.

# Arguments
- `hspf::HypsometricProfile`: the hypsometric profile to modify
- above: the elvation, exposure gets only added above this elevation
- below: the elvation, exposure gets only added below this elevation
- values: the exposure values that get added

# Example
```julia
function add_exposure_between!(hspf, 2.0, 3.0, [1000, 250000])
```
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
    for j in 1:size(hspf.cumulativeExposure, 2)
      hspf.cumulativeExposure[i, j] += (((i - ind1) / (ind2 - ind1)) * values[j])
    end
  end

  for i in (ind2+1):size(hspf.cumulativeExposure, 1)
    for j in 1:size(hspf.cumulativeExposure, 2)
      hspf.cumulativeExposure[i, j] += values[j]
    end
  end

  compress!(hspf)
end


function match_factors(hspf::HypsometricProfile{DT}, factors)::Array{DT} where {DT<:Real}
  if (size(hspf.cumulativeExposure, 2) != length(factors))
    @error "\n size(hspf.cumulativeExposure,2)!=length(factors) as size($hspf.cumulativeExposure,2)!=length($factors) as $(size(hspf.cumulativeExposure,2))!=$(length(factors))"
  end

  fac_array::Array{DT} = fill(1.0f0, size(hspf.cumulativeExposure, 2))

  for k in keys(factors)
    for i in 1:length(hspf.exposureNames)
      if (String(k) == hspf.exposureNames[i])
        fac_array[i] = factors[k]
      end
    end
  end

  return fac_array
end

function insert_elevation_point(hspf::HypsometricProfile{DT}, el::Real, ind::Int) where {DT<:Real}
  if hspf.elevation[ind] != el
    if (ind == 1)
      insert!(hspf.elevation, ind, el)
      insert!(hspf.cumulativeArea, ind, 0)
      hspf.cumulativeExposure = vcat(zeros(size(hspf.exposureNames, 1))', hspf.cumulativeExposure)
    elseif (ind > size(hspf.elevation, 1))
      push!(hspf.elevation, el)
      push!(hspf.cumulativeArea, hspf.cumulativeArea[size(hspf.cumulativeArea, 1)])
      hspf.cumulativeExposure = vcat(hspf.cumulativeExposure, hspf.cumulativeExposure[size(hspf.cumulativeExposure, 1), :]')
    else
      #println("case3!")
      #println(ind - 1, " el: ", hspf.elevation[ind-1], " area: ", hspf.cumulativeArea[ind-1])
      #println(ind, " el: ", hspf.elevation[ind], " area: ", hspf.cumulativeArea[ind])
      #println(ind + 1, " el: ", hspf.elevation[ind+1], " area: ", hspf.cumulativeArea[ind+1])
      #println(ind + 2, " el: ", hspf.elevation[ind+2], " area: ", hspf.cumulativeArea[ind+2])
      r = (el - hspf.elevation[ind-1]) / (hspf.elevation[ind] - hspf.elevation[ind-1])
      insert!(hspf.elevation, ind, el)
      a = hspf.cumulativeArea[ind-1] + r * (hspf.cumulativeArea[ind] - hspf.cumulativeArea[ind-1])
      insert!(hspf.cumulativeArea, ind, a)
      #println(r)

      expo = hspf.cumulativeExposure[ind-1, :] + r * (hspf.cumulativeExposure[ind, :] - hspf.cumulativeExposure[ind-1, :])
      hspf.cumulativeExposure = vcat(vcat(hspf.cumulativeExposure[1:(ind-1), 1:end], expo'), hspf.cumulativeExposure[ind:end, 1:end])

    end
  end
end

function insert_elevation_point(hspf::HypsometricProfile{DT}, el::Real) where {DT<:Real}
  ind::Int64 = searchsortedfirst(hspf.elevation, el)
  insert_elevation_point(hspf, el, ind)
end


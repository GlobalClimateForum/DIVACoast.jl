"""
    exposure(hspf::HypsometricProfile{DT}, wl::Real, im::IM) where {DT<:Real, IM<:InundationModel}
    exposure(hspf::HypsometricProfile{DT}, wl::Real, s::Symbol, im::IM) where {DT<:Real, IM<:InundationModel}

Calculate the cumulative area, static exposure, and dynamic exposure below elevation (`e`) for a hypsometric profile. The function handles different cases based on the elevation's presence in the profile and its position.
# Arguments
`hspf::HypsometricProfile{DT}`: The hypsometric profile with elevation, area and exposure data.
`e::Real`: The elevation threshold for which exposure is calculated (everything underneath this elevation).
`im::IM`: the inundationmodel used to .


# Returns
Exposed area and exposure for elevations smaller than `e`.

  # Example
```julia
function exposure(hspf, 2.0, BathtubInundation())
function exposure(hspf, 100, "population", BathtubInundation())
```

"""
function exposure(hspf::HypsometricProfile{DT}, wl::Number, im::IM=BathtubInundation()) where {DT<:Real,IM<:InundationModel}
  water_levels = inundate(hspf, wl, im)

  max_water_level = last(water_levels[2])
  ind::Int64 = searchsortedfirst(hspf.elevation, max_water_level)

  if (max_water_level in hspf.elevation)
    @inbounds ea = hspf.cumulativeArea[ind]
    @inbounds eo = (size(hspf.cumulativeExposure, 1) > 0) ? hspf.cumulativeExposure[ind, :] : Array{DT}(undef, 0)
    return (ea, eo)
  else
    if (ind == 1)
      @inbounds ea = hspf.cumulativeArea[ind]
      @inbounds eo = (size(hspf.cumulativeExposure, 1) > 0) ? hspf.cumulativeExposure[ind, :] : Array{DT}(undef, 0)
      return (ea, eo)
    end
    if (ind > size(hspf.elevation, 1))
      @inbounds ea = hspf.cumulativeArea[size(hspf.elevation, 1)]
      @inbounds eo = (size(hspf.cumulativeExposure, 1) > 0) ? hspf.cumulativeExposure[size(hspf.elevation, 1), :] : Array{DT}(undef, 0)
      return (ea, eo)
    end
    @inbounds r = (max_water_level - hspf.elevation[ind-1]) / (hspf.elevation[ind] - hspf.elevation[ind-1])
    @inbounds ea = convert(DT, hspf.cumulativeArea[ind-1] + ((hspf.cumulativeArea[ind] - hspf.cumulativeArea[ind-1]) * r))
    @inbounds eo = convert(Array{DT}, (size(hspf.cumulativeExposure, 1) > 0) ? hspf.cumulativeExposure[ind-1, :] + ((hspf.cumulativeExposure[ind, :] - hspf.cumulativeExposure[ind-1, :]) * r) : Array{DT}(undef, 0))
    return (ea, eo)
  end

end

function exposure(hspf::HypsometricProfile{DT}, wl::Real, inds::Array{Int}, im::IM=BathtubInundation()) where {DT<:Real,IM<:InundationModel}
  exposure = zeros(DT, size(hspf.elevation, 1), size(inds, 1))
  for i in 1:size(inds, 1)
    if (inds[i] == 0)
      exposure[:, i] = hspf.cumulativeArea
    end
    if (inds[i] > 0)
      exposure[:, i] = hspf.cumulativeExposure[:, inds[i]]
    end
  end

  water_levels = inundate(hspf, wl, im)
  max_water_level = last(water_levels[2])
  ind::Int64 = searchsortedfirst(hspf.elevation, max_water_level)

  if (max_water_level in hspf.elevation)
    @inbounds e = exposure[ind, :]
    return e
  else
    if (ind == 1)
      @inbounds e = exposure[ind, :]
      return e
    end
    if (ind > size(hspf.elevation, 1))
      e = exposure[size(hspf.elevation, 1), :]
      return e
    end
    @inbounds r = (max_water_level - hspf.elevation[ind-1]) / (hspf.elevation[ind] - hspf.elevation[ind-1])
    @inbounds e = convert(Array{DT}, exposure[ind-1, :] + (exposure[ind, :] - exposure[ind-1, :]) * r)
    return e
  end
end

exposure(hspf::HypsometricProfile{DT}, wl::Real, s::Array{Symbol}, im::IM=BathtubInundation()) where {DT<:Real,IM<:InundationModel} = exposure(hspf, wl, map(x -> String(x), s), im)
exposure(hspf::HypsometricProfile{DT}, wl::Real, s::Symbol, im::IM=BathtubInundation()) where {DT<:Real,IM<:InundationModel} = exposure(hspf, wl, [String(s)], im)[1]
exposure(hspf::HypsometricProfile{DT}, wl::Real, s::String, im::IM=BathtubInundation()) where {DT<:Real,IM<:InundationModel} = exposure(hspf, wl, [s], im)
exposure(hspf::HypsometricProfile{DT}, wl::Real, s::Array{String}, im::IM=BathtubInundation()) where {DT<:Real,IM<:InundationModel} = exposure(hspf, wl, map(x -> get_position(hspf, x), s), im)



"""
    function named(f::F, args::Tuple) where {F<:Union{typeof(exposure)}}

Named returns the results of the function `f` as named tuple. Currently `named()` is only 
implemented for the function `exposure()`.

# Arguments
- `f::F`: The function to be called.
- `args::Tuple`: The arguments to be passed to the function. **Note**: Arguments must be passed in right order.

# Returns
A named tuple with the results of the function `f`.

# Example
```julia
named(exposure, (hspf, 5, BathtubInundation()))
```
"""
function named(f::F, args::Tuple) where {F<:Union{typeof(exposure)}}
  t = f(args...)
  if isa(f, typeof(exposure))
    hspf, _ = args
    exposures  = [Symbol(expKey_) => expVal for (expKey_, expVal) in zip(hspf.exposureNames, t[2])]
    return @inbounds (; cumulativeArea = t[1], exposures...)
  elseif not isa(f, typeof(exposure))
    @warn "No named version available for $(f) returned unnamed results instead"
    @inbounds return t
  end
end
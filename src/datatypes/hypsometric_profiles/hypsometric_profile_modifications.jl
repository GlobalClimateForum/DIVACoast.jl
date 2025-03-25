"""
    function add_static_exposure!(hspf::HypsometricProfile, elevation::Array{DT}, 
    s_exposure::Array{DT}, s_exposure_name::String, s_exposure_units::String) 
    where {DT<:Real}

The `add_static_exposure!` function adds static exposure to a HypsometricProfile. Exposure values to add are provided using the `s_exposure` parameter. Corresponding elevation
increments need to be provided using the `elevation` parameter. The `s_exposure_name` and `s_exposure_units` parameters are used to name the exposure and provide units for the exposure values.
The function harmonizes the elevation increments within the HypsometricProfile and the provided elevation increments. The function also compresses the HypsometricProfile

# Arguments
- `hspf::HypsometricProfile`: The hypsometric profile object to which the exposure data will be added.
- `elevation::Array{DT}`: The elevation increments that the `hspf.elevation` will be resampled to.
- `s_exposure::Array{DT}`: The static exposure values to be added to the profile.
- `s_exposure_name::String`: The name to be associated with the static exposure data.
- `s_exposure_units::String`: The units of the static exposure data.

# Example
```julia
add_static_exposure!(hspf, [0.0, 1.0, 2.0, 3.0], [0.0, 3000, 5000, 2000], "agriculture", "m²")
```
"""
function add_static_exposure!(hspf::HypsometricProfile, elevation::Array{DT}, s_exposure::Array{DT}, s_exposure_name::String, s_exposure_units::String) where {DT<:Real}
  # resample hspf.elevation to elevation 
  resample!(hspf, elevation) 

  if (length(hspf.elevation) != size(s_exposure, 1))
    logg(hspf.logger, Logging.Error, @__FILE__, "", "\n length(hspf.elevation) != size(s_exposure,1) as length($(hspf.elevation)) != size($s_exposure,1) as $(length(hspf.elevation)) != $(size(s_exposure,1))")
  end

  if (values(s_exposure[1]) != 0)
    logg(hspf.logger, Logging.Error, @__FILE__, String(nameof(var"#self#")), "\n s_exposure first column should be zero, but its not: $s_exposure")
  end

  hspf.staticExposureSymbols = (hspf.staticExposureSymbols...,Symbol(s_exposure_name))
  push!(hspf.staticExposureUnits, s_exposure_units)
  hspf.cummulativeStaticExposure = hcat(hspf.cummulativeStaticExposure, cumsum(s_exposure))

  compress!(hspf)
end

"""
    function add_dynamic_exposure!(hspf::HypsometricProfile, elevation::Array{DT},
    d_exposure::Array{DT}, d_exposure_name::String, d_exposure_units::String) 
    where {DT<:Real}

The `add_dynamic_exposure!` function adds dynamic exposure to a HypsometricProfile. Exposure values to add are provided using the `s_exposure` parameter. Corresponding elevation
increments need to be provided using the `elevation` parameter. The `s_exposure_name` and `s_exposure_units` parameters are used to name the exposure and provide units for the exposure values.
The function harmonizes the elevation increments within the HypsometricProfile and the provided elevation increments. The function also compresses the HypsometricProfile

# Arguments
- `hspf::HypsometricProfile`: The hypsometric profile object to which the exposure data will be added.
- `elevation::Array{DT}`: The elevation increments that the `hspf.elevation` will be resampled to.
- `d_exposure::Array{DT}`: The static exposure values to be added to the profile.
- `d_exposure_name::String`: The name to be associated with the static exposure data.
- `d_exposure_units::String`: The units of the static exposure data.

# Example
```julia
add_dynamic_exposure!(hspf, [0.0, 1.0, 2.0, 3.0], [0.0, 3000, 5000, 2000], "population", "individuals")
```
"""
function add_dynamic_exposure!(hspf::HypsometricProfile, elevation::Array{DT}, d_exposure::Array{DT}, d_exposure_name::String, d_exposure_units::String) where {DT<:Real}
  resample!(hspf, elevation) 

  if (length(hspf.elevation) != size(d_exposure, 1))
    logg(hspf.logger, Logging.Error, @__FILE__, "", "\n length(hspf.elevation) != size(d_exposure,1) as length($(hspf.elevation)) != size($d_exposure,1) as $(length(hspf.elevation)) != $(size(d_exposure,1))")
  end

  if (values(d_exposure[1]) != 0)
    logg(hspf.logger, Logging.Error, @__FILE__, String(nameof(var"#self#")), "\n d_exposure first column should be zero, but its not: $d_exposure")
  end

  hspf.dynamicExposureSymbols = (hspf.dynamicExposureSymbols...,Symbol(d_exposure_name))
  push!(hspf.dynamicExposureUnits, d_exposure_units)
  hspf.cummulativeDynamicExposure = hcat(hspf.cummulativeDynamicExposure, cumsum(d_exposure))

  compress!(hspf)
end

"""
Removes static exposure from a HypsometricProfile
"""
function remove_static_exposure!(hspf::HypsometricProfile, ind :: Integer)
  if (1<=ind && ind<=size(hspf.staticExposureUnits,1))
    hspf.staticExposureSymbols = (hspf.staticExposureSymbols[1:ind-1]...,hspf.staticExposureSymbols[ind+1:size(hspf.staticExposureUnits,1)]...)
    deleteat!(hspf.staticExposureUnits,ind)
    hspf.cummulativeStaticExposure = hspf.cummulativeStaticExposure[:, 1:end .!= ind]
  end
end

"""
Removes dynamic exposure from a HypsometricProfile
"""
function remove_dynamic_exposure!(hspf::HypsometricProfile, ind :: Integer)
  if (1<=ind && ind<=size(hspf.dynamicExposureUnits,1))
    hspf.dynamicExposureSymbols = (hspf.dynamicExposureSymbols[1:ind-1]...,hspf.dynamicExposureSymbols[ind+1:size(hspf.dynamicExposureUnits,1)]...)
    deleteat!(hspf.dynamicExposureUnits,ind)
    hspf.cummulativeDynamicExposure = hspf.cummulativeDynamicExposure[:, 1:end .!= ind]
  end
end
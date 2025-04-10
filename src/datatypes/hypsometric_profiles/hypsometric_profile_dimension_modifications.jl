"""
    function add_exposure_dimension!(hspf::HypsometricProfile, elevation::Array{DT},
    exposure_data::Array{DT}, exposure_name::String, exposure_units::String) 
    where {DT<:Real}

The `add_exposure_dimension!` function adds a complete exposure dimension to a HypsometricProfile. Exposure values to add are provided using the `exposure_data` parameter. Corresponding elevation
increments need to be provided using the `elevation` parameter. The `exposure_name` and `exposure_units` parameters are used to name the exposure and provide units for the exposure values.
The function harmonizes the elevation increments within the HypsometricProfile and the provided elevation increments. The function also compresses the HypsometricProfile

# Arguments
- `hspf::HypsometricProfile`: The hypsometric profile object to which the exposure data will be added.
- `elevation::Array{DT}`: The elevation increments that the `hspf.elevation` will be resampled to.
- `exposure_data::Array{DT}`: The exposure values to be added to the profile.
- `exposure_name::String`: The name to be associated with the exposure data.
- `exposure_units::String`: The units of the exposure data.

# Example
```julia
add_exposure_dimension!(hspf, [0.0, 1.0, 2.0, 3.0], [0.0, 3000, 5000, 2000], "population", "individuals")
```
"""
function add_exposure_dimension!(hspf::HypsometricProfile, elevation::Array{DT}, exposure_data::Array{DT}, exposure_name::String, exposure_unit::String) where {DT<:Real}
  resample!(hspf, elevation)

  if (length(hspf.elevation) != size(exposure_data, 1))
    logg(hspf.logger, Logging.Error, @__FILE__, "", "\n length(hspf.elevation) != size(exposure_data) as length($(hspf.elevation)) != size($exposure_data,1) as $(length(hspf.elevation)) != $(size(exposure_data,1))")
  end

  if (values(exposure_data[1]) != 0)
    logg(hspf.logger, Logging.Error, @__FILE__, String(nameof(var"#self#")), "\n exposure_data first column should be zero, but its not: $exposure_data")
  end

  hspf.exposureSymbols = (hspf.exposureSymbols..., Symbol(exposure_name))
  push!(hspf.exposureUnits, exposure_unit)
  hspf.cummulativeExposure = hcat(hspf.cummulativeExposure, cumsum(exposure_data))

  compress!(hspf)
end


"""
    function remove_exposure_dimension!(hspf::HypsometricProfile, ind :: Integer)
    function remove_exposure_dimension!(hspf::HypsometricProfile, s: Symbol)
    function remove_exposure_dimension!(hspf::HypsometricProfile, s: String)

Function removes a complete exposure dimension from a HypsometricProfile at the index `ind`, or with name :s 
or s. The function removes the exposure data, the exposure name and the exposure units from the HypsometricProfile.

# Arguments
- `hspf::HypsometricProfile`: The hypsometric profile object from which the exposure data will be removed.
- `ind::Integer`: The index of the exposure data to be removed.
- `ind::Integer`: The index of the exposure data to be removed.
- `ind::Integer`: The index of the exposure data to be removed.

# Examples
```julia
remove_exposure_dimension!(hspf, 1)
remove_exposure_dimension!(hspf, :population)
```
"""
function remove_exposure_dimension!(hspf::HypsometricProfile, ind::Integer)
  if (1 <= ind && ind <= size(hspf.exposureUnits, 1))
    hspf.exposureSymbols = (hspf.exposureSymbols[1:ind-1]..., hspf.exposureSymbols[ind+1:size(hspf.exposureUnits, 1)]...)
    deleteat!(hspf.exposureUnits, ind)
    hspf.cummulativeExposure = hspf.cummulativeExposure[:, 1:end.!=ind]
  end
end

function remove_exposure_dimension!(hspf::HypsometricProfile, s::Symbol)
  p = get_position(hspf, s)
  if (p[1] == 2)
    remove_exposure_dimension!(hspf, p[2])
  end
end
remove_exposure_dimension!(hspf::HypsometricProfile, s::String) = remove_exposure_dimension!(hspf, Symbol(n))


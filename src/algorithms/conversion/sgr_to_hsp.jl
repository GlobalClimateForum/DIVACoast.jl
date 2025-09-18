export to_hypsometric_profile, to_hypsometric_profiles,
  attach_to_hypsometric_profiles!, attach_exposure_variable_to_hypsometric_profiles!,
  attach_exposure_variables_to_hypsometric_profiles!

"""
    function to_hypsometric_profile(ga::GeoArray, width::Real, min_elevation::Real, max_elevation::Real, elevation_incr::Real)::HypsometricProfile where {DT<:Real,IT<:Integer,DT2<:Real}

Function converts a `GeoArray` object to a `HypsometricProfile` object. The function calculates the area of each elevation increment and stores it in the `HypsometricProfile` object. Elevation
increments are calculated between a `min_elevation` and a `max_elevation` with a desired eleveation increment: `elevation_incr`. The function returns the `HypsometricProfile` object.

# Arguments
- `ga::GeoArray`: The `GeoArray` object to be converted.
- `width::DT2`: The width of the hypsometric profile.
- `min_elevation::DT2`: The minimum elevation of the hypsometric profile to be considered.
- `max_elevation::DT2`: The maximum elevation of the hypsometric profile to be considered.
- `elevation_incr::DT2`: Desired elevation increment.

# Returns
- `HypsometricProfile`: The hypsometric profile object.

# Example
```julia
to_hypsometric_profile(ga, 1.0, -2.0, 20.0, 5.0)
```
"""

function to_hypsometric_profile(ga::GeoArray{E,N,C}, width::Real, min_elevation::Real, max_elevation::Real, elevation_incr::Real)::HypsometricProfile where {E,N,C}
  s = floor(Int, ((max_elevation - min_elevation) / elevation_incr))
  a::Array{E} = zeros(s)
  e = Array{E}(undef, s)
  for i in 1:s
    e[i] = min_elevation + i * elevation_incr
  end

  for (indices, elevation) in GeoArrayIndexValueIterator(ga_elevation)
    if elevation <= e[1]
      a[1] += area(ga, indices)
    else
      i = floor(Int, (elevation - min_elevation) / elevation_incr) + 1
      if (i <= size(e, 1))
        a[i] += area(ga, indices)
      end
    end
  end

  i = 1
  while (i <= (size(e, 1) - 1))
    if (a[i] == 0 && a[i+1] == 0)
      deleteat!(e, i)
      deleteat!(a, i)
    else
      i += 1
    end
  end

  return HypsometricProfile(w, pushfirst!(e, min_elevation), pushfirst!(a, 0), a[:, :])
end

"""
    function to_hypsometric_profile(ga_elevation::GeoArray, area_unit::String, gas_exp::Array{GeoArray}, exp_names::Array{String}, exp_units::Array{String}, width::DT2, width_unit::String, min_elevation::DT2, max_elevation::DT2, elevation_incr::DT2, elevation_unit::String)

Creates a `HypsometricProfile` object from a `GeoArray` object containing elevation data. 
It also calculates associated area affected and static/dynamic exposure at each elevation increment. The function returns the `HypsometricProfile` object.

# Arguments
- `ga_elevation::GeoArray`: The `GeoArray` object containing elevation data.
- `area_unit::String`: The unit of the area.
- `gas_exp::Array{GeoArray}`: The `GeoArray` objects containing dynamic exposure data.
- `exp_names::Array{String}`: The names of the dynamic exposure data.
- `exp_units::Array{String}`: The units of the dynamic exposure data.
- `width::DT2`: The width of the hypsometric profile.
- `width_unit::String`: The unit of the width.
- `min_elevation::DT2`: The minimum elevation of the hypsometric profile to be considered.
- `max_elevation::DT2`: The maximum elevation of the hypsometric profile to be considered.
- `elevation_incr::DT2`: Desired elevation increment.
- `elevation_unit::String`: The unit of the elevation.

# Returns
- `HypsometricProfile`: The hypsometric profile object.

# Example
```julia
to_hypsometric_profile(ga_elevation, "m²", gas_exp, ["population", "assets"], ["individuals", "USD"], 1.0, "m", -2.0, 20.0, 5.0, "m")
```
"""
function to_hypsometric_profile(ga_elevation::GeoArray, area_unit::String,
  gas_exposure::Array{GeoArray}, exposure_names::Array{String}, exposure_units::Array{String},
  width::DT, width_unit::String, min_elevation::DT, max_elevation::DT, elevation_incr::DT, elevation_unit::String)::HypsometricProfile where {DT<:Real}
  # ToDo:: check if all dimensions match.

  s = floor(Int, ((max_elevation - min_elevation) / elevation_incr))
  a::Array{DT} = zeros(s)
  e = Array{DT}(undef, s)
  for i in 1:s
    e[i] = min_elevation + i * elevation_incr
  end

  exposure_tmp::Array{DT} = zeros(s, size(gas_exposure, 1))

  for (indices, elevation) in GeoArrayIndexValueIterator(ga_elevation)
    if elevation <= e[1]
      a[1] += area(ga_elevation, indices)
      for j in 1:size(gas_exposure, 1)
        if (gas_exposure[j][indices[1], indices[2]]) != no_data_value(gas_exposure[j])
          exposure_tmp[1, j] += gas_exposure[j][indices[1], indices[2]]
        end
      end
    else
      i = floor(Int, (elevation - min_elevation) / elevation_incr) + 1
      if (i <= length(e))
        a[i] += area(ga_elevation, indices)
        for j in 1:size(gas_exposure, 1)
          if (gas_exposure[j][indices[1], indices[2]]) != no_data_value(gas_exposure[j])
            exposure_tmp[i, j] += gas_exposure[j][indices[1], indices[2]]
          end
        end
      end
    end
  end

  i = 1
  while (i <= (length(e) - 1))
    if (a[i] == 0 && a[i+1] == 0)
      deleteat!(e, i)
      deleteat!(a, i)
      # this might be memory inefficient.
      exposure_tmp = exposure_tmp[1:end.!=i, 1:end]
    else
      i += 1
    end
  end

  z_exposure::Array{DT} = zeros(size(gas_exposure, 1))

  return HypsometricProfile(width, width_unit, pushfirst!(e, min_elevation), elevation_unit, pushfirst!(a, 0), area_unit, [z_exposure'; exposure_tmp], exposure_names, exposure_units)
end

function to_hypsometric_profile(gas_elevation::Dict{IT,GeoArray{E,N,C}}, area_unit::String,
  gas_exp::Array{Dict{IT,GeoArray{E,N,C}}}, exp_names::Array{String}, exp_units::Array{String},
  widths::Dict{IT2,DT2}, width_unit::String, min_elevation::DT, max_elevation::DT, elevation_incr::DT, elevation_unit::String)::Dict{IT,HypsometricProfile} where {E,N,C<:AbstractArray,DT<:Real,IT<:Integer,DT2<:Real,IT2<:Integer}

  ret::Dict{IT,HypsometricProfile{DT}} = Dict{IT2,HypsometricProfile{DT}}()
  exp_arrays = Array{GeoArray}(undef, size(gas_exp, 1))

  print("construction progress: 0 ")
  p = 0
  counter = 0

  length(gas_elevation)

  # VERY memory inefficient
  for (index, elevation_data) in gas_elevation
    counter = counter + 1
    if ((counter * 100 ÷ length(gas_elevation)) ÷ 10) > p
      p = (counter * 100 ÷ length(gas_elevation)) ÷ 10
      print("$(p*10) ")
    end

    for j in 1:size(gas_exp, 1)
      if (haskey(gas_exp[j], index))
        exp_arrays[j] = gas_exp[j][index]
      else
        exp_arrays[j] = empty_copy_from_geo_array(gas_elevation[index])
      end
    end
    ret[index] = to_hypsometric_profile(elevation_data, area_unit, exp_arrays, exp_names, exp_units, convert(DT, widths[index]), width_unit, min_elevation, max_elevation, elevation_incr, elevation_unit)
  end
  println()
  return ret
end

function to_hypsometric_profile(e::Array{DT}, a::Array{DT}, area_unit::String,
  exposure_data::Array{DT,2}, exposure_names::Array{String}, exposure_units::Array{String},
  width::DT, width_unit::String, min_elevation::DT, max_elevation::DT, elevation_incr::DT, elevation_unit::String)::HypsometricProfile where {DT<:Real}
  i = 1
  while (i <= (length(e) - 1))
    if (a[i] == 0 && a[i+1] == 0)
      deleteat!(e, i)
      deleteat!(a, i)
      exposure_data = exposure_data[1:end.!=(i), :]
    else
      i += 1
    end
  end

  return HypsometricProfile(width, width_unit, pushfirst!(e, min_elevation), elevation_unit, pushfirst!(a, 0), area_unit, vcat(zeros(DT, 1, size(exposure_data, 2)), exposure_data), exposure_names, exposure_units)
end

function to_hypsometric_profiles(
  category_file_name::String, elevation_file_name::String, area_unit::String,
  exposure_file_names::Array{String}, exposure_names::Array{String}, exposure_units::Array{String},
  widths::Dict, width_unit::String, min_elevation::DT, max_elevation::DT, elevation_incr::DT, elevation_unit::String)::Dict{Int32,HypsometricProfile{DT}} where {DT<:Real}

  category_data = empty_geo_array(SparseArrayDOK{Float32,Int32})
  read_geotiff_header!(category_data, category_file_name)

  elevation_data = empty_geo_array(SparseArrayDOK{Float32,Int32})
  read_geotiff_header!(elevation_data, elevation_file_name)
  ga_dimension_match(category_data, elevation_data)

  gas_exposure = Array{GeoArrays.GeoArray{Float32,2,SparseArrayDOK{Float32,Int32}}}(undef, size(exposure_file_names, 1))

  s = floor(Int, ((max_elevation - min_elevation) / elevation_incr))
  e = Array{DT}(undef, s)
  for i in 1:s
    e[i] = min_elevation + i * elevation_incr
  end

  area_data::Dict{Int32,Array{DT}} = Dict()
  exposure_data::Dict{Int32,Array{DT,2}} = Dict()

  for i in 1:size(gas_exposure, 1)
    gas_exposure[i] = empty_geo_array(SparseArrayDOK{Float32,Int32})
    read_geotiff_header!(gas_exposure[i], exposure_file_names[i])
    ga_dimension_match(category_data, gas_exposure[i])
  end

  print("construction progress: 0 ")
  p = 0

  for y in 1:size(category_data, 2)
    if ((y * 100 ÷ size(category_data, 2)) ÷ 10) > p
      p = (y * 100 ÷ size(category_data, 2)) ÷ 10
      print("$(p*10) ")
    end
    clear_data!(category_data)
    read_geotiff_data_partial!(category_data, 1, size(category_data, 1), y, y)
    clear_data!(elevation_data)
    read_geotiff_data_partial!(elevation_data, 1, size(elevation_data, 1), y, y)
    for i in 1:size(gas_exposure, 1)
      clear_data!(gas_exposure[i])
      read_geotiff_data_partial!(gas_exposure[i], 1, size(gas_exposure[i], 1), y, y)
    end
    for x in 1:size(category_data, 1)
      if (category_data[x, y] != no_data_value(category_data))
        if (elevation_data[x, y] != no_data_value(elevation_data))
          if (!haskey(area_data, category_data[x, y]))
            area_data[category_data[x, y]] = zeros(s)
          end
          if (!haskey(exposure_data, category_data[x, y]))
            exposure_data[category_data[x, y]] = zeros(s, size(gas_exposure, 1))
          end

          i = if elevation_data[x, y] <= e[1]
            1
          else
            floor(Int, (elevation_data[x, y] - min_elevation) / elevation_incr) + 1
          end
          if (i > length(e))
            i = length(e)
          end
          area_data[category_data[x, y]][i] += area(elevation_data, x, y)
          for j in 1:size(gas_exposure, 1)
            if (gas_exposure[j][x, y] != no_data_value(gas_exposure[j]))
              exposure_data[category_data[x, y]][i, j] += gas_exposure[j][x, y]
            end
          end
        end
      end
    end
  end
  println()

  ret::Dict{Int32,HypsometricProfile{DT}} = Dict{Int32,HypsometricProfile{DT}}()
  for (index, areas) in area_data
    if haskey(widths, index)
      ret[index] = to_hypsometric_profile(copy(e), areas, area_unit,
        exposure_data[index], copy(exposure_names), copy(exposure_units),
        convert(DT, widths[index]), width_unit, min_elevation, max_elevation, elevation_incr, elevation_unit)
    else
      # warning?
    end
  end

  return ret
end


function attach_to_hypsometric_profiles!(
  hspf_data::Dict{Int32,HypsometricProfile{DT}},
  category_file_name::String, elevation_file_name::String,
  exposure_file_names::Array{String}, exposure_names::Array{String}, exposure_units::Array{String},
  min_elevation::DT, max_elevation::DT, elevation_incr::DT) where {DT<:Real}

  category_data = empty_geo_array(SparseArrayDOK{Float32,Int32})
  read_geotiff_header!(category_data, category_file_name)

  elevation_data = empty_geo_array(SparseArrayDOK{Float32,Int32})
  read_geotiff_header!(elevation_data, elevation_file_name)
  ga_dimension_match(category_data, elevation_data)

  gas_exposure = Array{GeoArrays.GeoArray{Float32,2,SparseArrayDOK{Float32,Int32}}}(undef, size(exposure_file_names, 1))

  s = floor(Int, ((max_elevation - min_elevation) / elevation_incr))
  e = Array{DT}(undef, s)
  for i in 1:s
    e[i] = min_elevation + i * elevation_incr
  end

  exposure_data::Dict{Int32,Array{DT,2}} = Dict{Int,Array{DT,2}}()

  for i in 1:size(gas_exposure, 1)
    gas_exposure[i] = empty_geo_array(SparseArrayDOK{Float32,Int32})
    read_geotiff_header!(gas_exposure[i], exposure_file_names[i])
    ga_dimension_match(category_data, gas_exposure[i])
  end

  print("attach progress: 0 ")
  p = 0

  for y in 1:size(category_data, 2)
    if ((y * 100 ÷ size(category_data, 2)) ÷ 10) > p
      p = (y * 100 ÷ size(category_data, 2)) ÷ 10
      print("$(p*10) ")
    end
    clear_data!(category_data)
    read_geotiff_data_partial!(category_data, 1, size(category_data, 1), y, y)
    clear_data!(elevation_data)
    read_geotiff_data_partial!(elevation_data, 1, size(elevation_data, 1), y, y)
    for i in 1:size(gas_exposure, 1)
      clear_data!(gas_exposure[i])
      read_geotiff_data_partial!(gas_exposure[i], 1, size(gas_exposure[i], 1), y, y)
    end
    for x in 1:size(category_data, 1)
      if (category_data[x, y] != no_data_value(category_data))
        if (elevation_data[x, y] != no_data_value(elevation_data))
          i = if elevation_data[x, y] <= e[1]
            1
          else
            floor(Int, (elevation_data[x, y] - min_elevation) / elevation_incr) + 1
          end
          if (i > size(e, 1))
            i = size(e, 1)
          end

          for j in 1:size(gas_exposure, 1)
            if (!haskey(exposure_data, category_data[x, y]))
              exposure_data[category_data[x, y]] = zeros(DT, s, size(gas_exposure, 1))
            end
            if (gas_exposure[j][x, y] != no_data_value(gas_exposure[j]))
              exposure_data[category_data[x, y]][i, j] += gas_exposure[j][x, y]
            end
          end
        end
      end
    end
  end
  println()

  pushfirst!(e, min_elevation)

  for (exp_data_index, exp_data_data) in exposure_data
    if (haskey(hspf_data, exp_data_index))
      exp_data_data = vcat(zeros(DT, 1, size(exp_data_data)[2]), exp_data_data)
      for j in 1:size(exp_data_data, 2)
        add_exposure_variable!(hspf_data[exp_data_index], copy(e), copy(exp_data_data[:, j]), exposure_names[j], exposure_units[j])
      end
    end
  end

end

function attach_exposure_variable_to_hypsometric_profiles!(
  hspf_data::Dict{Int32,HypsometricProfile{DT}},
  category_file_name::String, elevation_file_name::String,
  exposure_file_name::String, exposure_name::String, exposure_unit::String,
  min_elevation::DT, max_elevation::DT, elevation_incr::DT) where {DT<:Real}
  attach_to_hypsometric_profiles!(hspf_data, category_file_name, elevation_file_name, [exposure_file_name], [exposure_name], [exposure_unit], min_elevation, max_elevation, elevation_incr)
end

function attach_exposure_variable_to_hypsometric_profiles!(
  hspf_data::Dict{IT,HypsometricProfile{DT}},
  category_file_name::String, elevation_file_name::String,
  exposure_file_names::Array{String}, exposure_names::Array{String}, exposure_units::Array{String},
  min_elevation::DT, max_elevation::DT, elevation_incr::DT) where {DT<:Real,IT}

  if (size(exposure_file_names)[1] != size(exposure_names)[1])
    @error("exposure_file_names and exposure_names have different lengths ($(exposure_file_names) and $(exposure_names))")
  end

  if (size(exposure_file_names)[1] != size(exposure_units)[1])
    @error("exposure_file_names and exposure_units have different lengths ($(exposure_file_names) and $(exposure_units))")
  end

  for i in 1:size(exposure_file_names)
    attach_to_hypsometric_profiles!(hspf_data, category_file_name, elevation_file_name, exposure_file_names[i], exposure_names[i], exposure_units[i], min_elevation, max_elevation, elevation_incr)
  end
end

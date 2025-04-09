using StructArrays

export HypsometricProfile,
  unit,
  exposure_below_bathtub, exposure_below_bathtub_named,
  exposure_below_attenuated, attenuate,
  exposure_growth!, exposure_growth_above!, exposure_growth_below!, 
  remove_exposure_below!, remove_exposure_below_named!, add_exposure_above!, add_exposure_between!,
  add_exposure_dimension!, remove_exposure_dimension!,
  damage_bathtub_standard_ddf, damage_bathtub,
  compress!, compress_multithread!

"""
    HypsometricProfile(coast_length::DT, coast_length_unit::String,
    elevations::Array{DT}, elevation_unit::String, area::Array{DT}, area_unit::String,
    exposure_data::StructArray{T1}, exposure_units::Array{String}) where {DT<:Real,T1}

A HypsometricProfile represents the variation in elevation from the coastline to inland areas. It can be constructed manually or by using `load_hsps_nc()` and a NetCDF-file.
"""
mutable struct HypsometricProfile{DT<:Real}
  width::DT
  width_unit::String
  elevation::Array{DT}
  elevation_unit::String
  cummulativeArea::Array{DT}
  area_unit::String
  cummulativeExposure::Array{DT,2}
  exposureSymbols
  exposureUnits::Array{String}
  doLog::Bool

  # Constructors
  function HypsometricProfile(coast_length::DT, coast_length_unit::String,
    elevations::Array{DT}, elevation_unit::String, area::Array{DT}, area_unit::String,
    exposure_data::StructArray{T}, exposure_units::Array{String}) where {DT<:Real,T}
    if (length(elevations) != length(area))
      @error "length(elevations) != length(area) as length($elevations) != length($area) as $(length(elevations)) != $(length(area))"
    end
    if (length(elevations) != size(exposure_data, 1))
      @error "length(elevations) != size(exposure_data,1)  as length($elevations) != size($exposure_data,1)  as $(length(elevations)) != $(size(exposure_data,1))"
    end
    if (length(elevations) < 2)
      @error "length(elevations) = length($elevations) = $(length(elevations)) < 2 which is not allowed"
    end
    if (!issorted(elevations))
      @error "elevations is not sorted: $elevations"
    end

    if (area[1] != 0)
      @error "area[1] should be zero, but its not: $area"
    end
    if (values(exposure_data[1]) != tuple(zeros(length(exposure_data[1]))...))
      @error "exposure_data first column should be zero, but its not: $exposure_data"
    end

    exposure_arrays = private_convert_strarray_to_array(DT, exposure_data)
    new{DT}(coast_length, coast_length_unit, elevations, elevation_unit, cumsum(area), area_unit, cumsum(exposure_arrays, dims=1), keys(fieldarrays(exposure_data)), exposure_units)
  end

  function HypsometricProfile(coast_length::DT, coast_length_unit::String,
    elevations::Array{DT}, elevation_unit::String, area::Array{DT}, area_unit::String,
    exposure_data::Array{DT,2}, exposure_units::Array{String}) where {DT<:Real}
    # String(nameof(var"#self#"))
    if (length(elevations) != length(area))
      @error "length(elevations) != length(area) as length($elevations) != length($area) as $(length(elevations)) != $(length(area))"
    end
    if ((size(exposure_data, 1) > 0) && (length(elevations) != size(exposure_data, 1)))
      @error "length(elevations) != size(exposure_data,1)  as length($elevations) != size($exposure_data,1)  as $(length(elevations)) != $(size(exposure_data,1))"
    end
    if (length(elevations) < 2)
      @error "length(elevations) = length($elevations) = $(length(elevations)) < 2 which is not allowed"
    end
    if (!issorted(elevations))
      @error "elevations is not sorted: $elevations"
    end
    if (area[1] != 0)
      @error " area[1] should be zero, but its not: $area"
    end

    new{DT}(coast_length, coast_length_unit, elevations, elevation_unit, cumsum(area), area_unit, cumsum(exposure_data, dims=1), ntuple(i -> Symbol("exposure_data_name_$i"), size(exposure_data, 2)), exposure_units)
  end


  function HypsometricProfile(coast_length::DT, coast_length_unit::String,
    elevations::Array{DT}, elevation_unit::String, area::Array{DT}, area_unit::String,
    exposure_data::Array{DT,2}, exposure_names::Array{String}, exposure_units::Array{String}) where {DT<:Real}
    # String(nameof(var"#self#"))
    if (length(elevations) != length(area))
      @error "length(elevations) != length(area) as length($elevations) != length($area) as $(length(elevations)) != $(length(area))"
    end
    if ((size(exposure_data, 1) > 0) && (length(elevations) != size(exposure_data, 1)))
      @error "length(elevations) != size(exposure_data,1)  as length($elevations) != size($exposure_data,1)  as $(length(elevations)) != $(size(exposure_data,1))"
    end
    if (length(elevations) < 2)
      @error "length(elevations) = length($elevations) = $(length(elevations)) < 2 which is not allowed"
    end
    if (!issorted(elevations))
      @error "elevations is not sorted: $elevations"
    end
    if (exposure_names != unique(exposure_names))
      @error "exposure_names has duplicates: $exposure_names"
    end
    if (area[1] != 0)
      @error "area[1] should be zero, but its not: $area"
    end

    new{DT}(coast_length, coast_length_unit, elevations, elevation_unit, cumsum(area), area_unit, cumsum(exposure_data, dims=1), Tuple(map(x -> Symbol(x), exposure_names)), exposure_units)
  end

end


"""
   distance(hspf::HypsometricProfile, e::Real)
  
Compute the distance of elevation e (given in m) from the coastline in hspf. disatnce is returned in km.
"""
function distance(hspf::HypsometricProfile{DT}, e::Real)::DT where {DT<:Real}
  # internal note: this might be inefficient - it would be more efficient 
  if (e <= hspf.elevation[1])
    return 0.0
  end

  d = 0.0
  ind::Int64 = searchsortedfirst(hspf.elevation, e)
  for i in 2:(ind-1)
    Δ_area = hspf.cummulativeArea[i] - hspf.cummulativeArea[i-1]
    @inbounds Δ_el = (hspf.elevation[i] - hspf.elevation[i-1]) / 1000
    #println("$e:  $(hspf.elevation[i]) $(hspf.elevation[i-1]) $(Δ_area) $(Δ_el)")
    if (Δ_area != 0) && ((Δ_area / hspf.width) * (Δ_area / hspf.width) > (Δ_el * Δ_el))
      d += sqrt((Δ_area / hspf.width) * (Δ_area / hspf.width) - (Δ_el * Δ_el))
    end
  end

  @inbounds Δ_area = exposure_below_bathtub(hspf, e, :area) - hspf.cummulativeArea[ind-1]
  @inbounds Δ_el = (e - hspf.elevation[ind-1]) / 1000
  #println("$e:  $(hspf.elevation[ind-1]) $(Δ_el) $(Δ_area)")
  if (Δ_area != 0) && ((Δ_area / hspf.width) * (Δ_area / hspf.width) > (Δ_el * Δ_el))
    d += sqrt((Δ_area / hspf.width) * (Δ_area / hspf.width) - (Δ_el * Δ_el))
  end
  return d
end

function private_convert_strarray_to_array(::Type{DT}, sarr::StructArray{T1})::Array{DT} where {DT,T1}
  ret::Array{DT,2} = Array{DT,2}(undef, length(sarr), length(fieldarrays(sarr)))
  for i in 1:size(ret, 1)
    for j in 1:size(ret, 2)
      ret[i, j] = convert(DT, fieldarrays(sarr)[j][i])
    end
  end
  return ret
end

function slope(hspf::HypsometricProfile{DT}, i::Int) where {DT<:Real}
  if (i <= 1)
    return Inf
  end
  if (i > size(hspf.elevation, 1))
    return (hspf.width / (hspf.cummulativeArea[size(hspf.elevation, 1)] - hspf.cummulativeArea[size(hspf.elevation, 1)-1])) * (hspf.elevation[size(hspf.elevation, 1)] - hspf.elevation[size(hspf.elevation, 1)-1]) * convert(DT, 0.001)
  end
  return (hspf.width / (hspf.cummulativeArea[i] - hspf.cummulativeArea[i-1])) * (hspf.elevation[i] - hspf.elevation[i-1]) * convert(DT, 0.001)
end

function resample!(hspf::HypsometricProfile{DT}, elevation::Array{DT}) where {DT<:Real}
  if (hspf.elevation[1] != elevation[1])
    @error "min elevation can not be changed in resampling: $(hspf.elevation[1]) != $(elevation[1])"
  end

  can = Array{DT}(undef, size(elevation, 1))
  cden::Array{DT,2} = Array{DT,2}(undef, size(elevation, 1), size(hspf.cummulativeExposure, 2))

  for i in 1:size(elevation, 1)
    t_exposure = exposure_below_bathtub(hspf, elevation[i])
    can[i] = t_exposure[1]
    cden[i, :] = t_exposure[2]
  end

  hspf.elevation = copy(elevation)
  hspf.cummulativeArea = can
  hspf.cummulativeExposure = cden
end

"""
    compress!(hspf::HypsometricProfile)
  
Comress a hypsometric profile by removing colinear points. Calculations on compressed hypsometric profiles can be faster. Idempotent operation.
"""
function compress!(hspf::HypsometricProfile{DT}) where {DT<:Real}
  if (size(hspf.elevation, 1) > 2)
    i = 2
    d = 0
    keep = ones(Bool, size(hspf.elevation, 1))
    nzlf = false

    while i < size(hspf.elevation, 1) && !nzlf
      if (complete_zero(exposure_below_bathtub(hspf, hspf.elevation[i-1])) && complete_zero(exposure_below_bathtub(hspf, hspf.elevation[i])))
        keep[i-1] = false
        d = d + 1
      else
        nzlf = true
      end
      i += 1
    end

    for j in i:size(hspf.elevation, 1)-1
      if private_colinear_lines(hspf, j - 1, j, j + 1, !nzlf)
        keep[j] = false
        d = d + 1
      end
    end

    # OLD:
    #newElevation = zeros(DT, size(hspf.elevation, 1) - d)
    #newCummulativeArea = zeros(DT, size(hspf.elevation, 1) - d)
    newCummulativeExposure = zeros(DT, size(hspf.cummulativeExposure, 1) - d, size(hspf.cummulativeExposure, 2))

    c = 1
    for i in 1:size(hspf.elevation, 1)
      if (keep[i])
        hspf.elevation[c] = hspf.elevation[i]
        hspf.cummulativeArea[c] = hspf.cummulativeArea[i]
        newCummulativeExposure[c, :] = hspf.cummulativeExposure[i, :]
        c += 1
      end
    end

    resize!(hspf.elevation, c - 1)
    resize!(hspf.cummulativeArea, c - 1)
    hspf.cummulativeExposure = newCummulativeExposure
  end
end

function compress_multithread!(hspf::HypsometricProfile{DT}, mtlock) where {DT<:Real}
  if (size(hspf.elevation, 1) > 2)
    i = 2
    d = 0
    keep = ones(Bool, size(hspf.elevation, 1))
    nzlf = false

    while i < size(hspf.elevation, 1) && !nzlf
      if (complete_zero(exposure_below_bathtub(hspf, hspf.elevation[i-1])) && complete_zero(exposure_below_bathtub(hspf, hspf.elevation[i])))
        keep[i-1] = false
        d = d + 1
      else
        nzlf = true
      end
      i += 1
    end

    for j in i:size(hspf.elevation, 1)-1
      if private_colinear_lines(hspf, j - 1, j, j + 1, !nzlf)
        keep[j] = false
        d = d + 1
      end
    end

    # OLD:
    #newElevation = zeros(DT, size(hspf.elevation, 1) - d)
    #newCummulativeArea = zeros(DT, size(hspf.elevation, 1) - d)
    newCummulativeExposure = zeros(DT, size(hspf.cummulativeExposure, 1) - d, size(hspf.cummulativeExposure, 2))

    c = 1
    for i in 1:size(hspf.elevation, 1)
      if (keep[i])
        Threads.lock(mtlock) do
          hspf.elevation[c] = hspf.elevation[i]
          hspf.cummulativeArea[c] = hspf.cummulativeArea[i]
        end
        newCummulativeExposure[c, :] = hspf.cummulativeExposure[i, :]
        c += 1
      end
    end

    Threads.lock(mtlock) do
      resize!(hspf.elevation, c - 1)
      resize!(hspf.cummulativeArea, c - 1)
      hspf.cummulativeExposure = newCummulativeExposure
    end
  end
end

function get_position(hspf::HypsometricProfile, s::Symbol)
  if (s == :area)
    return (1, 1)
  end
  if (findfirst(==(s), hspf.exposureSymbols) != nothing)
    return (2, findfirst(==(s), hspf.exposureSymbols))
  end
  return (-1, 0)
end

get_position(hspf::HypsometricProfile, n::String) = get_position(hspf, Symbol(n))

"""
    unit(hspf::HypsometricProfile, s::Symbol)  
    unit(hspf::HypsometricProfile, s::String)    

    returns the unit (of type String) of the exposure dimension with name s (where s can be a string or a symbol)
"""
function unit(hspf::HypsometricProfile, s::Symbol)
  p = get_position(hspf, s)
  if (p[1] == 1)
    return hspf.area_unit
  end
  if (p[1] == 2)
    return hspf.exposureUnits[p[2]]
  end
  return "unknown symbol: $s"
end

unit(hspf::HypsometricProfile, n::String) = unit(hspf, Symbol(n))


function complete_zero(exposure)
  if (exposure[1] != 0)
    return false
  end
  for i in 1:size(exposure[2], 1)
    if exposure[2][i] != 0
      return false
    end
  end
  return true
end

function private_colinear_lines(hspf::HypsometricProfile, i1::Int64, i2::Int64, i3::Int64, check_zero::Bool)::Bool
  ex1 = exposure_below_bathtub(hspf, hspf.elevation[i1])
  ex2 = exposure_below_bathtub(hspf, hspf.elevation[i2])
  ex3 = exposure_below_bathtub(hspf, hspf.elevation[i3])
  r = (hspf.elevation[i2] - hspf.elevation[i1]) / (hspf.elevation[i3] - hspf.elevation[i1])
  # hack to capture special case that makes problems (if e3 is very small)
  if (check_zero && complete_zero(ex2) && !complete_zero(ex3))
    return false
  end
  return isapprox(ex2[1], ex1[1] + r * (ex3[1] - ex1[1])) && isapprox(ex2[2], ex1[2] + r * (ex3[2] - ex1[2]))
end

include("hypsometric_profile_exposure.jl")
include("hypsometric_profile_damage_arbitrary_ddf.jl")
include("hypsometric_profile_damage_standard_ddf.jl")
include("hypsometric_profile_exposure_modifications.jl")
include("hypsometric_profile_dimension_modifications.jl")
include("hypsometric_profile_plot.jl")
include("hypsometric_profile_operators.jl")

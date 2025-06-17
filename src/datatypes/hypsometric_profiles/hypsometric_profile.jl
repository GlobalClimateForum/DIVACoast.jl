using StructArrays, DataFrames

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
  exposureNames::Array{String}
  exposureUnits::Array{String}
  doLog::Bool

  # Constructors
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

    new{DT}(coast_length, coast_length_unit, elevations, elevation_unit, cumsum(area), area_unit, cumsum(exposure_data, dims=1), map(i -> "exposure_data_name_$i", collect(1:size(exposure_data, 2))), exposure_units)
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

    new{DT}(coast_length, coast_length_unit, elevations, elevation_unit, cumsum(area), area_unit, cumsum(exposure_data, dims=1), exposure_names, exposure_units)
  end

  function HypsometricProfile(df::DataFrame; exposureCols = Symbol[], exposureUnits = String[], units = (width = "m", elevation = "m", area = "m²"))

    exportData = vcat([hcat(values(row) ...) for row in eachrow(df[:, exposureCols])] ...)

    new{Float32}(df.width[1], units.width,
        df.elevation, units.elevation,
        df.cummulativeArea, units.area,
        exportData, 
        String.(exposureCols),
        exposureUnits)
end


end


"""
   distance(hspf::HypsometricProfile, e::Real)
  
Compute the distance of elevation e (given in m) from the coastline in hspf. disatnce is returned in km.
"""
function distance(hspf::HypsometricProfile{DT}, e::Real)::DT where {DT<:Real}
  # internal note: this might be inefficient 
  if (e <= hspf.elevation[1])
    return 0.0
  end

  d = 0.0
  ind::Int64 = searchsortedfirst(hspf.elevation, e)
  for i in 2:(ind-1)
    Δ_area = hspf.cummulativeArea[i] - hspf.cummulativeArea[i-1]
    @inbounds Δ_el = (hspf.elevation[i] - hspf.elevation[i-1]) / 1000
    if (Δ_area != 0) && ((Δ_area / hspf.width) * (Δ_area / hspf.width) > (Δ_el * Δ_el))
      d += sqrt((Δ_area / hspf.width) * (Δ_area / hspf.width) - (Δ_el * Δ_el))
    end
  end

  if (ind <= size(hspf.elevation, 1))
    @inbounds Δ_el = (e - hspf.elevation[ind-1]) / 1000
    @inbounds Δ_el_rel = (e - hspf.elevation[ind-1]) / (hspf.elevation[ind] - hspf.elevation[ind-1])
    @inbounds Δ_area = (hspf.cummulativeArea[ind] - hspf.cummulativeArea[ind-1]) * Δ_el_rel

    if (Δ_area != 0) && ((Δ_area / hspf.width) * (Δ_area / hspf.width) > (Δ_el * Δ_el))
      d += sqrt((Δ_area / hspf.width) * (Δ_area / hspf.width) - (Δ_el * Δ_el))
    end
  end
  return d
end

# Important: returned unit is km/km (or m/m ...)
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
    t_exposure = exposure(hspf, elevation[i])
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
      if (complete_zero(exposure(hspf, hspf.elevation[i-1])) && complete_zero(exposure(hspf, hspf.elevation[i])))
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
      if (complete_zero(exposure(hspf, hspf.elevation[i-1])) && complete_zero(exposure(hspf, hspf.elevation[i])))
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

function get_position(hspf::HypsometricProfile, s::String)
  if (s == "area")
    return 0
  end
  if (findfirst(==(s), hspf.exposureNames) != nothing)
    return findfirst(==(s), hspf.exposureNames)
  end
  return -1
end

get_position(hspf::HypsometricProfile, n::Symbol) = get_position(hspf, String(n))

"""
    unit(hspf::HypsometricProfile, s::Symbol)  
    unit(hspf::HypsometricProfile, s::String)    

    returns the unit (of type String) of the exposure variable with name s (where s can be a string or a symbol)
"""
function unit(hspf::HypsometricProfile, s::String)
  p = get_position(hspf, s)
  if (p == 0)
    return hspf.area_unit
  end
  if (p > 0)
    return hspf.exposureUnits[p]
  end
  return "unknown symbol: $s"
end

unit(hspf::HypsometricProfile, n::Symbol) = unit(hspf, String(n))

function complete_zero(exposure::Tuple{DT, Vector{DT}}) where {DT<:Real}
  if (exposure[1] != 0)
    return false
  end
  if length(exposure) == 1
    return true
  else
    for i in 1:size(exposure[2], 1)
      if exposure[2][i] != 0
        return false
      end
    end
    return true
  end
end

function complete_zero(exposure::Array{DT}) where {DT<:Real}
  for i in 1:size(exposure, 1)
    if exposure[i] != 0
      return false
    end
  end
  return true
end

function private_colinear_lines(hspf::HypsometricProfile, i1::Int64, i2::Int64, i3::Int64, check_zero::Bool)::Bool
  ex1 = exposure(hspf, hspf.elevation[i1])
  ex2 = exposure(hspf, hspf.elevation[i2])
  ex3 = exposure(hspf, hspf.elevation[i3])
  r = (hspf.elevation[i2] - hspf.elevation[i1]) / (hspf.elevation[i3] - hspf.elevation[i1])
  # hack to capture special case that makes problems (if e3 is very small)
  if (check_zero && complete_zero(ex2) && !complete_zero(ex3))
    return false
  end
  return isapprox(ex2[1], ex1[1] + r * (ex3[1] - ex1[1])) && isapprox(ex2[2], ex1[2] + r * (ex3[2] - ex1[2]))
end

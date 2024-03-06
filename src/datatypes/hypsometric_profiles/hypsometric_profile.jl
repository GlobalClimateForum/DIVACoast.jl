using StructArrays

export HypsometricProfile,
  unit,
  exposure_below_bathtub, exposure_below_bathtub_named,
  sed, sed_above, sed_below, remove_below, remove_below_named, add_above, add_between,
  add_static_exposure!, add_dynamic_exposure!, remove_static_exposure!, remove_dynamic_exposure!,
  damage_bathtub_standard_ddf, damage_bathtub,
  compress!


mutable struct HypsometricProfile{DT<:Real}
  width::DT
  width_unit::String
  elevation::Array{DT}
  elevation_unit::String
  cummulativeArea::Array{DT}
  area_unit::String
  cummulativeStaticExposure::Array{DT,2}
  staticExposureSymbols
  staticExposureUnits::Array{String}
  cummulativeDynamicExposure::Array{DT,2}
  dynamicExposureSymbols
  dynamicExposureUnits::Array{String}
  logger::ExtendedLogger

  # Constructors
  function HypsometricProfile(w::DT, width_unit::String,
    elevations::Array{DT}, elevation_unit::String, area::Array{DT}, area_unit::String,
    s_exposure::StructArray{T1}, s_exposure_units::Array{String},
    d_exposure::StructArray{T2}, d_exposure_units::Array{String},
    logger::ExtendedLogger=ExtendedLogger()) where {DT<:Real,T1,T2}
    if (length(elevations) != length(area))
      logg(logger, Logging.Error, @__FILE__, String(nameof(var"#self#")), "\n length(elevations) != length(area) as length($elevations) != length($area) as $(length(elevations)) != $(length(area))")
    end
    if (length(elevations) != size(s_exposure, 1))
      logg(logger, Logging.Error, @__FILE__, String(nameof(var"#self#")), "\n length(elevations) != size(s_exposure,1) as length($elevations) != size($s_exposure,1) as $(length(elevations)) != $(size(s_exposure,1))")
    end
    if (length(elevations) != size(d_exposure, 1))
      logg(logger, Logging.Error, @__FILE__, String(nameof(var"#self#")), "\n length(elevations) != size(d_exposure,1)  as length($elevations) != size($d_exposure,1)  as $(length(elevations)) != $(size(d_exposure,1))")
    end
    if (length(elevations) < 2)
      logg(logger, Logging.Error, @__FILE__, String(nameof(var"#self#")), "\n length(elevations) = length($elevations) = $(length(elevations)) < 2 which is not allowed")
    end
    if (!issorted(elevations))
      logg(logger, Logging.Error, @__FILE__, String(nameof(var"#self#")), "\n elevations is not sorted: $elevations")
    end

    if (area[1] != 0)
      logg(logger, Logging.Error, @__FILE__, String(nameof(var"#self#")), "\n area[1] should be zero, but its not: $area")
    end
    if (values(s_exposure[1]) != tuple(zeros(length(s_exposure[1]))...))
      logg(logger, Logging.Error, @__FILE__, String(nameof(var"#self#")), "\n d_exposure first column should be zero, but its not: $s_exposure")
    end
    if (values(d_exposure[1]) != tuple(zeros(length(d_exposure[1]))...))
      logg(logger, Logging.Error, @__FILE__, String(nameof(var"#self#")), "\n d_exposure first column should be zero, but its not: $d_exposure")
    end

    s_exposure_arrays = private_convert_strarray_to_array(DT, s_exposure)
    d_exposure_arrays = private_convert_strarray_to_array(DT, d_exposure)

    new{DT}(w, width_unit, elevations, elevation_unit, cumsum(area), area_unit, cumsum(s_exposure_arrays, dims=1), keys(fieldarrays(s_exposure)), s_exposure_units, cumsum(d_exposure_arrays, dims=1), keys(fieldarrays(d_exposure)), d_exposure_units, ExtendedLogger())
  end

  function HypsometricProfile(w::DT, width_unit::String,
    elevations::Array{DT}, elevation_unit::String, area::Array{DT}, area_unit::String,
    s_exposure::Array{DT,2}, s_exposure_units::Array{String},
    d_exposure::Array{DT,2}, d_exposure_units::Array{String},
    logger::ExtendedLogger=ExtendedLogger()) where {DT<:Real}
    # String(nameof(var"#self#"))
    if (length(elevations) != length(area))
      logg(logger, Logging.Error, @__FILE__, "", "\n length(elevations) != length(area) as length($elevations) != length($area) as $(length(elevations)) != $(length(area))")
    end
    if ((size(s_exposure, 1) > 0) && (length(elevations) != size(s_exposure, 1)))
      logg(logger, Logging.Error, @__FILE__, "", "\n length(elevations) != size(s_exposure,1) as length($elevations) != size($s_exposure,1) as $(length(elevations)) != $(size(s_exposure,1))")
    end
    if ((size(d_exposure, 1) > 0) && (length(elevations) != size(d_exposure, 1)))
      logg(logger, Logging.Error, @__FILE__, "", "\n length(elevations) != size(d_exposure,1)  as length($elevations) != size($d_exposure,1)  as $(length(elevations)) != $(size(d_exposure,1))")
    end
    if (length(elevations) < 2)
      logg(logger, Logging.Error, @__FILE__, "", "\n length(elevations) = length($elevations) = $(length(elevations)) < 2 which is not allowed")
    end
    if (!issorted(elevations))
      logg(logger, Logging.Error, @__FILE__, "", "\n elevations is not sorted: $elevations")
    end
    if (area[1] != 0)
      logg(logger, Logging.Error, @__FILE__, String(nameof(var"#self#")), "\n area[1] should be zero, but its not: $area")
    end
    #if (values(s_exposure[1]) != tuple(zeros(length(s_exposure[1]))...)) logg(logger,Logging.Error,@__FILE__,String(nameof(var"#self#")),"\n d_exposure first column should be zero, but its not: $s_exposure") end
    #if (values(d_exposure[1]) != tuple(zeros(length(d_exposure[1]))...)) logg(logger,Logging.Error,@__FILE__,String(nameof(var"#self#")),"\n d_exposure first column should be zero, but its not: $d_exposure") end

    new{DT}(w, width_unit, elevations, elevation_unit, cumsum(area), area_unit, cumsum(s_exposure, dims=1), ntuple(i -> Symbol("s_exposure_name_$i"), size(s_exposure, 2)), s_exposure_units, cumsum(d_exposure, dims=1), ntuple(i -> Symbol("d_exposure_name_$i"), size(d_exposure, 2)), d_exposure_units, logger)
  end


  function HypsometricProfile(w::DT, width_unit::String,
    elevations::Array{DT}, elevation_unit::String, area::Array{DT}, area_unit::String,
    s_exposure::Array{DT,2}, s_exposure_names::Array{String}, s_exposure_units::Array{String},
    d_exposure::Array{DT,2}, d_exposure_names::Array{String}, d_exposure_units::Array{String},
    logger::ExtendedLogger=ExtendedLogger()) where {DT<:Real}
    # String(nameof(var"#self#"))
    if (length(elevations) != length(area))
      logg(logger, Logging.Error, @__FILE__, "", "\n length(elevations) != length(area) as length($elevations) != length($area) as $(length(elevations)) != $(length(area))")
    end
    if ((size(s_exposure, 1) > 0) && (length(elevations) != size(s_exposure, 1)))
      logg(logger, Logging.Error, @__FILE__, "", "\n length(elevations) != size(s_exposure,1) as length($elevations) != size($s_exposure,1) as $(length(elevations)) != $(size(s_exposure,1))")
    end
    if ((size(d_exposure, 1) > 0) && (length(elevations) != size(d_exposure, 1)))
      logg(logger, Logging.Error, @__FILE__, "", "\n length(elevations) != size(d_exposure,1)  as length($elevations) != size($d_exposure,1)  as $(length(elevations)) != $(size(d_exposure,1))")
    end
    if (length(elevations) < 2)
      logg(logger, Logging.Error, @__FILE__, "", "\n length(elevations) = length($elevations) = $(length(elevations)) < 2 which is not allowed")
    end
    if (!issorted(elevations))
      logg(logger, Logging.Error, @__FILE__, "", "\n elevations is not sorted: $elevations")
    end
    if (s_exposure_names != unique(s_exposure_names))
      logg(logger, Logging.Error, @__FILE__, "", "\n s_exposure_names has duplicates: $s_exposure_names")
    end
    if (d_exposure_names != unique(d_exposure_names))
      logg(logger, Logging.Error, @__FILE__, "", "\n d_exposure_names has duplicates: $d_exposure_names")
    end
    if (area[1] != 0)
      logg(logger, Logging.Error, @__FILE__, String(nameof(var"#self#")), "\n area[1] should be zero, but its not: $area")
    end
    #if (values(s_exposure[1]) != tuple(zeros(length(s_exposure[1]))...)) logg(logger,Logging.Error,@__FILE__,String(nameof(var"#self#")),"\n d_exposure first column should be zero, but its not: $s_exposure") end
    #if (values(d_exposure[1]) != tuple(zeros(length(d_exposure[1]))...)) logg(logger,Logging.Error,@__FILE__,String(nameof(var"#self#")),"\n d_exposure first column should be zero, but its not: $d_exposure") end

    new{DT}(w, width_unit, elevations, elevation_unit, cumsum(area), area_unit, cumsum(s_exposure, dims=1), Tuple(map(x -> Symbol(x), s_exposure_names)), s_exposure_units, cumsum(d_exposure, dims=1), Tuple(map(x -> Symbol(x), d_exposure_names)), d_exposure_units, logger)
  end


  function HypsometricProfile(w::DT, width_unit::String,
    elevations::Array{DT}, elevation_unit::String, area::Array{DT}, area_unit::String,
    s_exposure::Vector{Any}, s_exposure_names::Vector{Any}, s_exposure_units::Vector{Any},
    d_exposure::Array{DT,2}, d_exposure_names::Array{String}, d_exposure_units::Array{String},
    logger::ExtendedLogger=ExtendedLogger()) where {DT<:Real}
    if s_exposure == []
      return HypsometricProfile(w, width_unit, elevations, elevation_unit, area, area_unit, Matrix{Float32}(undef, 0, 0), convert(Array{String}, s_exposure_names), convert(Array{String}, s_exposure_units), d_exposure, d_exposure_names, d_exposure_units, logger)
    else
      return HypsometricProfile(w, width_unit, elevations, elevation_unit, area, area_unit, convert(Array{DT,2}, s_exposure), convert(Array{String}, s_exposure_names), convert(Array{String}, s_exposure_units), d_exposure, d_exposure_names, d_exposure_units, logger)
    end
  end

  function HypsometricProfile(w::DT,
    elevations::Array{DT}, elevation_unit::String, area::Array{DT}, area_unit::String,
    s_exposure::Array{DT,2}, s_exposure_names::Array{String}, s_exposure_units::Array{String},
    d_exposure::Vector{Any}, d_exposure_names::Vector{Any}, d_exposure_units::Vector{Any},
    logger::ExtendedLogger=ExtendedLogger()) where {DT<:Real}
    if d_exposure == []
      return HypsometricProfile(w, width_unit, elevations, elevation_unit, area, area_unit, s_exposure, s_exposure_names, s_exposure_units, Matrix{Float32}(undef, 0, 0), convert(Array{String}, d_exposure_names), convert(Array{String}, d_exposure_units), logger)
    else
      return HypsometricProfile(w, width_unit, elevations, elevation_unit, area, area_unit, s_exposure, s_exposure_names, s_exposure_units, convert(Array{DT,2}, d_exposure), convert(Array{String}, d_exposure_names), convert(Array{String}, d_exposure_units), logger)
    end
  end
end

include("hypsometric_profile_exposure.jl")
include("hypsometric_profile_damage_arbitrary_ddf.jl")
include("hypsometric_profile_damage_standard_ddf.jl")
include("hypsometric_profile_sed.jl")
include("hypsometric_profile_modifications.jl")
include("hypsometric_profile_plot.jl")

function distance(hspf::HypsometricProfile, e::Real)::DT
  ind::Int64 = searchsortedfirst(hspf.elevation, e)

  if (e in hspf.elevation)
    return cos(asin(hspf.elevation[i] / (hspf.cummulativeArea[ind] / hspf.width))) * (hspf.cummulativeArea[ind] / hspf.width)
  else
    @inbounds if (ind == 1)
      return 0.0f0
    end
    @inbounds if (ind >= size(hspf.elevation, 1))
      cos(asin(hspf.elevation[size(hspf.elevation, 1)] / (hspf.cummulativeArea[size(hspf.elevation, 1)] / hspf.width))) * (hspf.cummulativeArea[size(hspf.elevation, 1)] / hspf.width)
    end
    @inbounds r = (DT)(e - hspf.elevation[ind-1]) / (hspf.elevation[ind] - hspf.elevation[ind-1])

    @inbounds return cos(asin(hspf.elevation[ind-1] + ((hspf.elevation[ind] - hspf.elevation[ind-1]) * r) / (hspf.cummulativeArea[ind-1] + ((hspf.cummulativeArea[ind] - hspf.cummulativeArea[ind-1]) * r) / hspf.width))) * (hspf.cummulativeArea[ind-1] + ((hspf.cummulativeArea[ind] - hspf.cummulativeArea[ind-1]) * r) / hspf.width)
  end
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
    logg(hspf.logger, Logging.Error, @__FILE__, "", "\n min elevation can not be changed in resampling: $(hspf.elevation[1]) != $(elevation[1])")
  end

  can = Array{DT}(undef, size(elevation, 1))
  csen::Array{DT,2} = Array{DT,2}(undef, size(elevation, 1), size(hspf.cummulativeStaticExposure, 2))
  cden::Array{DT,2} = Array{DT,2}(undef, size(elevation, 1), size(hspf.cummulativeDynamicExposure, 2))

  for i in 1:size(elevation, 1)
    t_exposure = exposure_below_bathtub(hspf, elevation[i])
    can[i] = t_exposure[1]
    csen[i, :] = t_exposure[2]
    cden[i, :] = t_exposure[3]
  end

  hspf.elevation = copy(elevation)
  hspf.cummulativeArea = can
  hspf.cummulativeStaticExposure = csen
  hspf.cummulativeDynamicExposure = cden
end

"""
    compress!(hspf::HypsometricProfile)
  
Comress a hypsometric profile by removing colinear points. Calculations on compressed hypsometric profiles can be faster. Idempotent operation.
"""
function compress!(hspf::HypsometricProfile{DT}) where {DT<:Real}
  i = 2
  d = 0
  keep = ones(Bool,size(hspf.elevation, 1))
  for i in 2:size(hspf.elevation, 1) - 1
    if private_colinear_lines(hspf, i - 1, i, i + 1)
      keep[i]=false
      d = d + 1
    end
  end

  newElevation = zeros(DT,size(hspf.elevation, 1)-d)
  newCummulativeArea = zeros(DT,size(hspf.elevation, 1)-d)
  newCummulativeStaticExposure = zeros(DT,size(hspf.cummulativeStaticExposure,1)-d,size(hspf.cummulativeStaticExposure,2))
  newCummulativeDynamicExposure = zeros(DT,size(hspf.cummulativeDynamicExposure,1)-d,size(hspf.cummulativeDynamicExposure,2))

  c=1 
  for i in 1:size(hspf.elevation, 1)
    if (keep[i])
      newElevation[c] = hspf.elevation[i]
      newCummulativeArea[c] = hspf.cummulativeArea[i]
      newCummulativeStaticExposure[c,:] = hspf.cummulativeStaticExposure[i,:]
      newCummulativeDynamicExposure[c,:] = hspf.cummulativeDynamicExposure[i,:]
      c += 1
    end
  end

  hspf.elevation = newElevation
  hspf.cummulativeArea = newCummulativeArea
  hspf.cummulativeStaticExposure = newCummulativeStaticExposure
  hspf.cummulativeDynamicExposure = newCummulativeDynamicExposure
end

function get_position(hspf::HypsometricProfile, s::Symbol)
  if (s == :area)
    return (1,1)
  end
  if (findfirst(==(s), hspf.staticExposureSymbols) != nothing)
    return (2,findfirst(==(s), hspf.staticExposureSymbols))
  end
  if (findfirst(==(s), hspf.dynamicExposureSymbols) != nothing)
    return (3,findfirst(==(s), hspf.dynamicExposureSymbols))
  end
  return (-1,0)
end

get_position(hspf::HypsometricProfile, n::String) = get_position(hspf, Symbol(n))

function unit(hspf::HypsometricProfile, s::Symbol)
  p = get_position(hspf, s)
  if (p[1]==1)
    return hspf.area_unit
  end
  if (p[1]==2)
    return hspf.staticExposureUnits[p[2]]
  end
  if (p[1]==3)
    return hspf.dynamicExposureUnits[p[2]]
  end
  return "unknown symbol: $s"
end

unit(hspf::HypsometricProfile, n::String) = unit(hspf, Symbol(n))


function private_colinear_lines(hspf::HypsometricProfile, i1::Int64, i2::Int64, i3::Int64)::Bool
  ex1 = exposure_below_bathtub(hspf, hspf.elevation[i1])
  ex2 = exposure_below_bathtub(hspf, hspf.elevation[i2])
  ex3 = exposure_below_bathtub(hspf, hspf.elevation[i3])
  r = (hspf.elevation[i2] - hspf.elevation[i1]) / (hspf.elevation[i3] - hspf.elevation[i1])
  return isapprox(ex2[1], ex1[1] + r * (ex2[1] - ex1[1])) && isapprox(ex2[2], ex1[2] + r * (ex2[2] - ex1[2])) && isapprox(ex2[3], ex1[3] + r * (ex2[3] - ex1[3]))
end

#==
function private_remove_line(hspf::HypsometricProfile, i)
  # probably not efficient
  deleteat!(hspf.elevation, i)
  deleteat!(hspf.cummulativeArea, i)
  newarray = hspf.cummulativeStaticExposure[1:end.!=(i), :]
  hspf.cummulativeStaticExposure = newarray
  newarray = hspf.cummulativeDynamicExposure[1:end.!=(i), :]
  hspf.cummulativeDynamicExposure = newarray
end
==#

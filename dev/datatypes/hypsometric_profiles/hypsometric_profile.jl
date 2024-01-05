using StructArrays

export HypsometricProfile,
  exposure, exposure_named,
  sed, sed_above, sed_below, remove_below, remove_below_named, add_above, add_between,
  add_static_exposure!, add_dynamic_exposure!, remove_static_exposure!, remove_dynamic_exposure!

mutable struct HypsometricProfile{DT<:Real}
  width::DT
  elevation::Array{DT}
  cummulativeArea::Array{DT}
  cummulativeStaticExposure::Array{DT,2}
  staticExposureSymbols
  staticExposureUnits::Array{String}
  cummulativeDynamicExposure::Array{DT,2}
  dynamicExposureSymbols
  dynamicExposureUnits::Array{String}
  logger::ExtendedLogger

  # Constructors
  function HypsometricProfile(w::DT, elevations::Array{DT}, area::Array{DT}, s_exposure::StructArray{T1},
    s_exposure_units::Array{String}, d_exposure::StructArray{T2}, _exposure_units::Array{String},
    logger::ExtendedLogger=ExtendedLogger()) where {T1,T2,DT<:Real}
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

    s_exposure_arrays = private_convert_strarray_to_array{T1,DT}(s_exposure)
    d_exposure_arrays = private_convert_strarray_to_array{T1,DT}(d_exposure)

    new{DT}(w, elevations, cumsum(area), cumsum(s_exposure_arrays, dims=1), keys(fieldarrays(s_exposure)), s_exposure_units, cumsum(d_exposure_arrays, dims=1), keys(fieldarrays(d_exposure)), d_exposure_units, logger)
  end

  function HypsometricProfile(w::DT, elevations::Array{DT}, area::Array{DT},
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

    new{DT}(w, elevations, cumsum(area), cumsum(s_exposure, dims=1), ntuple(i -> Symbol("s_exposure_name_$i"), size(s_exposure, 2)), s_exposure_units, cumsum(d_exposure, dims=1), ntuple(i -> Symbol("d_exposure_name_$i"), size(d_exposure, 2)), d_exposure_units, logger)
  end


  function HypsometricProfile(w::DT, elevations::Vector{DT}, area::Vector{DT},
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

    if (area[1] != 0)
      logg(logger, Logging.Error, @__FILE__, String(nameof(var"#self#")), "\n area[1] should be zero, but its not: $area")
    end
    #if (values(s_exposure[1]) != tuple(zeros(length(s_exposure[1]))...)) logg(logger,Logging.Error,@__FILE__,String(nameof(var"#self#")),"\n d_exposure first column should be zero, but its not: $s_exposure") end
    #if (values(d_exposure[1]) != tuple(zeros(length(d_exposure[1]))...)) logg(logger,Logging.Error,@__FILE__,String(nameof(var"#self#")),"\n d_exposure first column should be zero, but its not: $d_exposure") end

    new{DT}(w, elevations, cumsum(area), cumsum(s_exposure, dims=1), Tuple(map(x -> Symbol(x), s_exposure_names)), s_exposure_units, cumsum(d_exposure, dims=1), Tuple(map(x -> Symbol(x), d_exposure_names)), d_exposure_units, logger)
  end
end

include("hypsometric_profile_exposure.jl")
include("hypsometric_profile_damage.jl")
include("hypsometric_profile_sed.jl")
include("hypsometric_profile_modifications.jl")

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

function private_convert_strarray_to_array(sarr::StructArray{T1})::Array{DT} where {T1,DT}
  ret::Array{DT,2} = Array{DT,2}(undef, length(sarr), length(fieldarrays(sarr)))
  for i in 1:size(ret, 1)
    for j in 1:size(ret, 2)
      ret[i, j] = convert(DT, fieldarrays(sarr)[j][i])
    end
  end
  return ret
end

function private_slope(hspf::HypsometricProfile, i::Int64)::DT
  if (i <= 1)
    return Inf
  end
  if (i > size(hspf.elevation, 1))
    return (hspf.elevation[size(hspf.elevation, 1)] - hspf.elevation[size(hspf.elevation, 1)-1]) * (hspf.width / hspf.cummulativeArea[size(hspf.elevation, 1)])
  end
  return (hspf.elevation[i] - hspf.elevation[i-1]) * (hspf.width / hspf.cummulativeArea[i])
end


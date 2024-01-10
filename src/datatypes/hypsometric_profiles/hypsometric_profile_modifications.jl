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

function remove_static_exposure!(hspf::HypsometricProfile, ind :: Integer)
  if (1<=ind && ind<=size(hspf.staticExposureUnits,1))
    hspf.staticExposureSymbols = (hspf.staticExposureSymbols[1:ind-1]...,hspf.staticExposureSymbols[ind+1:size(hspf.staticExposureUnits,1)]...)
    deleteat!(hspf.staticExposureUnits,ind)
    hspf.cummulativeStaticExposure = hspf.cummulativeStaticExposure[:, 1:end .!= ind]
  end
end

function remove_dynamic_exposure!(hspf::HypsometricProfile, ind :: Integer)
  if (1<=ind && ind<=size(hspf.dynamicExposureUnits,1))
    hspf.dynamicExposureSymbols = (hspf.dynamicExposureSymbols[1:ind-1]...,hspf.dynamicExposureSymbols[ind+1:size(hspf.dynamicExposureUnits,1)]...)
    deleteat!(hspf.dynamicExposureUnits,ind)
    hspf.cummulativeDynamicExposure = hspf.cummulativeDynamicExposure[:, 1:end .!= ind]
  end
end
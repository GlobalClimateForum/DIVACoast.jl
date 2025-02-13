using NCDatasets
using DataStructures

export save_hsps_nc

function get_area_exposures(hspf :: HypsometricProfile{Float32}, elevations :: Array{DT}) where {DT <: Real}
  ret :: Array{Float32} = zeros(Float32, size(elevations,1)+1)
  for j in 1:size(elevations,1)
    ret[j+1] = exposure_below_bathtub(hspf,elevations[j])[1]
  end
  for j in size(elevations,1):-1:1
    ret[j+1] = ret[j+1] - ret[j]
  end
  return ret
end

function get_exposures(hspf :: HypsometricProfile{Float32}, elevations :: Array{DT}, t :: Int, pos :: Int) where {DT <: Real}
  ret :: Array{Float32} = zeros(Float32, size(elevations,1)+1)
  for j in 1:size(elevations,1)
    ret[j+1] = exposure_below_bathtub(hspf,elevations[j])[t][pos]
  end
  for j in size(elevations,1):-1:1
    ret[j+1] = ret[j+1] - ret[j]
  end
  return ret
end

function save_hsps_nc(data :: Dict{Int32, HypsometricProfile{Float32}}, filename :: String,  elevations :: Array{DT}, min_elevation :: Real, my_missing_value :: Real) where {DT <: Real}
  if (min_elevation >= elevations[1]) logg(logger,Logging.Error,@__FILE__,String(nameof(var"#self#")),"\n min_elevation should be smaller then elevations[1], but its not: $min_elevation $(elevations[1])") end
   
  ids = keys(data)
  ids_data = Float32[x for x in ids]
  elevation_data = copy(elevations)
  pushfirst!(elevation_data,min_elevation)

  ds_new = Dataset(filename,"c")
  
  defDim(ds_new,"ids",size(ids_data,1))
  defDim(ds_new,"elevations",size(elevation_data,1))

  nv = defVar(ds_new,"ids",Float32,("ids",), attrib = OrderedDict("units" => "number", "missing_value" => Float32(my_missing_value), "_FillValue" => Float32(my_missing_value)))
  nv[:] = ids_data
  nv = defVar(ds_new,"elevations",Float32,("elevations",), attrib = OrderedDict("units" => "m", "missing_value" => Float32(my_missing_value), "_FillValue" => Float32(my_missing_value)))
  nv[:] = elevation_data
 
  nv = defVar(ds_new,"width",Float32,("ids",), attrib = OrderedDict("units" => "km", "missing_value" => Float32(my_missing_value), "_FillValue" => Float32(my_missing_value)))
  width_data = map(hpsf -> hpsf.width, values(data))
  nv[:] = width_data

  exp_data = Array{Float32}(undef, size(ids_data,1), size(elevations,1)+1)
  nv = defVar(ds_new,"area",Float32,("ids","elevations"), attrib = OrderedDict("units" => "km^2", "missing_value" => Float32(my_missing_value), "_FillValue" => Float32(my_missing_value),"dynamic" => "false"))

  for i in 1:size(ids_data,1)
    exp_data[i,:]=get_area_exposures(data[convert(Int32, ids_data[i])],elevations)
  end
  nv[:] = exp_data

  for (index, se) in enumerate(string.(first(data)[2].staticExposureSymbols))
    nv = defVar(ds_new,se,Float32,("ids","elevations"), attrib = OrderedDict("units" => first(data)[2].staticExposureUnits[index], "missing_value" => Float32(my_missing_value), "_FillValue" => Float32(my_missing_value),"_FillValue" => Float32(my_missing_value),"dynamic" => "false"))  
    for i in 1:size(ids_data,1)
      exp_data[i,:]=get_exposures(data[convert(Int32, ids_data[i])],elevations,2,index)
    end
    nv[:] = exp_data
  end

  for (index, de) in enumerate(string.(first(data)[2].dynamicExposureSymbols))
    nv = defVar(ds_new,de,Float32,("ids","elevations"), attrib = OrderedDict("units" => first(data)[2].dynamicExposureUnits[index], "missing_value" => Float32(my_missing_value), "_FillValue" => Float32(my_missing_value),"_FillValue" => Float32(my_missing_value),"dynamic" => "true"))  
    for i in 1:size(ids_data,1)
      exp_data[i,:]=get_exposures(data[convert(Int32, ids_data[i])],elevations,3,index)
    end
    nv[:] = exp_data
  end

  close(ds_new)
end



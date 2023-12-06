using NetCDF

export save_hsps_nc

function save_hsps_nc(data :: Dict{Int32, HypsometricProfile{Float32}}, filename :: String,  elevations :: Array{DT}) where {DT <: Real}
  ids = keys(data)
  ids_data = Float32[x for x in ids]
  els = elevations
  
  # Define some attributes of the variable (optionlal)
  idsatts = Dict("longname" => "ids", "units" => "Integers")
  elsatts = Dict("longname" => "Elevations", "units" => "m")
  
  isfile(filename) && rm(filename)
  nccreate(
    filename,
      "ids_data","ids_data", ids_data, idsatts,
      "elevations","elevations", els, elsatts,
  )

  #ids_data = Float32[x for x in ids]
  #ncwrite(ids_data, filename, "ids")
  #ncwrite(els, filename, "elevations")

  areas = Array{Float32}(undef, size(ids,1), size(ids,2))

  for i in 1:size(ids,1)
    for j in 1:size(els,1)
      areas[i,j]=0
    end
  end

end


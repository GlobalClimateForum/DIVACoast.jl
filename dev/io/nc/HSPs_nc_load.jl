using NCDatasets
using DataStructures

export load_hsps_nc

# data :: Dict{Int32, HypsometricProfile{Float32}}, 
function load_hsps_nc(filename::String)
  ds = Dataset(filename, "r")

  if !haskey(ds, "elevations")
    println("The file has a variable 'temperature'")
  end
  el = ds["elevations"]

  for (varname, var) in ds
    # all variables
    @show (varname, size(var))
  end

  for (dimname, dim) in ds.dim
    # all dimensions
    @show (dimname, dim)
  end

  close(ds)
end



using NCDatasets
using DataStructures

export load_hsps_nc

function load_hsps_nc(::Type{IT}, ::Type{DT}, filename::String)::Dict{IT,HypsometricProfile{DT}} where {IT<:Integer,DT<:Real}
  ds = Dataset(filename, "r")

  if !haskey(ds, "ids")
    error("$filename has no variable 'ids'")
  end
  if !haskey(ds.dim, "ids")
    error("$filename has no dimension 'ids'")
  end
  ids::Array{IT} = convert(Array{IT}, ds["ids"])
  #println(ids)

  if !haskey(ds, "elevations")
    error("$filename has no variable 'elevations'")
  end
  if !haskey(ds.dim, "elevations")
    error("$filename has no dimension 'elevations'")
  end
  el::Array{DT} = convert(Array{DT}, ds["elevations"])

  if !haskey(ds, "width")
    error("$filename has no dimension 'width'")
  end
  if size(ds["width"],1)!=size(ids,1) error("variable 'width' in $filename has wrong dimension ($(size(ds["width"],1))) - it should have ($(size(ids,1)))") end
  width::Array{DT} = convert(Array{DT}, ds["width"])

  if !haskey(ds, "area")
    error("$filename has no variable 'area'")
  end
  area_nc = ds["area"]
  if size(area_nc,1)!=size(ids,1) error("variable 'area' in $filename has wrong dimensions ($(size(area_nc,1)),$(size(area_nc,2))) - it should have ($(size(ids,1)),$(size(elevations,1)))") end

  hpsf_data :: Dict{IT,HypsometricProfile{DT}} = Dict()
  static_exp = Array{NCDatasets.CFVariable}(undef, 0)
  static_exp_names = Array{String}(undef, 0)
  dynamic_exp = Array{NCDatasets.CFVariable}(undef, 0)
  dynamic_exp_names = Array{String}(undef, 0)

  for (varname, var) in ds
    #    # all variables
    #    @show (varname, size(var))
    if (varname != "ids" && varname != "elevations")
      if haskey(var.attrib, "static") && lowercase(var.attrib["static"]) == "true"
        push!(static_exp,var)
        push!(static_exp_names,varname)
      end
      if haskey(var.attrib, "dynamic") && lowercase(var.attrib["dynamic"]) == "true"
        push!(dynamic_exp,var)
        push!(dynamic_exp_names,varname)
      end
    end
  end

  for i in 1:size(ids,1)
    area::Array{DT} = convert(Array{DT},area_nc[i,:])
    s_exposure :: Array{DT,2} = Array{DT, 2}(undef, size(el,1), size(static_exp,1))
    d_exposure :: Array{DT,2} = Array{DT, 2}(undef, size(el,1), size(dynamic_exp,1))
    for j in 1:size(static_exp,1)
      s_exposure[:,j] = convert(Array{DT},static_exp[j][i,:])
    end
    for j in 1:size(dynamic_exp,1)
      d_exposure[:,j] = convert(Array{DT},dynamic_exp[j][i,:])
    end
    hpsf = HypsometricProfile(width[i], el, area, s_exposure, d_exposure, static_exp_names, dynamic_exp_names) 
    hpsf_data[ids[i]] = hpsf
  end

  close(ds)
  return hpsf_data 
end



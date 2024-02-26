using NCDatasets
using DataStructures

export load_hsps_nc

"""
    load_hsps_nc(::Type{IT}, ::Type{DT}, filename::String)::Dict{IT,HypsometricProfile{DT}} where {IT<:Integer,DT<:Real}

Load a netcdf file into hypsometric profiles. IT is the indextype (an integer type which is used to adress a specific profile), DT is
the datatype (a floating point type which is used to store the data internally). Hypsometric profiles are not compressed.

# Examples
```julia-repl
julia> test = load_hsps_nc(Int32, Float32, "test.nc")
Dict{Int32, HypsometricProfile{Float32}} with 2716 entries:
  2108 => HypsometricProfile{Float32}(1.0, Float32[-5.0, -4.9, -4.8, -4.7, -4.6, -4.5, -4.4, -4.3, -4.2, -4.1  …  19.1, 19.2, 19.3, 19.4, 19.5, 19.6, 19.7, 19.8, 19.9, 20.0], Float32[0.0, 0.0, 0.0, 0.0, …
```
"""
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
  el_unit::String = if haskey(ds["elevations"].attrib, "unit")
    ds["elevations"].attrib["unit"]
  else
    "m"
  end

  if !haskey(ds, "width")
    error("$filename has no variable 'width'")
  end
  if size(ds["width"], 1) != size(ids, 1)
    error("variable 'width' in $filename has wrong dimension ($(size(ds["width"],1))) - it should have ($(size(ids,1)))")
  end
  width::Array{DT} = convert(Array{DT}, ds["width"])
  width_unit::String = if haskey(ds["width"].attrib, "unit")
    ds["width"].attrib["unit"]
  else
    "km"
  end

  if !haskey(ds, "area")
    error("$filename has no variable 'area'")
  end
  area_nc = ds["area"]
  if size(area_nc, 1) != size(ids, 1)
    error("variable 'area' in $filename has wrong dimensions ($(size(area_nc,1)),$(size(area_nc,2))) - it should have ($(size(ids,1)),$(size(elevations,1)))")
  end
  area_unit::String = if haskey(ds["area"].attrib, "unit")
    ds["area"].attrib["unit"]
  else
    "km^2"
  end

  hpsf_data::Dict{IT,HypsometricProfile{DT}} = Dict()
  static_exp = Array{NCDatasets.CFVariable}(undef, 0)
  static_exp_names = Array{String}(undef, 0)
  static_exp_units = Array{String}(undef, 0)
  dynamic_exp = Array{NCDatasets.CFVariable}(undef, 0)
  dynamic_exp_names = Array{String}(undef, 0)
  dynamic_exp_units = Array{String}(undef, 0)

  for (varname, var) in ds
    #    # all variables
    #    @show (varname, size(var))
    if (varname != "ids" && varname != "elevations")
      if haskey(var.attrib, "static") && lowercase(var.attrib["static"]) == "true"
        push!(static_exp, var)
        push!(static_exp_names, varname)
        if haskey(var.attrib, "unit")
          push!(static_exp_units, var.attrib["unit"])
        else
          push!(static_exp_units, "")
        end
      end
      if haskey(var.attrib, "dynamic") && lowercase(var.attrib["dynamic"]) == "true"
        push!(dynamic_exp, var)
        push!(dynamic_exp_names, varname)
        if haskey(var.attrib, "unit")
          push!(dynamic_exp_units, var.attrib["unit"])
        else
          push!(dynamic_exp_units, "")
        end
      end
    end
  end

  for i in 1:size(ids, 1)
    area::Array{DT} = convert(Array{DT}, area_nc[i, :])
    s_exposure::Array{DT,2} = Array{DT,2}(undef, size(el, 1), size(static_exp, 1))
    d_exposure::Array{DT,2} = Array{DT,2}(undef, size(el, 1), size(dynamic_exp, 1))
    for j in 1:size(static_exp, 1)
      s_exposure[:, j] = convert(Array{DT}, static_exp[j][i, :])
    end
    for j in 1:size(dynamic_exp, 1)
      d_exposure[:, j] = convert(Array{DT}, dynamic_exp[j][i, :])
    end
    hpsf_data[ids[i]] = HypsometricProfile(width[i], width_unit, copy(el), el_unit, area, area_unit, s_exposure, static_exp_names, static_exp_units, d_exposure, dynamic_exp_names, dynamic_exp_units)
#    hpsf_data[ids[i]] = HypsometricProfile(width[i], width_unit, el, el_unit, area, area_unit, s_exposure, static_exp_names, static_exp_units, d_exposure, dynamic_exp_names, dynamic_exp_units)
  end

  close(ds)
  return hpsf_data
end



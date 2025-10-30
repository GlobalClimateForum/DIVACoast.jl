using ArchGDAL
using StaticArrays
using GDAL
using CoordinateTransformations
using GeoFormatTypes
using GeoArrays


function is_circular(ga::GeoArray)
  return false
end

function no_data_value(ga::GeoArray)
  return parse(eltype(ga), ga.metadata["NoData Value"]["NoData Value"])
end

function set_no_data_value(ga::GeoArray{E,N,C}, value) where {E,N,C<:AbstractArray} 
  ga.metadata["NoData Value"]["NoData Value"] = string(value)
  ga.A.no_data=value
end

function set_no_data_value(ga::GeoArray{E,N,Array{E}}, value) where {N,E<:Number}
  ga.metadata["NoData Value"]["NoData Value"] = string(value)
end

filename(ga::GeoArray) = ga.metadata["FILENAME"]["FILENAME"]
pixelsize_x(ga::GeoArray) = ga.f.linear[1, 1]
pixelsize_y(ga::GeoArray) = ga.f.linear[2, 2]

empty_geo_array(::Type{C}) where {C<:AbstractArray} = GeoArray(C(-9999, 1, 1), GeoArrays.geotransform_to_affine(SVector(0.0, 1.0, 0.0, 0.0, 0.0, 1.0)), GeoFormatTypes.WellKnownText(GeoFormatTypes.CRS(), ""), Dict{String,Any}())
empty_geo_array(::Type{Array{E}}) where {E<:Number} = GeoArray(Array{E}(undef, 1, 1), GeoArrays.geotransform_to_affine(SVector(0.0, 1.0, 0.0, 0.0, 0.0, 1.0)), GeoFormatTypes.WellKnownText(GeoFormatTypes.CRS(), ""), Dict{String,Any}())
empty_geo_array(::Type{Matrix{E}}) where {E<:Number} = GeoArray(Array{E}(undef, 1, 1), GeoArrays.geotransform_to_affine(SVector(0.0, 1.0, 0.0, 0.0, 0.0, 1.0)), GeoFormatTypes.WellKnownText(GeoFormatTypes.CRS(), ""), Dict{String,Any}())

empty_geo_array(::Type{C}, x::Int, y::Int) where {C<:AbstractArray} = GeoArray(C(-9999, x, y), GeoArrays.geotransform_to_affine(SVector(0.0, 1.0, 0.0, 0.0, 0.0, 1.0)), GeoFormatTypes.WellKnownText(GeoFormatTypes.CRS(), ""), Dict{String,Any}())
empty_geo_array(::Type{Array{E}}, x::Int, y::Int) where {E<:Number} = GeoArray(Array{E}(undef, x, y), GeoArrays.geotransform_to_affine(SVector(0.0, 1.0, 0.0, 0.0, 0.0, 1.0)), GeoFormatTypes.WellKnownText(GeoFormatTypes.CRS(), ""), Dict{String,Any}())

empty_geo_array(::Type{C}, x::Int, y::Int, ndv) where {C<:AbstractArray} = GeoArray(C(ndv, x, y), GeoArrays.geotransform_to_affine(SVector(0.0, 1.0, 0.0, 0.0, 0.0, 1.0)), GeoFormatTypes.WellKnownText(GeoFormatTypes.CRS(), ""), Dict{String,Any}())
function empty_geo_array(::Type{Array{E}}, x::Int, y::Int, ndv) where {E<:Number}
  ret = GeoArray(Array{E}(undef, x, y), GeoArrays.geotransform_to_affine(SVector(0.0, 1.0, 0.0, 0.0, 0.0, 1.0)), GeoFormatTypes.WellKnownText(GeoFormatTypes.CRS(), ""), Dict{String,Any}())
  ret .= ndv
  return ret
end

empty_geo_array(ga::GeoArray{E,N,C}, x::Int, y::Int, ndv) where {E,N,C<:AbstractArray} = GeoArray(C(ndv, x, y), GeoArrays.geotransform_to_affine(SVector(0.0, 1.0, 0.0, 0.0, 0.0, 1.0)), GeoFormatTypes.WellKnownText(GeoFormatTypes.CRS(), ""), Dict{String,Any}())
function empty_geo_array(ga::GeoArray{E,N,Array{E}}, x::Int, y::Int, ndv) where {N,E<:Number}
  ret = GeoArray(Array{E}(undef, x, y), GeoArrays.geotransform_to_affine(SVector(0.0, 1.0, 0.0, 0.0, 0.0, 1.0)), GeoFormatTypes.WellKnownText(GeoFormatTypes.CRS(), ""), Dict{String,Any}())
  ret .= ndv
  return ret
end


"""
        empty_copy_from_geo_array(::Type{C}, ga::GeoArray{E,N,T}) where {T,E,N,C}
        empty_copy_from_geo_array(::Type{C}, ga::GeoArray{E,N,T}, ndv::E) where {T,E,N,C}
        empty_copy_from_geo_array(::Type{C}, ga::GeoArray{E,N,T}, ul, ur, ll, lr) where {T,E,N,C}
        empty_copy_from_geo_array(::Type{C}, ga::GeoArray{E,N,T}, ndv::E, ul, ur, ll, lr) where {T,E,N,C} 

        Creates an empty GeoArray from an existing GA with same metadta 

but with  a new extent defined by `extentNew` and
empty data.

# Arguments
- `orgSGA::SparseGeoArray{DT,IT}`: The original SparseGeoArray from which metadata is copied.
- `extentNew`: The new extent for the SparseGeoArray, defines as a named tuple with keys `uppL`, `uppR`, `lwrL`, and `lwrR` representing the upper left, upper right, lower left, and lower right corners of the new extent.

# Returns
- A new `SparseGeoArray{DT,IT}`

# Example
```julia
emptySGAfromSGA(orgSGA, (uppL=(0.0, 10.0), uppR=(10.0, 10.0), lwrL=(0.0, 0.0), lwrR=(10.0, 0.0)))
```
"""
function empty_copy_from_geo_array(::Type{Array{T}}, ga::GeoArray{E,N,C}) where {T,E,N,C}
  ret = GeoArray(Array{T}(undef, size(ga)[1], size(ga)[2]))
  ret.f = ga.f
  ret.crs = ga.crs
  ret.metadata = ga.metadata
  return ret
end

function empty_copy_from_geo_array(::Type{Matrix{T}}, ga::GeoArray{E,N,C}) where {T,E,N,C}
  ret = GeoArray(Array{T}(undef, size(ga)[1], size(ga)[2]))
  ret.f = ga.f
  ret.crs = ga.crs
  ret.metadata = ga.metadata
  return ret
end


function empty_copy_from_geo_array(::Type{C}, ga::GeoArray{E,N,T}) where {C,E,N,T}
  ret = GeoArray(C(no_data_value(ga), size(ga)[1], size(ga)[2]))
  ret.f = ga.f
  ret.crs = ga.crs
  ret.metadata = ga.metadata
  return ret
end

# explicit initialisation with no_data
function empty_copy_from_geo_array(t::Type{Array{T}}, ga::GeoArray{E,N,C}, ndv::E) where {T,E,N,C}
  ret = empty_copy_from_geo_array(t, ga)
  ret.A .= ndv
  return ret
end

function empty_copy_from_geo_array(t::Type{Matrix{T}}, ga::GeoArray{E,N,C}, ndv::E) where {T,E,N,C}
  ret = empty_copy_from_geo_array(t, ga)
  ret.A .= ndv
  return ret
end

empty_copy_from_geo_array(::Type{C}, ga::GeoArray{E,N,T}, ndv::E) where {C,E,N,T} = empty_copy_from_geo_array(C, ga)


# explicit extent
function empty_copy_from_geo_array(::Type{Array{T}}, ga::GeoArray{E,N,C}, ul, ur, ll, lr) where {T,E,N,C}
  t = SVector(ul[1], ul[2])
  l = ga.f.linear * SMatrix{2,2}([1 0; 0 1])
  xs = round(abs(ul[1] - ur[1]) / abs(pixelsize_x(ga)), digits=0)
  ys = round(abs(ul[2] - ll[2]) / abs(pixelsize_y(ga)), digits=0)
  ret = GeoArray(Array{T}(undef, xs, ys))
  ret.f = AffineMap(l, t)
  ret.crs = ga.crs
  ret.metadata = ga.metadata
  return ret
end

function empty_copy_from_geo_array(::Type{C}, ga::GeoArray{E,N,T}, ul, ur, ll, lr) where {T,E,N,C}
  t = SVector(ul[1], ul[2])
  l = ga.f.linear * SMatrix{2,2}([1 0; 0 1])
  xs = round(abs(ul[1] - ur[1]) / abs(pixelsize_x(ga)), digits=0)
  ys = round(abs(ul[2] - ll[2]) / abs(pixelsize_y(ga)), digits=0)
  ret = GeoArray(C(no_data_value(ga), xs, ys))
  ret.f = AffineMap(l, t)
  ret.crs = ga.crs
  ret.metadata = ga.metadata
  return ret
end

function empty_copy_from_geo_array(t::Type{Array{T}}, ga::GeoArray{E,N,C}, ndv::T, ul, ur, ll, lr) where {T,E,N,C}
  ret = empty_copy_from_geo_array(t, ga, ul, ur, ll, lr)
  ret.A .= ndv
  return ret
end

empty_copy_from_geo_array(t::Type{C}, ga::GeoArray{E,N,T}, ndv, ul, ur, ll, lr) where {T,E,N,C} = empty_copy_from_geo_array(t, ga, ul, ur, ll, lr)


# as before, but the type is taken from the input ga
function empty_copy_from_geo_array(ga::GeoArray{E,N,Array{E}}) where {E,N}
  ret = GeoArray(Array{E}(undef, size(ga)[1], size(ga)[2]))
  ret.f = ga.f
  ret.crs = ga.crs
  ret.metadata = ga.metadata
  return ret
end

function empty_copy_from_geo_array(ga::GeoArray{E,N,C}) where {E,N,C}
  ret = GeoArray(C(no_data_value(ga), size(ga)[1], size(ga)[2]))
  ret.f = ga.f
  ret.crs = ga.crs
  ret.metadata = ga.metadata
  return ret
end

function empty_copy_from_geo_array(ga::GeoArray{E,N,Array{E}}, ndv::E) where {E,N}
  ret = empty_copy_from_geo_array(ga)
  ret.A .= ndv
  return ret
end

empty_copy_from_geo_array(ga::GeoArray{E,N,C}, ndv::E) where {C,E,N} = empty_copy_from_geo_array(ga)

function empty_copy_from_geo_array(ga::GeoArray, xs::Int, ys::Int, ul, ndv) 
  ret = empty_geo_array(ga, xs, ys, ndv)
  t = SVector(ul[1], ul[2])
  l = ga.f.linear * SMatrix{2,2}([1 0; 0 1])
  ret.f = AffineMap(l, t)
  ret.crs = ga.crs
  ret.metadata = ga.metadata
  return ret
end


function ga_dimension_match(ga1::GeoArray, ga2::GeoArray; do_log=false)::Bool
  if do_log
    if ((size(ga1, 1) != size(ga2, 1)) || (size(ga1, 2) != size(ga2, 2)))
      error("DimensionError: ($(size(ga1,1))×$(size(ga1,2))) and ($(size(ga2,1))×$(size(ga2,2)))")
    end
    if (ga1.crs != ga2.crs)
      error("ProjRefError: ($(ga1.crs)) and ($(ga2.crs))")
    end
    if (ga1.f != ga2.f)
      error("GeoTransfomError: ($(ga1.f)) and ($(ga2.f))")
    end
  end
  return (size(ga1, 1) == size(ga2, 1)) && (size(ga1, 2) == size(ga2, 2)) && (ga1.f == ga2.f)
end

function clear_data!(a::Array{E}) where {E}
  # does not make sence for usual Array - thus does not do anything
end

function clear_data!(ga::GeoArray{E,N,C}) where {C,E,N}
  clear_data!(ga.A)
end

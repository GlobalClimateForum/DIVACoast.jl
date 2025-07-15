#import GeoFormatTypes as GFT
using GDAL
using CoordinateTransformations
using StaticArrays
using GeoArrays

"""
    SparseGeoArray{DT,IT}(filename::String, band::Integer=1) where {DT <: Real, IT <: Integer}

A `SparseGeoArray` combines spatial data with geospatial information for referencing. The data itself is stored in a efficient (sparse) format, so only the non-empty grid cells are stored. The geospatial information is stored in a `CoordinateTransformations.AffineMap` object, which is used to transform between pixel coordinates and geospatial coordinates. 

The `SparseGeoArray` is a mutable struct that contains the following attributes:
- `data`: a dictionary that stores the data values for each pixel in the grid. The keys are tuples of pixel coordinates (x,y), and the values are the data values.
- `nodatavalue`: a value that represents missing or invalid data in the grid. This value is used to identify empty cells in the grid.
- `f`: a `CoordinateTransformations.AffineMap` object that defines the transformation between pixel coordinates and geospatial coordinates.
- `crs`: a `GeoFormatTypes.WellKnownText` object that defines the coordinate reference system (CRS) for the data. This is used to interpret the geospatial coordinates correctly.
- `metadata`: a dictionary that stores additional metadata about the data, such as the source of the data or the date it was collected.
- `xsize`: the number of pixels in the x-direction (width) of the grid.
- `ysize`: the number of pixels in the y-direction (height) of the grid.
- `projref`: a string that represents the projection reference for the data.
- `filename`: a string that represents the filename of the data file.

  
"""
Base.@kwdef mutable struct SparseGeoArray{DT <: Real, IT <: Integer}  # <: AbstractGeoArray? 
  data :: Dict{Tuple{IT, IT}, DT}
  nodatavalue :: DT
  f::CoordinateTransformations.AffineMap{StaticArrays.SMatrix{2,2,Float64,4},StaticArrays.SVector{2,Float64}}
  crs :: GFT.WellKnownText{GFT.CRS}
  metadata :: Dict{String, Any} = Dict{String,Any}()
  xsize :: IT = 0
  ysize :: IT = 0
  projref :: String = ""
  circular :: Bool = false
  filename :: String = ""
end


SparseGeoArray{DT,IT}() where {DT <: Real, IT <: Integer} = SparseGeoArray{DT,IT}(Dict{Tuple{IT,IT},DT}(), convert(DT,-Inf), geotransform_to_affine(SVector(0.0, 1.0, 0.0, 0.0, 0.0, 1.0)), GFT.WellKnownText(GFT.CRS(), ""), Dict{String, Any}(), convert(IT,0), convert(IT,0), "", false, "")

function SparseGeoArray{DT,IT}(filename :: String, band :: Integer = 1) where {DT <: Real, IT <: Integer} 
  sga = SparseGeoArray{DT,IT}()
  sga.filename = filename
  read_geotiff_data_complete!(sga,filename,band,1)
  sga
end

function empty_copy(sga :: SparseGeoArray{DT,IT}) :: SparseGeoArray{DT,IT} where {DT <: Real, IT <: Integer} 
  return SparseGeoArray{DT,IT}(Dict{Tuple{IT,IT},DT}(), sga.nodatavalue,sga.f,sga.crs,sga.metadata,sga.xsize,sga.ysize,sga.projref,sga.circular,sga.filename)
end


# Behave like an Array
Base.size(sga::SparseGeoArray) = (sga.xsize,sga.ysize)
Base.IndexStyle(::Type{<:SparseGeoArray}) = IndexCartesian()
#Base.similar(sga::SparseGeoArray, t::Type) = SparseGeoArray(similar(ga.A, t), ga.f, ga.crs, ga.metadata)
Base.iterate(sga::SparseGeoArray) = iterate(sga.data)
Base.iterate(sga::SparseGeoArray, state) = iterate(sga.data, state)
Base.length(sga::SparseGeoArray) = length(sga.data)
Base.parent(sga::SparseGeoArray) = Any
Base.eltype(::Type{SparseGeoArray{DT,IT}}) where {DT,IT} = DT
Base.show(io::IO, ::MIME"text/plain", sga::SparseGeoArray) = show(io, sga)

function Base.size(sga::SparseGeoArray, i :: Integer) 
 if i==1 return sga.xsize end
 if i==2 return sga.ysize end
 return 1
end

function Base.convert(::Type{SparseGeoArray{DT,IT}}, sga :: SparseGeoArray) where {DT, IT} 
  data = convert(Dict{Tuple{IT,IT}, DT}, sga.data)
  SparseGeoArray(data, convert(DT,sga.nodatavalue), sga.f, sga.crs, sga.metadata, convert(IT,sga.xsize), convert(IT,sga.ysize), sga.projref, sga.circular, sga.filename)
end

#find_ga(bc::Base.Broadcast.Broadcasted) = find_ga(bc.args)
#find_ga(bc::Base.Broadcast.Extruded) = find_ga(bc.x)
#find_ga(args::Tuple) = find_ga(find_ga(args[1]), Base.tail(args))
#find_ga(x) = x
#find_ga(::Tuple{}) = nothing
#find_ga(a::GeoArray, rest) = a
#find_ga(::Any, rest) = find_ga(rest)

# Getindex
"""
    getindex(sga::SparseGeoArray, i::AbstractRange, j::AbstractRange, k::Union{Colon,AbstractRange,Integer})

Index a SparseGeoArray with `AbstractRange`s to get a cropped SparseGeoArray with the correct `AffineMap` set.

# Examples
```julia-repl
julia> sga[2:3,2:3]
2x2x1 Array{Float64, 3} with AffineMap([1.0 0.0; 0.0 1.0], [1.0, 1.0]) and undefined CRS
```
"""
function Base.getindex(sga :: SparseGeoArray{DT, IT}, xrange::AbstractRange, yrange::AbstractRange) :: SparseGeoArray{DT, IT} where {DT <: Real, IT <: Integer} 
  data :: Dict{Tuple{IT,IT}, DT} = Dict{Tuple{IT,IT}, DT}()
  # choose the method that is faster for the given data
  if (size(xrange)[1]*size(yrange)[1] < length(sga.data))
    for y in yrange
      for x in xrange
        v :: DT = get(sga.data, (x,y), sga.nodatavalue)
        if (v != sga.nodatavalue) data[(x-first(xrange)+1,y-first(yrange)+1)]=v end
      end
    end
  else
    for (ind, v) in sga.data
      if (first(xrange)<ind[1] && ind[1]<last(xrange) && first(yrange)<ind[2] && ind[2]<last(yrange))
        data[(ind[1]-first(xrange)+1,ind[2]-first(yrange)+1)]=v
      end
    end
  end
  x, y = first(xrange) - 1, first(yrange) - 1
  t = sga.f(SVector(x, y))
  l = sga.f.linear * SMatrix{2,2}([step(yrange) 0; 0 step(xrange)])
  SparseGeoArray{DT,IT}(data, sga.nodatavalue, AffineMap(l, t), sga.crs, sga.metadata, convert(IT,size(xrange,1)), convert(IT,size(yrange,1)), sga.projref, sga.circular, sga.filename)
end

function Base.getindex(sga :: SparseGeoArray{DT, IT}, indices::Vararg{Integer,2}) :: DT where {DT <: Real, IT <: Integer} 
  if ((indices[1]<=0) || (indices[1]>sga.xsize) || (indices[2]<=0) || (indices[2]>sga.ysize))
    error("BoundsError: attempt to access $(sga.xsize)×$(sga.ysize) SparseGeoArray{$DT,$IT} at index [$(indices[1]), $(indices[2])]")
  end
  get(sga.data, (indices[1],indices[2]), sga.nodatavalue)
end

function Base.getindex(sga :: SparseGeoArray{DT, IT}, indices :: Tuple{IT,IT}) :: DT where {DT <: Real, IT <: Integer} 
  if ((indices[1]<=0) || (indices[1]>sga.xsize) || (indices[2]<=0) || (indices[2]>sga.ysize))
    error("BoundsError: attempt to access $(sga.xsize)×$(sga.ysize) SparseGeoArray{$DT,$IT} at index [$(indices[1]), $(indices[2])]")
  end
  get(sga.data, (indices[1],indices[2]), sga.nodatavalue)
end

function Base.setindex!(sga :: SparseGeoArray{DT, IT}, v :: DT, indices::Vararg{IT,2}) where {DT <: Real, IT <: Integer} 
  if ((indices[1]<=0) || (indices[1]>sga.xsize) || (indices[2]<=0) || (indices[2]>sga.ysize))
    error("BoundsError: attempt to access $(sga.xsize)×$(sga.ysize) SparseGeoArray{$DT,$IT} at index [$(indices[1]), $(indices[2])]")
  end
  sga.data[(indices[1],indices[2])] = v
end

Base.setindex!(sga :: SparseGeoArray{DT, IT}, v::DT, indices::Tuple{IT,IT})      where {DT <: Real, IT <: Integer} = setindex!(sga, v, indices[1], indices[2])
Base.setindex!(sga :: SparseGeoArray{DT, IT}, v, indices::Vararg{Integer,2})      where {DT <: Real, IT <: Integer} = setindex!(sga, convert(DT,v), convert(IT,indices[1]), convert(IT,indices[2]))
Base.setindex!(sga :: SparseGeoArray{DT, IT}, v, indices::Tuple{Integer,Integer}) where {DT <: Real, IT <: Integer} = setindex!(sga, convert(DT,v), convert(IT,indices[1]), convert(IT,indices[2]))


function Base.show(io::IO, sga::SparseGeoArray)
  crs = GFT.val(sga.crs)
  wkt = isempty(crs) ? "undefined CRS" : "CRS $crs"
  println(io, "$(join(size(sga), "x")) SparseGeoRaster implemented as $(typeof(sga.data)) with $(wkt)")
  println(io, "projref: $(sga.projref)")
  print(io, "aft: $(sga.f); nodatavalue: $(sga.nodatavalue); stored values: $(length(sga.data))")
end

"""
    crop!(sga::SparseGeoArray{DT, IT}, bbox::NamedTuple{(:min_x, :min_y, :max_x, :max_y)}) where {DT <: Real, IT <: Integer}
Crop a `SparseGeoArray` to the bounding box defined by `bbox`. The bounding box is defined by the minimum and maximum x and y coordinates. The function modifies the `SparseGeoArray` in place.

# Arguments
- `sga`: The `SparseGeoArray` to crop.
- `bbox`: A `NamedTuple` with the keys `:min_x`, `:min_y`, `:max_x`, and `:max_y` defining the bounding box.

# Returns
- Returns nothing, since the function modifies the `SparseGeoArray` in place.

# Example
```julia
crop!(sga, (min_x=10, min_y=20, max_x=30, max_y=40))
```
"""
function crop!(sga::SparseGeoArray{DT, IT}, bbox::NamedTuple{(:min_x, :min_y, :max_x, :max_y)}) where {DT <: Real, IT <: Integer}
  for (coordinates, d) in sga.data
    if ((coordinates[1]<bbox.min_x) || (coordinates[1]>bbox.max_x) || (coordinates[2]<bbox.min_y) || (coordinates[2]>bbox.max_y))
      delete!(sga.data, coordinates)
    end
  end

  data :: Dict{Tuple{IT,IT}, DT} = Dict{Tuple{IT,IT}, DT}()
  for (coordinates, d) in sga.data
    data[(coordinates[1]-bbox.min_x+1,coordinates[2]-bbox.min_y+1)] = d
    delete!(sga.data, coordinates)
  end
  sga.data = data

  t = sga.f(SVector(bbox.min_x-1, bbox.min_y-1))
  l = sga.f.linear * SMatrix{2,2}([1 0; 0 1])
  sga.xsize=bbox.max_x-bbox.min_x+1
  sga.ysize=bbox.max_y-bbox.min_y+1
  sga.f = AffineMap(l, t)
end 

"""
    crop!(sga::SparseGeoArray{DT, IT}; margin_x :: Integer = 0, margin_y :: Integer = 0) where {DT <: Real, IT <: Integer}

Crop a `SparseGeoArray` to its minimum data extent and optional margins around the extent. 

# Arguments
- `sga`: The `SparseGeoArray` to crop.
- `margin_x`: An optional integer specifying the margin to add to the left and right of the extent. Defaults to 0.
- `margin_y`: An optional integer specifying the margin to add to the top and bottom of the extent. Defaults to 0.

# Returns
- Returns nothing, since the function modifies the `SparseGeoArray` in place.

# Example
```julia
crop!(sga, margin_x=5, margin_y=10)
```
"""
function crop!(sga::SparseGeoArray{DT, IT}; margin_x :: Integer = 0, margin_y :: Integer = 0) where {DT <: Real, IT <: Integer}
  max_x = 1
  min_x = sga.xsize
  max_y = 1
  min_y = sga.ysize
  for (coordinates, elevation) in sga.data
    if (coordinates[1]<min_x) min_x=coordinates[1] end
    if (coordinates[1]>max_x) max_x=coordinates[1] end
    if (coordinates[2]<min_y) min_y=coordinates[2] end
    if (coordinates[2]>max_y) max_y=coordinates[2] end
  end
  min_x = (min_x-margin_x < 1) ? 1 : min_x-margin_x
  min_y = (min_y-margin_y < 1) ? 1 : min_y-margin_y  
  max_x = (max_x+margin_x > sga.xsize) ? sga.xsize : max_x+margin_x
  max_y = (max_y+margin_y > sga.ysize) ? sga.ysize : max_y+margin_y

  crop!(sga,(min_x=min_x, min_y=min_y, max_x=max_x, max_y=max_y))
end

clear_data!(sga) = empty!(sga.data)

function hard_reset!(sga :: SparseGeoArray{DT,IT}) where {DT <: Real, IT <: Integer} 
  sga = SparseGeoArray{DT,IT}()  
end


"""
    coords(sga::SparseGeoArray, p::SVector{2,<:Integer}, strategy::AbstractStrategy=Center())
    coords(sga::SparseGeoArray, p::Tuple{<:Integer,<:Integer}, strategy::AbstractStrategy=Center())
    coords(sga::SparseGeoArray, p::CartesianIndex{2}, strategy::AbstractStrategy=Center())`

Retrieve geospatial coordinates of the cell represented by indices `p` in a `SparseGeoArray`.
The coordinates are returned as a `SVector{2}`. The `strategy` parameter determines how the coordinates are calculated, e.g., whether they are centered or aligned with the upper left corner of the cell. See `indices` for the inverse function.

# Arguments
- `sga`: The `SparseGeoArray` to retrieve coordinates from.
- `p`: The pixel indices as a `SVector{2}` of integers, a tuple of integers, or a `CartesianIndex{2}`.
- `strategy`: An optional parameter that determines how the coordinates are calculated. Defaults to `Center()`, which returns the center of the cell. Other strategies include `UpperLeft()`, `UpperRight()`, `LowerLeft()`, and `LowerRight()`.

# Returns
- Returns a `SVector{2}` containing the geospatial coordinates of the cell represented by the indices `p`.

# Example
```julia

```
"""
function coords(sga::SparseGeoArray, p::SVector{2,<:Integer}, strategy::GeoArrays.AbstractStrategy)
    SVector{2}(sga.f(p .- (1,1) .+ strategy.offset))
end
coords(sga::SparseGeoArray, p::Vector{<:Integer}, strategy::GeoArrays.AbstractStrategy=Center()) = coords(sga, SVector{2}(p), strategy)
coords(sga::SparseGeoArray, p::Tuple{<:Integer,<:Integer}, strategy::GeoArrays.AbstractStrategy=Center()) = coords(sga, SVector{2}(p), strategy)
coords(sga::SparseGeoArray, i :: IT, j :: IT, strategy::GeoArrays.AbstractStrategy=Center()) where {IT <: Integer} = coords(sga, SVector{2}(i,j), strategy)

"""
    indices(sga::SparseGeoArray, p::SVector{2,<:Real})

Retrieve indices of the cell represented by geospatial coordinates `p`.
See `coords` for the inverse function.

# Arguments
- `sga`: The `SparseGeoArray` to retrieve indices from.
- `p`: The geospatial coordinates as a `SVector{2}` of real numbers, a tuple of real numbers, or an `AbstractVector{<:Real}`.

# Returns
- Returns a `Tuple{IT, IT}` containing the indices of the cell represented by the geospatial coordinates `p`.

# Example
```julia
indices(sga, (12.34, 56.78))
```
"""
function indices(sga :: SparseGeoArray{DT, IT}, p::SVector{2,<:Real}) :: Tuple{IT,IT} where {DT <: Real, IT <: Integer} 
    Tuple(floor.(Int, inv(sga.f)(p)) .+ (1,1))
end
indices(sga::SparseGeoArray, p::AbstractVector{<:Real}) = indices(sga, SVector{2}(p))
indices(sga::SparseGeoArray, p::Tuple{<:Real,<:Real}) = indices(sga, SVector{2}(p))
indices(sga::SparseGeoArray, i :: R, j :: R, strategy::GeoArrays.AbstractStrategy=Center()) where {R <: Real} = indices(sga, SVector{2}(i,j))

"""
    area(sga::SparseGeoArray, i::I, j::I) where {I <: Integer}
    area(sga :: SparseGeoArray, p::Tuple{<:Integer,<:Integer}) = area(sga, p[1], p[2])

Calculate the area of the cell at pixel indices `(i, j)` in a `SparseGeoArray`. The area is calculated using the Haversine formula, which accounts for the curvature of the Earth.

# Arguments
- `sga`: The `SparseGeoArray` containing the geospatial data.
- `i`: The pixel index in the x-direction.
- `j`: The pixel index in the y-direction.

# Returns
- Returns the area of the cell.

# Example
```julia
area(sga, 10, 20)
```
"""
function area(sga :: SparseGeoArray, i :: I, j :: I) where {I <: Integer} 
  ul = coords(sga,i,j,UpperLeft())
  lr = coords(sga,i,j,LowerRight())
  lambda_diff_rad = (lr[1] - ul[1]) * pi / 180

  sin_phi1 = sin(ul[2] * pi / 180)
  sin_phi2 = sin(lr[2] * pi / 180)

  rr = earth_radius_km * earth_radius_km;
  return rr * lambda_diff_rad * abs(sin_phi2 - sin_phi1)
end

area(sga :: SparseGeoArray, p::Tuple{<:Integer,<:Integer}) = area(sga, p[1], p[2])
area(sga :: SparseGeoArray, p::Tuple{I,I}) where {I <: Integer} = area(sga, p[1], p[2])

pixelsize_x(sga :: SparseGeoArray) = sga.f.linear[1,1]
pixelsize_y(sga :: SparseGeoArray) = sga.f.linear[2,2]




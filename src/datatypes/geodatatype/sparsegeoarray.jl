#import GeoFormatTypes as GFT
using GDAL
using CoordinateTransformations
using StaticArrays

"""
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
        data[(ind[1]-first(xrange)+1,ind[2] -first(yrange)+1)]=v
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


# Coordinates and indices
abstract type AbstractStrategy end
struct Center <: AbstractStrategy
    offset :: SVector{2}
    Center() = new(SVector{2}(0.5,0.5))
end
struct UpperLeft <: AbstractStrategy
    offset :: SVector{2}
    UpperLeft() = new(SVector{2}(0.0,0.0))
end
struct UpperRight <: AbstractStrategy
    offset :: SVector{2}
    UpperRight() = new(SVector{2}(1.0,0.0))
end
struct LowerLeft <: AbstractStrategy
    offset :: SVector{2}
    LowerLeft() = new(SVector{2}(0.0,1.0))
end
struct LowerRight <: AbstractStrategy
    offset :: SVector{2}
    LowerRight() = new(SVector{2}(1.0,1.0))
end

"""
    coords(sga::SparseGeoArray, p::SVector{2,<:Integer}, strategy::AbstractStrategy=Center())
    coords(sga::SparseGeoArray, p::Tuple{<:Integer,<:Integer}, strategy::AbstractStrategy=Center())
    coords(sga::SparseGeoArray, p::CartesianIndex{2}, strategy::AbstractStrategy=Center())

Retrieve coordinates of the cell index by `p`.
See `indices` for the inverse function.
"""
function coords(sga::SparseGeoArray, p::SVector{2,<:Integer}, strategy::AbstractStrategy)
    SVector{2}(sga.f(p .- (1,1) .+ strategy.offset))
end
coords(sga::SparseGeoArray, p::Vector{<:Integer}, strategy::AbstractStrategy=Center()) = coords(sga, SVector{2}(p), strategy)
coords(sga::SparseGeoArray, p::Tuple{<:Integer,<:Integer}, strategy::AbstractStrategy=Center()) = coords(sga, SVector{2}(p), strategy)
coords(sga::SparseGeoArray, i :: IT, j :: IT, strategy::AbstractStrategy=Center()) where {IT <: Integer} = coords(sga, SVector{2}(i,j), strategy)

"""
    indices(sga::SparseGeoArray, p::SVector{2,<:Real})

Retrieve logical indices of the cell represented by coordinates `p`.
See `coords` for the inverse function.
"""
function indices(sga :: SparseGeoArray{DT, IT}, p::SVector{2,<:Real}) :: Tuple{IT,IT} where {DT <: Real, IT <: Integer} 
    Tuple(floor.(Int, inv(sga.f)(p)) .+ (1,1))
end
indices(sga::SparseGeoArray, p::AbstractVector{<:Real}) = indices(sga, SVector{2}(p))
indices(sga::SparseGeoArray, p::Tuple{<:Real,<:Real}) = indices(sga, SVector{2}(p))
indices(sga::SparseGeoArray, i :: R, j :: R, strategy::AbstractStrategy=Center()) where {R <: Real} = indices(sga, SVector{2}(i,j))


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




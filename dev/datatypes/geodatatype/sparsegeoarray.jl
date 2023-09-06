import GeoFormatTypes as GFT
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
end

SparseGeoArray{DT,IT}() where {DT <: Real, IT <: Integer} = SparseGeoArray{DT,IT}(Dict{Tuple{IT,IT},DT}(), convert(DT,-Inf), geotransform_to_affine(SVector(0.0, 1.0, 0.0, 0.0, 0.0, 1.0)), GFT.WellKnownText(GFT.CRS(), ""), Dict{String, Any}(), convert(IT,0), convert(IT,0), "", false)

function SparseGeoArray{DT,IT}(filename :: String, band :: Integer = 1) :: SparseGeoArray{DT,IT} where {DT <: Real, IT <: Integer}
  sga = SparseGeoArray{DT,IT}()
  readGEOTiffDataComplete(sga,filename,band,1)
  sga
end

#  function SparseGeoArray(a :: AbstractArray{DT,2}, nodatavalue :: DT, crs :: GFT.WellKnownText{GFT.CRS}) where {DT<:Real}
#    data :: Dict{Tuple{Int32,Int32},DT} = Dict{Tuple{Int32,Int32},DT}()
#    for i in 1:size(a,1)
#      for j in 1:size(a,2)
#	if (a[i,j]!=nodatavalue) data[(i,j)]=a[i,j] end
#      end
#    end
#    new{DT,Int32}(data, nodatavalue, crs, Dict{String,Any}(), size(a,1), size(a,2))
#  end


# Behave like an Array
Base.size(sga::SparseGeoArray) = (sga.xsize,sga.ysize)
Base.IndexStyle(::Type{<:SparseGeoArray}) = IndexCartesian()
#Base.similar(sga::SparseGeoArray, t::Type) = SparseGeoArray(similar(ga.A, t), ga.f, ga.crs, ga.metadata)
Base.iterate(sga::SparseGeoArray) = iterate(sga.data)
Base.iterate(sga::SparseGeoArray, state) = iterate(ga.data, state)
Base.length(sga::SparseGeoArray) = length(sga.data)
Base.parent(sga::SparseGeoArray) = Any
Base.eltype(::Type{SparseGeoArray{DT,IT}}) where {DT,IT} = DT
Base.show(io::IO, ::MIME"text/plain", sga::SparseGeoArray) = show(io, sga)

function Base.convert(::Type{SparseGeoArray{DT,IT}}, sga :: SparseGeoArray) where {DT, IT} 
  data = convert(Dict{Tuple{IT,IT}, DT}, sga.data)
  SparseGeoArray(data, convert(DT,sga.nodatavalue), sga.f, sga.crs, sga.metadata, convert(IT,sga.xsize), convert(IT,sga.ysize), sga.projref, sga.circular)
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

Index a GeoArray with `AbstractRange`s to get a cropped GeoArray with the correct `AffineMap` set.

# Examples
```julia-repl
julia> sga[2:3,2:3]
2x2x1 Array{Float64, 3} with AffineMap([1.0 0.0; 0.0 1.0], [1.0, 1.0]) and undefined CRS
```
"""
function Base.getindex(sga :: SparseGeoArray{DT, IT}, xrange::AbstractRange, yrange::AbstractRange) :: SparseGeoArray{DT, IT} where {DT <: Real, IT <: Integer} 
  data :: Dict{Tuple{IT,IT}, DT} = Dict{Tuple{IT,IT}, DT}()
  for y in 1:sga.ysize
    for x in 1:sga.xsize
      if ((y in yrange) && (x in xrange))
	v :: DT = get(sga.data, (x,y), sga.nodatavalue)
	if (v != sga.nodatavalue) data[(x-first(yrange)+1,y-first(yrange)+1)]=sga[x,y] end
      end
    end
  end
  x, y = first(yrange) - 1, first(xrange) - 1
  t = sga.f(SVector(x, y))
  l = sga.f.linear * SMatrix{2,2}([step(yrange) 0; 0 step(xrange)])
  SparseGeoArray{DT,IT}(data, sga.nodatavalue, AffineMap(l, t), sga.crs, sga.metadata, convert(IT,size(xrange,1)), convert(IT,size(yrange,1)), sga.projref, sga.circular)
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

function Base.setindex!(sga :: SparseGeoArray{DT, IT}, v :: DT, indices::Vararg{Integer,2}) where {DT <: Real, IT <: Integer} 
  if ((indices[1]<=0) || (indices[1]>sga.xsize) || (indices[2]<=0) || (indices[2]>sga.ysize))
    error("BoundsError: attempt to access $(sga.xsize)×$(sga.ysize) SparseGeoArray{$DT,$IT} at index [$(indices[1]), $(indices[2])]")
  end
  sga.data[(indices[1],indices[2])] = v
end

Base.setindex!(sga :: SparseGeoArray{DT, IT}, v, indices::Vararg{Integer,2}) where {DT <: Real, IT <: Integer} = setindex!(sga, convert, indices)


function Base.show(io::IO, sga::SparseGeoArray)
  crs = GFT.val(sga.crs)
  wkt = isempty(crs) ? "undefined CRS" : "CRS $crs"
  println(io, "$(join(size(sga), "x")) SparseGeoRaster implemented as $(typeof(sga.data)) with $(wkt)")
  println(io, "projref: $(sga.projref)")
  print(io, "aft: $(sga.f); nodatavalue: $(sga.nodatavalue); stored values: $(length(sga.data))")
end


clearData(sgr) = empty!(sgr.data)
function reset(sgr :: SparseGeoArray{DT,IT}) where {DT <: Real, IT <: Integer} 
  sgr = SparseGeoArray{DT,IT}()  
end


# Coordinates and indices
abstract type AbstractStrategy end
struct Center <: AbstractStrategy
    offset :: SVector{2}
    Center() = new(SVector{2}(0.5,0.5))
end
struct UpperLeft <: AbstractStrategy
    offset :: SVector{2}
    UpperLeft() = new(SVector{2}(1.0,0.0))
end
struct UpperRight <: AbstractStrategy
    offset :: SVector{2}
    UpperRight() = new(SVector{2}(1.0,1.0))
end
struct LowerLeft <: AbstractStrategy
    offset :: SVector{2}
    LowerLeft() = new(SVector{2}(0.0,1.0))
end
struct LowerRight <: AbstractStrategy
    offset :: SVector{2}
    LowerRight() = new(SVector{2}(0.0,0.0))
end

"""
    coords(sga::SparseGeoArray, p::SVector{2,<:Integer}, strategy::AbstractStrategy=Center())
    coords(sga::SparseGeoArray, p::Tuple{<:Integer,<:Integer}, strategy::AbstractStrategy=Center())
    coords(sga::SparseGeoArray, p::CartesianIndex{2}, strategy::AbstractStrategy=Center())

Retrieve coordinates of the cell index by `p`.
See `indices` for the inverse function.
"""
function coords(sga::SparseGeoArray, p::SVector{2,<:Integer}, strategy::AbstractStrategy)
    SVector{2}(sga.f(p .- strategy.offset))
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
    Tuple(round.(Int, inv(sga.f)(p)))
end
indices(sga::SparseGeoArray, p::AbstractVector{<:Real}) = indices(sga, SVector{2}(p))
indices(sga::SparseGeoArray, p::Tuple{<:Real,<:Real}) = indices(sga, SVector{2}(p))
indices(sga::SparseGeoArray, i :: R, j :: R, strategy::AbstractStrategy=Center()) where {R <: Real} = indices(sga, SVector{2}(i,j))


function area(sga :: SparseGeoArray, i :: I, j :: I) where {I <: Integer} 
  ul = coords(sgr,i,j,UpperLeft)
  lr = coords(sgr,i,j,LowerRight)
  lambda_diff_rad = (lr[1] - ul[1]) * pi / 180

  sin_phi1 = sin(ul[2] * pi / 180)
  sin_phi2 = sin(lr[2] * pi / 180)

  rr = earth_radius_km * earth_radius_km;
  return rr * lambda_diff_rad * abs(sin_phi2 - sin_phi1)
end


#=
    inline double Area(size_type x1, size_type x2, size_type y1, size_type y2, float unit_factor=1) const { 
    if (x1 > x2) { std::swap(x1,x2); }
    if (y1 > y2) { std::swap(y1,y2); }

    if (!cartesian) {
        double lambda_diff_rad = fabs(cellRightLon(x2) - cellLeftLon(x1)) * pi_f / 180;
        double sin_phi1 = sin(cellUpperLat(y1) * pi_f / 180);
        double sin_phi2 = sin(cellLowerLat(y2) * pi_f / 180);
        double rr = earth_radius_km * earth_radius_km;
        return rr * lambda_diff_rad * fabs(sin_phi2 - sin_phi1) * unit_factor;
    } else {
        return (fabs(cellRightX(x2)-cellLeftX(x1)) * fabs(cellLowerY(y2)-cellUpperY(y1))) * unit_factor;
    }
    }

    inline double Distance(size_type x1, size_type y1, size_type x2, size_type y2) const {
    double lat1 = cellCenterLat(y1);
    double lat2 = cellCenterLat(y2);
    double lon1 = cellCenterLon(x1);
    double lon2 = cellCenterLon(x2);

    return (!cartesian) ? DistanceLonLat(lon1, lat1, lon2, lat2) : DistanceLonLat(x1, y1, x2, y2);
    }

    inline double DistanceLonLat(double lon1, double lat1, double lon2, double lat2) const {
    // actually shortest distance - taking into account the border 0/360
    // implements the haversine formula

    if (!cartesian) {
        double diff_lat_radians = (lat2-lat1) * pi_f / 180;
        double diff_lon_radians = (fabs(lon1-lon2) > (fabs((lon1-lon2)-360))) ? ((lon2-lon1)-360) * pi_f / 180 : (lon2-lon1) * pi_f / 180;
        double sin_diff_lat = sin(diff_lat_radians / 2);
        double sin_diff_lon = sin(diff_lon_radians / 2);

        double a = pow(sin_diff_lat, 2) + pow(sin_diff_lon, 2) * cos(lat1 * pi_f / 180) * cos(lat2 * pi_f / 180);
        double c = 2 * atan2(sqrt(a), sqrt(1-a));
        double dist = earth_radius_km * c;

        return dist;
    } else {
        return sqrt(((lat2 - lat1) * (lat2 - lat1)) + ((lon2 - lon1) * (lon2 - lon1))); 
    }
    }
=#
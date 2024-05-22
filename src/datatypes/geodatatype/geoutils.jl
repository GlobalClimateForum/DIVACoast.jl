function geotransform_to_affine(gt::SVector{6,<:AbstractFloat})
  # See https://lists.osgeo.org/pipermail/gdal-dev/2011-July/029449.html
  # for an explanation of the geotransform format
  AffineMap(SMatrix{2,2}([gt[2] gt[3]; gt[5] gt[6]]), SVector{2}([gt[1], gt[4]]))
end
geotransform_to_affine(A::Vector{<:AbstractFloat}) = geotransform_to_affine(SVector{6}(A))

function affine_to_geotransform(am::AffineMap)
  l = am.linear
  t = am.translation
  (length(l) == 4 && length(t) == 2) || error("AffineMap has wrong dimensions.")
  [t[1], l[1], l[3], t[2], l[2], l[4]]
end

"""Check wether the AffineMap of a GeoArray contains rotations."""
function is_rotated(sga::SparseGeoArray)
  ga.f.linear[2] != 0.0 || ga.f.linear[3] != 0.0
end

function unitrange_to_affine(x::StepRangeLen, y::StepRangeLen)
  δx, δy = float(step(x)), float(step(y))
  AffineMap(
    SMatrix{2,2}(δx, 0.0, 0.0, δy),
    SVector(x[1] - δx / 2, y[1] - δy / 2)
  )
end

function bbox_to_affine(size::Tuple{Integer,Integer}, bbox::NamedTuple{(:min_x, :min_y, :max_x, :max_y)})
  AffineMap(
    SMatrix{2,2}(float(bbox.max_x - bbox.min_x) / size[1], 0, 0, float(bbox.max_y - bbox.min_y) / size[2]),
    SVector(float(bbox.min_x), float(bbox.min_y))
  )
end

"""Set geotransform of `SparseGeoArray` by specifying a bounding box.
Note that this only can result in a non-rotated or skewed `GeoArray`."""
function bbox!(sga::SparseGeoArray, bbox::NamedTuple{(:min_x, :min_y, :max_x, :max_y)})
  sga.f = bbox_to_affine(size(sga)[1:2], bbox)
  sga
end

crs(sga::SparseGeoArray) = sga.crs
affine(sga::SparseGeoArray) = sga.f
metadata(sga::SparseGeoArray) = sga.metadata

"""
    nh4(sga :: SparseGeoArray{DT, IT}, x :: Integer, y :: Integer) :: Array{Tuple{IT,IT}}
    nh4(sga :: SparseGeoArray{DT, IT}, p :: Tuple{Integer,Integer}) :: Array{Tuple{IT,IT}}

Compute the 4-Neighbourhood of the grid cell `x`,`y` in the SparseGeoArray `sga` and return as Array of pairs. Takes into account the boundaries of the SparseGeoArray.

# Examples
```julia-repl
julia> nh4(sga, 1, 1)
2-element Vector{Tuple{Int32, Int32}}:
 (2, 1)
 (1, 2)

julia> nh4(sga, 2, 4)
4-element Vector{Tuple{Int32, Int32}}:
 (1, 4)
 (3, 4)
 (2, 3)
 (2, 5)

```
"""
function nh4(sga::SparseGeoArray{DT,IT}, x::Integer, y::Integer)::Array{Tuple{IT,IT}} where {DT<:Real,IT<:Integer}
  # TODO: circularity!
  ret::Array{Tuple{IT,IT},1} = []
  if ((x < 1) || (x > sga.xsize))
    return ret
  end
  if ((y < 1) || (y > sga.ysize))
    return ret
  end
  if (x > 1)
    push!(ret, (x - 1, y))
  else
    if (sga.circular)
      push!(ret, (sga.xsize, y))
    end
  end
  if (x < sga.xsize)
    push!(ret, (x + 1, y))
  else
    if (sga.circular)
      push!(ret, (1, y))
    end
  end
  if (y > 1)
    push!(ret, (x, y - 1))
  end
  if (y < sga.ysize)
    push!(ret, (x, y + 1))
  end
  return ret
end

nh4(sga::SparseGeoArray{DT,IT}, p::Tuple{Integer,Integer}) where {DT<:Real,IT<:Integer} = nh4(sga, p[1], p[2])

# Todo: circularity!
function nh4(sga::SparseGeoArray{DT,IT}, x::Integer, y::Integer, nh::Array{Tuple{IT,IT}})::Integer where {DT<:Real,IT<:Integer}
  ret::Integer = 0
  if ((x < 1) || (x > sga.xsize))
    return ret
  end
  if ((y < 1) || (y > sga.ysize))
    return ret
  end
  if (x > 1)
    ret += 1
    nh[ret] = (x - 1, y)
  else
    if (sga.circular)
      ret += 1
      nh[ret] = (sga.xsize, y)
    end
  end
  if (x < sga.xsize)
    ret += 1
    nh[ret] = (x + 1, y)
  else
    if (sga.circular)
      ret += 1
      nh[ret] = (1, y)
    end
  end
  if (y > 1)
    ret += 1
    nh[ret] = (x, y - 1)
  end
  if (y < sga.ysize)
    ret += 1
    nh[ret] = (x, y + 1)
  end
  return ret
end

nh4(sga::SparseGeoArray{DT,IT}, p::Tuple{Integer,Integer}, nh::Array{Tuple{IT,IT}}) where {DT<:Real,IT<:Integer} = nh4(sga, p[1], p[2], nh)

"""
same as nh4 but accounting for al 8 neighbours of a pixel with index (x,y)
"""
function nh8(sga::SparseGeoArray{DT,IT}, x::Integer, y::Integer)::Array{Tuple{IT,IT}} where {DT<:Real,IT<:Integer}
  ret::Array{Tuple{IT,IT},1} = []
  if ((x < 1) || (x > sga.xsize))
    return ret
  end
  if ((y < 1) || (y > sga.ysize))
    return ret
  end
  ret = nh4(sga, x, y)
  if ((x > 1) && (y > 1))
    push!(ret, (x - 1, y - 1))
  end
  if ((x == 1) && (y > 1) && sga.circular)
    push!(ret, (sga.xsize, y - 1))
  end
  if ((x > 1) && (y < sga.ysize))
    push!(ret, (x - 1, y + 1))
  end
  if ((x == 1) && (y < sga.ysize) && sga.circular)
    push!(ret, (sga.xsize, y + 1))
  end
  if ((x < sga.xsize) && (y > 1))
    push!(ret, (x + 1, y - 1))
  end
  if ((x == sga.xsize) && (y > 1) && sga.circular)
    push!(ret, (1, y - 1))
  end
  if ((x < sga.xsize) && (y < sga.ysize))
    push!(ret, (x + 1, y + 1))
  end
  if ((x == sga.xsize) && (y < sga.ysize) && sga.circular)
    push!(ret, (1, y + 1))
  end
  return ret
end

nh8(sga::SparseGeoArray{DT,IT}, p::Tuple{Integer,Integer}) where {DT<:Real,IT<:Integer} = nh8(sga, p[1], p[2])

function nh8(sga::SparseGeoArray{DT,IT}, x::Integer, y::Integer, nh::Array{Tuple{IT,IT}})::Int where {DT<:Real,IT<:Integer}
  ret::Int = 0
  if ((x < 1) || (x > sga.xsize))
    return ret
  end
  if ((y < 1) || (y > sga.ysize))
    return ret
  end
  ret = nh4(sga, x, y, nh)
  if ((x > 1) && (y > 1))
    ret += 1
    nh[ret] = (x - 1, y - 1)
  end
  if (sga.circular && (x == 1) && (y > 1))
    ret += 1
    nh[ret] = (sga.xsize, y - 1)
  end
  if ((x > 1) && (y < sga.ysize))
    ret += 1
    nh[ret] = (x - 1, y + 1)
  end
  if (sga.circular && (x == 1) && (y < sga.ysize))
    ret += 1
    nh[ret] = (sga.xsize, y + 1)
  end
  if ((x < sga.xsize) && (y > 1))
    ret += 1
    nh[ret] = (x + 1, y - 1)
  end
  if (sga.circular && (x == sga.xsize) && (y > 1))
    ret += 1
    nh[ret] = (1, y - 1)
  end
  if ((x < sga.xsize) && (y < sga.ysize))
    ret += 1
    nh[ret] = (x + 1, y + 1)
  end
  if (sga.circular && (x == sga.xsize) && (y < sga.ysize))
    ret += 1
    nh[ret] = (1, y + 1)
  end
  return ret
end

nh8(sga::SparseGeoArray{DT,IT}, p::Tuple{Integer,Integer}, nh::Array{Tuple{IT,IT}}) where {DT<:Real,IT<:Integer} = nh8(sga, p[1], p[2], nh)

"""
    distance(lon1 :: R, lat1 :: R, lon2 :: R, lat2 :: R) :: R where {R <: Real}
    distance(p1 :: SVector{2,R}, p2 :: SVector{2,R}) :: R where {R <: Real}
    distance(p1 :: AbstractVector{R}, p2 :: AbstractVector{R}) :: R where {R <: Real} 
    distance(p1 :: Tuple{R,R}, p2 :: Tuple{R,R}) where {R <: Real} :: R where {R <: Real}

Compute the distance (in km) between two points given by lon1,lat1 and lon2,lat2 resp. p1 and p2. Uses the Haversine formula.

# Examples
```julia-repl
julia> ...

```
"""
function distance(lon1::R, lat1::R, lon2::R, lat2::R)::R where {R<:Real}
  diff_lat_radians = abs((lat2 - lat1) * pi / 180)
  diff_lon_radians = (abs(lon1 - lon2) > (abs((lon1 - lon2) - 360))) ? abs((lon2 - lon1) - 360) * pi / 180 : abs(lon2 - lon1) * pi / 180

  sin_diff_lat = sin(diff_lat_radians / 2)
  sin_diff_lon = sin(diff_lon_radians / 2)
  a = sin_diff_lat^2 + sin_diff_lon^2 * cos(lat1 * pi / 180) * cos(lat2 * pi / 180)

  c = 2 * atan(sqrt(a), sqrt(1 - a))
  #  c = 2 * asin(sqrt(a))
  return earth_radius_km * c
end

distance(p1::SVector{2,<:Real}, p2::SVector{2,<:Real}) = distance(p1[1], p1[2], p2[1], p2[2])
distance(p1::AbstractVector{<:Real}, p2::AbstractVector{<:Real}) = distance(p1[1], p1[2], p2[1], p2[2])
distance(p1::Tuple{R,R}, p2::Tuple{R,R}) where {R<:Real} = distance(p1[1], p1[2], p2[1], p2[2])


"""
    go_direction(lon :: R, lat :: R, distance :: Real, direction :: AbstractDirection) :: Tuple{R,R} where {R <: Real}

Compute the geographical coordinates of the point reached if we go distance km from (lon,lat) in direction. Takes into account circularity, but does not cross poles. direction can be East(), North(), West(), South()

# Examples
```julia-repl
julia> go_direction(13.2240, 52.3057, 10, East())
(13.370916039175427, 52.3057)
julia> go_direction(13.2240, 52.3057, 10000, North())
(13.224, 90.0)
julia> go_direction(19.0045,0.0,40075,West())
(19.004500000000007, 0.0)
```
"""
function go_direction(lon::R, lat::R, distance::Real, direction::AbstractDirection)::Tuple{R,R} where {R<:Real}
  s = SVector{2}(360 * distance / (earth_circumference_km * cos(deg2rad(lat))), 360 * distance / earth_circumference_km)
  delta = direction.step .* s
  r = [(lon + delta[1]) % 360, (lat + delta[2])]
  if r[1] <= -180
    r[1] = r[1] + 360
  end
  if r[1] > 180
    r[1] = r[1] - 360
  end
  if r[2] <= -90
    r[2] = convert(R, -90)
  end
  if r[2] > 90
    r[2] = convert(R, 90)
  end
  return Tuple(r)
end

go_direction(p::SVector{2,<:Real}, distance::Real, direction::AbstractDirection) = go_direction(p[1], p[2], distance, direction)
go_direction(p::AbstractVector{<:Real}, distance::Real, direction::AbstractDirection) = go_direction(p[1], p[2], distance, direction)
go_direction(p::Tuple{R,R}, distance::Real, direction::AbstractDirection) where {R<:Real} = go_direction(p[1], p[2], distance, direction)


"""
    bounding_boxes(sga :: SparseGeoArray{DT, IT}, lon_east :: Real, lon_west :: Real, lat_south :: Real, lat_north :: Real) where {DT <: Real, IT <: Integer}

Compute the bounding box(es) for the sparse geoarray sga and an area from lon_east to lon_west and lat_south and lat_north.

# Examples
```julia-repl
julia> ...

```
"""
function bounding_boxes(sga::SparseGeoArray{DT,IT}, lon_east::Real, lon_west::Real, lat_south::Real, lat_north::Real) where {DT<:Real,IT<:Integer}
  ret = Array{NTuple{4,IT}}(undef, 0)
  if lon_west <= lon_east
    ul = indices(sga, (lon_west, lat_north))
    ulx = if ul[1] < 1
      1
    elseif ul[1] > size(sga, 1)
      size(sga, 1)
    else
      ul[1]
    end
    uly = if ul[2] < 1
      1
    elseif ul[2] > size(sga, 2)
      size(sga, 2)
    else
      ul[2]
    end
    lr = indices(sga, (lon_east, lat_south))
    lrx = if lr[1] < 1
      1
    elseif lr[1] > size(sga, 1)
      size(sga, 1)
    else
      lr[1]
    end
    lry = if lr[2] < 1
      1
    elseif lr[2] > size(sga, 2)
      size(sga, 2)
    else
      lr[2]
    end
    push!(ret, (ulx, uly, lrx, lry))
  else
    ul = indices(sga, (lon_west, lat_north))
    ulx = if ul[1] < 1
      1
    elseif ul[1] > size(sga, 1)
      size(sga, 1)
    else
      ul[1]
    end
    uly = if ul[2] < 1
      1
    elseif ul[2] > size(sga, 2)
      size(sga, 2)
    else
      ul[2]
    end
    lr = indices(sga, (lon_east, lat_south))
    lrx = if lr[1] < 1
      1
    elseif lr[1] > size(sga, 1)
      size(sga, 1)
    else
      lr[1]
    end
    lry = if lr[2] < 1
      1
    elseif lr[2] > size(sga, 2)
      size(sga, 2)
    else
      lr[2]
    end
    push!(ret, (1, uly, ulx, lry))
    push!(ret, (lrx, uly, size(sga, 1), lry))
  end
  return ret
end

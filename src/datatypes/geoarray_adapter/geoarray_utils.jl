"""
    nh4(ga :: GeoArray, x :: Integer, y :: Integer) :: Array{Tuple{Integer,Integer}}
    nh4(ga :: GeoArray, p :: Tuple{Integer,Integer}) :: Array{Tuple{Integer,Integer}}

Compute the 4-Neighbourhood of the grid cell `x`,`y` in the SparseGeoArray `ga` and return as Array of pairs. Takes into account the boundaries of the SparseGeoArray.

# Examples
```julia-repl
julia> nh4(ga, 1, 1)
2-element Vector{Tuple{Int32, Int32}}:
 (2, 1)
 (1, 2)

julia> nh4(ga, 2, 4)
4-element Vector{Tuple{Int32, Int32}}:
 (1, 4)
 (3, 4)
 (2, 3)
 (2, 5)

```
"""
function nh4(ga::GeoArray, x::Integer, y::Integer)::Array{Tuple{Integer,Integer}}
  # TODO: circularity!
  ret::Array{Tuple{Integer,Integer},1} = []
  if ((x < 1) || (x > size(ga)[1]))
    return ret
  end
  if ((y < 1) || (y > size(ga)[2]))
    return ret
  end
  if (x > 1)
    push!(ret, (x - 1, y))
  else
    if (x == 1) && is_circular(ga)
      push!(ret, (size(ga)[1], y))
    end
  end
  if (x < size(ga)[1])
    push!(ret, (x + 1, y))
  else
    if (x == size(ga)[1]) && is_circular(ga)
      push!(ret, (1, y))
    end
  end
  if (y > 1)
    push!(ret, (x, y - 1))
  end
  if (y < size(ga)[2])
    push!(ret, (x, y + 1))
  end
  return ret
end

nh4(ga::GeoArray, p::Tuple{Integer,Integer}) = nh4(ga, p[1], p[2])

function nh4(ga::GeoArray, x::Integer, y::Integer, nh::Array{Tuple{Integer,Integer}})::Integer
  ret::Integer = 0
  if ((x < 1) || (x > size(ga)[1]))
    return ret
  end
  if ((y < 1) || (y > size(ga)[2]))
    return ret
  end
  if (x > 1)
    ret += 1
    nh[ret] = (x - 1, y)
  else
    if (x == 1) && is_circular(ga)
      ret += 1
      nh[ret] = (size(ga)[1], y)
    end
  end
  if (x < size(ga)[1])
    ret += 1
    nh[ret] = (x + 1, y)
  else
    if (x == size(ga)[1]) && is_circular(ga)
      ret += 1
      nh[ret] = (1, y)
    end
  end
  if (y > 1)
    ret += 1
    nh[ret] = (x, y - 1)
  end
  if (y < size(ga)[2])
    ret += 1
    nh[ret] = (x, y + 1)
  end
  return ret
end

nh4(ga::GeoArray, p::Tuple{Integer,Integer}, nh::Array{Tuple{Integer,Integer}})::Integer = nh4(ga, p[1], p[2], nh)

"""
same as nh4 but accounting for al 8 neighbours of a pixel with index (x,y)
"""
function nh8(ga::GeoArray, x::Integer, y::Integer)::Array{Tuple{Integer,Integer}}
  ret::Array{Tuple{Integer,Integer},1} = []
  if ((x < 1) || (x > size(ga)[1]))
    return ret
  end
  if ((y < 1) || (y > size(ga)[2]))
    return ret
  end
  ret = nh4(ga, x, y)
  if ((x > 1) && (y > 1))
    push!(ret, (x - 1, y - 1))
  end
  if ((x == 1) && (y > 1) && is_circular(ga))
    push!(ret, (size(ga)[1], y - 1))
  end
  if ((x > 1) && (y < size(ga)[2]))
    push!(ret, (x - 1, y + 1))
  end
  if ((x == 1) && (y < size(ga)[2]) && is_circular(ga))
    push!(ret, (size(ga)[1], y + 1))
  end
  if ((x < size(ga)[1]) && (y > 1))
    push!(ret, (x + 1, y - 1))
  end
  if ((x == size(ga)[1]) && (y > 1) && is_circular(ga))
    push!(ret, (1, y - 1))
  end
  if ((x < size(ga)[1]) && (y < size(ga)[2]))
    push!(ret, (x + 1, y + 1))
  end
  if ((x == size(ga)[1]) && (y < size(ga)[2]) && is_circular(ga))
    push!(ret, (1, y + 1))
  end
  return ret
end

nh8(ga::GeoArray, p::Tuple{Integer,Integer}) = nh8(ga, p[1], p[2])

function nh8(ga::GeoArray, x::Integer, y::Integer, nh::Array{Tuple{Integer,Integer}})::Int
  ret::Int = 0
  if ((x < 1) || (x > size(ga)[1]))
    return ret
  end
  if ((y < 1) || (y > size(ga)[2]))
    return ret
  end
  ret = nh4(ga, x, y, nh)
  if ((x > 1) && (y > 1))
    ret += 1
    nh[ret] = (x - 1, y - 1)
  end
  if (is_circular(ga) && (x == 1) && (y > 1))
    ret += 1
    nh[ret] = (size(ga)[1], y - 1)
  end
  if ((x > 1) && (y < size(ga)[2]))
    ret += 1
    nh[ret] = (x - 1, y + 1)
  end
  if (is_circular(ga) && (x == 1) && (y < size(ga)[2]))
    ret += 1
    nh[ret] = (size(ga)[1], y + 1)
  end
  if ((x < size(ga)[1]) && (y > 1))
    ret += 1
    nh[ret] = (x + 1, y - 1)
  end
  if (is_circular(ga) && (x == size(ga)[1]) && (y > 1))
    ret += 1
    nh[ret] = (1, y - 1)
  end
  if ((x < size(ga)[1]) && (y < size(ga)[2]))
    ret += 1
    nh[ret] = (x + 1, y + 1)
  end
  if (is_circular(ga) && (x == size(ga)[1]) && (y < size(ga)[2]))
    ret += 1
    nh[ret] = (1, y + 1)
  end
  return ret
end

nh8(ga::GeoArray, p::Tuple{Integer,Integer}, nh::Array{Tuple{Integer,Integer}}) = nh8(ga, p[1], p[2], nh)

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
    bounding_boxes(ga :: SparseGeoArray{DT, IT}, lon_east :: Real, lon_west :: Real, lat_south :: Real, lat_north :: Real) where {DT <: Real, IT <: Integer}

Compute the bounding box(es) for the sparse geoarray ga and an area from lon_east to lon_west and lat_south and lat_north.

# Examples
```julia-repl
julia> ...

```
"""
function bounding_boxes(ga::GeoArray, lon_east::Real, lon_west::Real, lat_south::Real, lat_north::Real)
  ret = Array{NTuple{4,Int}}(undef, 0)
  if lon_west <= lon_east
    ul = indices(ga, (lon_west, lat_north))
    ulx = if ul[1] < 1
      1
    elseif ul[1] > size(ga, 1)
      size(ga, 1)
    else
      ul[1]
    end
    uly = if ul[2] < 1
      1
    elseif ul[2] > size(ga, 2)
      size(ga, 2)
    else
      ul[2]
    end
    lr = indices(ga, (lon_east, lat_south))
    lrx = if lr[1] < 1
      1
    elseif lr[1] > size(ga, 1)
      size(ga, 1)
    else
      lr[1]
    end
    lry = if lr[2] < 1
      1
    elseif lr[2] > size(ga, 2)
      size(ga, 2)
    else
      lr[2]
    end
    push!(ret, (ulx, uly, lrx, lry))
  else
    ul = indices(ga, (lon_west, lat_north))
    ulx = if ul[1] < 1
      1
    elseif ul[1] > size(ga, 1)
      size(ga, 1)
    else
      ul[1]
    end
    uly = if ul[2] < 1
      1
    elseif ul[2] > size(ga, 2)
      size(ga, 2)
    else
      ul[2]
    end
    lr = indices(ga, (lon_east, lat_south))
    lrx = if lr[1] < 1
      1
    elseif lr[1] > size(ga, 1)
      size(ga, 1)
    else
      lr[1]
    end
    lry = if lr[2] < 1
      1
    elseif lr[2] > size(ga, 2)
      size(ga, 2)
    else
      lr[2]
    end
    push!(ret, (1, uly, ulx, lry))
    push!(ret, (lrx, uly, size(ga, 1), lry))
  end
  return ret
end


"""
    join_geotiff_data_categorised!(geo_arrays :: Dict{CT, GeoArray}, geo_arrays_ret :: Dict{CT2, GeoArray}, mapping :: Dict{CT, CT2}) where {CT <: Integer, CT2 <: Integer}

The function joins geotiff data from a dictionary of `GeoArray` objects categorized by integer keys.
It takes a mapping dictionary that maps the original keys to new keys, and it updates the `sgrs_ret` dictionary with the union of the `SparseGeoArray` objects.

# Arguments
- `geo_arrays`: A dictionary where keys are integers and values are `GeoArray`. 
- `geo_arrays_ret`: A dictionary where keys are new integers and values are `GeoArray` to store the results.
- `mapping`: A dictionary that maps original integer keys to new integer keys.
# Returns
- The function modifies `geo_arrays_ret` in place, adding the union of `GeoArray` objects from `sgrs` based on the mapping. 
"""
function join_geotiff_data_categorised!(geo_arrays::Dict{CT,GeoArray}, geo_arrays_ret::Dict{CT2,GeoArray}, mapping::Dict{CT,CT2}) where {CT<:Integer,CT2<:Integer}
  for key in keys(geo_arrays)
    if (haskey(mapping, key))
      mk::CT2 = mapping[key]
      if (haskey(geo_arrays_ret, mk))
        union!(geo_arrays_ret[mk], geo_arrays[key])
      else
        geo_arrays_ret[mk], geo_arrays[key]
      end
    end
  end
end


function area(ga::GeoArray, i::Integer, j::Integer)
  ul = GeoArrays.coords(ga, (i, j), UpperLeft())
  lr = GeoArrays.coords(ga, (i, j), LowerRight())
  lambda_diff_rad = (lr[1] - ul[1]) * pi / 180

  sin_phi1 = sin(ul[2] * pi / 180)
  sin_phi2 = sin(lr[2] * pi / 180)

  rr = earth_radius_km * earth_radius_km
  return rr * lambda_diff_rad * abs(sin_phi2 - sin_phi1)
end

area(ga::GeoArray, p::Tuple{<:Integer,<:Integer}) = area(ga, p[1], p[2])
area(ga::GeoArray, p::Tuple{I,I}) where {I<:Integer} = area(ga, p[1], p[2])

include("geoarray_helpers.jl")

function make_consistent_for_crop(ga::GeoArray{T,N,C}, min_x::Integer, min_y::Integer, max_x::Integer, max_y::Integer) where {T,N,C}
  if max_x < min_x
    min_x, max_x = max_x, min_x
  end
  if max_y < min_y
    min_y, max_y = max_y, min_y
  end
  if min_x < 1
    min_x = 1
  end
  if max_x > size(ga, 1)
    max_x = size(ga, 1)
  end
  if min_y < 1
    min_y = 1
  end
  if max_y > size(ga, 2)
    max_y = size(ga, 2)
  end
  return min_x, min_y, max_x, max_y
end

function crop!(ga::GeoArray{T,N,C}, min_x::Integer, min_y::Integer, max_x::Integer, max_y::Integer) where {T,N,C}
  min_x, min_y, max_x, max_y = make_consistent_for_crop(ga, min_x, min_y, max_x, max_y)
  crop!(ga.A, min_x=min_x, max_x=max_x, min_y=min_y, max_y=max_y)
  t = ga.f(SVector(min_x - 1, min_y - 1))
  l = ga.f.linear * SMatrix{2,2}([1 0; 0 1])
  ga.f = AffineMap(l, t)
end

function crop!(ga::GeoArray{T,N,Array{T}}, min_x::Integer, min_y::Integer, max_x::Integer, max_y::Integer) where {T,N}
  min_x, min_y, max_x, max_y = make_consistent_for_crop(ga, min_x, min_y, max_x, max_y)
  a = ga.A[min_x:max_x,min_y:max_y]
  ga.A = a
  t = ga.f(SVector(min_x - 1, min_y - 1))
  l = ga.f.linear * SMatrix{2,2}([1 0; 0 1])
  ga.f = AffineMap(l, t)
end

function crop!(ga::GeoArray{T,N,Matrix{T}}, min_x::Integer, min_y::Integer, max_x::Integer, max_y::Integer) where {T,N}
  min_x, min_y, max_x, max_y = make_consistent_for_crop(ga, min_x, min_y, max_x, max_y)
  a = ga.A[min_x:max_x,min_y:max_y]
  ga.A = a
  t = ga.f(SVector(min_x - 1, min_y - 1))
  l = ga.f.linear * SMatrix{2,2}([1 0; 0 1])
  ga.f = AffineMap(l, t)
end

"""
    crop!(ga::GeoArray; margin_x :: Integer = 0, margin_y :: Integer = 0)

Crop a `GeoArray` to its minimum data extent and optional margins around the extent. 

# Arguments
- `ga`: The `GeoArray` to crop.
- `margin_x`: An optional integer specifying the margin to add to the left and right of the extent. Defaults to 0.
- `margin_y`: An optional integer specifying the margin to add to the top and bottom of the extent. Defaults to 0.

# Returns
- Returns nothing, since the function modifies the `GeoArray` in place.

# Example
```julia
crop!(ga, margin_x=5, margin_y=10)
```
"""
function crop!(ga::GeoArray{T,N,C}; margin_x::Integer=0, margin_y::Integer=0) where {T,N,C}
  min_x, min_y, max_x, max_y = extent(ga.A, no_data_value(ga))
  min_x = (min_x - margin_x < 1) ? 1 : min_x - margin_x
  min_y = (min_y - margin_y < 1) ? 1 : min_y - margin_y
  max_x = (max_x + margin_x > size(ga)[1]) ? size(ga)[1] : max_x + margin_x
  max_y = (max_y + margin_y > size(ga)[2]) ? size(ga)[2] : max_y + margin_y

  crop!(ga, min_x, min_y, max_x, max_y)
end


#clear_data!(sga) = empty!(sga.data)

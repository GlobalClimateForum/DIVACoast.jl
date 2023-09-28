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

function nh4(sga :: SparseGeoArray{DT, IT}, x :: Integer, y :: Integer) :: Array{Tuple{IT,IT}} where {DT <: Real, IT <: Integer}
  ret :: Array{Tuple{IT,IT}, 1} = []
  if ((x<1) || (x>sga.xsize)) return ret end
  if ((y<1) || (y>sga.ysize)) return ret end
  if (x>1)           push!(ret, (x-1,y)) end
  if (x<sga.xsize)   push!(ret, (x+1,y)) end
  if (y>1)           push!(ret, (x,y-1)) end
  if (y<sga.ysize)   push!(ret, (x,y+1)) end
  return ret
end

function nh4(sga :: SparseGeoArray{DT, IT}, p :: Tuple{Integer,Integer}) :: Array{Tuple{IT,IT}} where {DT <: Real, IT <: Integer}
  return nh4(g, p[1], p[2])
end

function nh8(sga :: SparseGeoArray{DT, IT}, x :: Integer, y :: Integer) :: Array{Tuple{IT,IT}} where {DT <: Real, IT <: Integer}
  ret :: Array{Tuple{IT,IT}, 1} = []
  if ((x<1) || (x>sga.xsize)) return ret end
  if ((y<1) || (y>sga.ysize)) return ret end
  ret = nh4(sga,x,y)
  if ((x>1) && (y>1))                 push!(ret, (x-1,y-1)) end
  if ((x>1) && (y<sga.ysize))         push!(ret, (x-1,y+1)) end
  if ((x<sga.xsize) && (y>1))         push!(ret, (x+1,y-1)) end
  if ((x<sga.xsize) && (y<sga.ysize)) push!(ret, (x+1,y+1)) end
  return ret
end

function nh8(sga :: SparseGeoArray{DT, IT}, p :: Tuple{Integer,Integer}) :: Array{Tuple{IT,IT}} where {DT <: Real, IT <: Integer}
  return nh8(sga, p[1], p[2])
end

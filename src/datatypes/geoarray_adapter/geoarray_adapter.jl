using ArchGDAL
using StaticArrays
using GDAL
using CoordinateTransformations
using GeoFormatTypes
using GeoArrays


function geotransform_to_affine(gt::SVector{6,<:AbstractFloat})
  # See https://lists.osgeo.org/pipermail/gdal-dev/2011-July/029449.html
  # for an explanation of the geotransform format
  AffineMap(Matrix{Float64}([gt[2] gt[3]; gt[5] gt[6]]), Vector{Float64}([gt[1], gt[4]]))
end
geotransform_to_affine(A::Vector{<:AbstractFloat}) = geotransform_to_affine(SVector{6}(A))

function getmetadata(ds::ArchGDAL.RasterDataset, domain::AbstractString)
    a = ArchGDAL.metadata(ds.ds, domain=domain)
    k, v = zip(split.(a, "=")...)
    Dict(Pair.(collect(k), collect(v))...)
end

function getmetadata(ds::ArchGDAL.RasterDataset)
    domains = ArchGDAL.metadatadomainlist(ds.ds)
    values = getmetadata.(Ref(ds), domains)
    Dict(Pair.(domains, values))
end

"""Check wether the AffineMap of a GeoArray contains rotations."""
function is_rotated(ga::GeoArray)
  ga.f.linear[2] != 0.0 || ga.f.linear[3] != 0.0
end

function is_circular(ga::GeoArray)
  return false
end

function no_data_value(ga::GeoArray)
  return parse(eltype(ga),ga.metadata["NoData Value"]["NoData Value"])  
end

function my_insert_data!(gr::T1, data::T2, x_start::Integer, x_end::Integer, y_start::Integer, y_end::Integer, nodatavalue) where {T1,T2}
  xs = (x_end - x_start + 1)
  for y in y_start:y_end
    for x in x_start:x_end
      val = data[((y-y_start)*xs+(x-x_start)+1)]
      if val != nodatavalue
        gr[x,y] = val
      end
    end
  end
end

empty_geo_array(::Type{E}) where{E <: Number} = GeoArray(Array{E}(undef,1,1), geotransform_to_affine(SVector(0.0, 1.0, 0.0, 0.0, 0.0, 1.0)), GFT.WellKnownText(GFT.CRS(), ""), Dict{String,Any}())
empty_geo_array(::Type{C}) where{C <: AbstractArray} = GeoArray(C(-9999,1,1), geotransform_to_affine(SVector(0.0, 1.0, 0.0, 0.0, 0.0, 1.0)), GFT.WellKnownText(GFT.CRS(), ""), Dict{String,Any}())


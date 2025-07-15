import GeoArrays
import ArchGDAL
import GDAL
import CoordinateTransformations
import GeoFormatTypes

using StaticArrays


function read_geotiff_to_geoarray_2d(::Type{C}, ::Type{E}, init, fn::String, b::Int) where {C<:AbstractArray,E<:Number}
  ds = ArchGDAL.readraster(fn)
  band = ArchGDAL.getband(ds, b)

  data = C{E}(init, ArchGDAL.width(ds), ArchGDAL.height(ds))
  buffer = Array{ArchGDAL.pixeltype(band)}(undef, ArchGDAL.blocksize(band)..., 1)
  ndv = convert(ArchGDAL.pixeltype(band), ArchGDAL.getnodatavalue(band))

  total_p = ArchGDAL.width(ds) * ArchGDAL.height(ds)
  current_fill = 0
  p = 0
  print("read progress: 0 ")

  for (cols, rows) in ArchGDAL.windows(band)
    ArchGDAL.read!(ds.ds, buffer, [1], rows, cols)
    my_insert_data!(data, buffer, cols[1], cols[length(cols)], rows[1], rows[length(rows)], ndv)
    current_fill += (cols[length(cols)] - cols[1] + 1) * (rows[length(rows)] - rows[1] + 1)

    if floor(Int, current_fill / total_p * 10) > p
      p = floor(Int, current_fill / total_p * 10)
      print("$(p*10) ")
    end
  end

  ret = GeoArrays.GeoArray(data)
  ret.f = geotransform_to_affine(ArchGDAL.getgeotransform(ds))
  ret.crs = GeoFormatTypes.WellKnownText(GeoFormatTypes.CRS(), ArchGDAL.getproj(ds))
  ret.metadata = getmetadata(ds)
  ret.metadata["NoData Value"] = Dict("NoData Value" => string(ndv))
  ArchGDAL.destroy(ds)
  println()
  return ret
end


function read_geotiff_to_geoarray_2d(::Type{C}, ::Type{E}, ::Type{I}, init, fn::String, b::Int) where {C<:AbstractArray,E<:Number,I<:Number}
  ds = ArchGDAL.readraster(fn)
  band = ArchGDAL.getband(ds, b)

  data = C{E,I}(init, ArchGDAL.width(ds), ArchGDAL.height(ds))
  buffer = Array{ArchGDAL.pixeltype(band)}(undef, ArchGDAL.blocksize(band)..., 1)
  ndv = convert(ArchGDAL.pixeltype(band), ArchGDAL.getnodatavalue(band))

  total_p = ArchGDAL.width(ds) * ArchGDAL.height(ds)
  current_fill = 0
  p = 0
  print("read progress: 0 ")

  for (cols, rows) in ArchGDAL.windows(band)
    ArchGDAL.read!(ds.ds, buffer, [1], rows, cols)
    my_insert_data!(data, buffer, cols[1], cols[length(cols)], rows[1], rows[length(rows)], ndv)

    current_fill += (cols[length(cols)] - cols[1] + 1) * (rows[length(rows)] - rows[1] + 1)

    if floor(Int, current_fill / total_p * 10) > p
      p = floor(Int, current_fill / total_p * 10)
      print("$(p*10) ")
    end
  end

  ret = GeoArrays.GeoArray(data)
  ret.f = geotransform_to_affine(ArchGDAL.getgeotransform(ds))
  ret.crs = GeoFormatTypes.WellKnownText(GeoFormatTypes.CRS(), ArchGDAL.getproj(ds))
  ret.metadata = getmetadata(ds)
  ret.metadata["NoData Value"] = Dict("NoData Value" => string(ndv))
  ArchGDAL.destroy(ds)
  println()
  return ret
end

function read_geotiff_data_complete!(ga, filename::String, band::Integer=1, row_chunk_size::Integer=1)

  read_geotiff_header!(ga, filename, band)

  ds = ArchGDAL.readraster(filename)
  band = ArchGDAL.getband(ds, band)

  ysize = size(ga)[2]
  xsize = size(ga)[1]

  r_tiles = ysize ÷ row_chunk_size
  remaining_r = ysize % row_chunk_size

  buffer = Array{ArchGDAL.pixeltype(band)}(undef, ArchGDAL.blocksize(band)..., 1)
  ndv = convert(ArchGDAL.pixeltype(band), ArchGDAL.getnodatavalue(band))

  print("read progress: 0 ")
  total_p = xsize * ysize
  current_fill = 0
  p = 0

  for (cols, rows) in ArchGDAL.windows(band)

    ArchGDAL.read!(ds.ds, buffer, [1], rows, cols)
    my_insert_data!(ga.A, buffer, cols[1], cols[length(cols)], rows[1], rows[length(rows)], ndv)
    current_fill += (cols[length(cols)] - cols[1] + 1) * (rows[length(rows)] - rows[1] + 1)

    if floor(Int, current_fill / total_p * 10) > p
      p = floor(Int, current_fill / total_p * 10)
      print("$(p*10) ")
    end

  end

  println()
  ArchGDAL.destroy(ds)
end


#
# Double check.
#
function read_geotiff_data_partial!(ga::GeoArray, x_start::Integer, x_end::Integer, y_start::Integer, y_end::Integer, band::Integer=1; y_chunk_size::Integer=1) where {DT<:Real,IT<:Integer}

  dataset = GDAL.gdalopen(ga.filename, GDAL.GA_ReadOnly)
  band = GDAL.gdalgetrasterband(dataset, band)

  if y_start > y_end
    y_start, y_end = y_end, y_start
  end
  if y_start < 1
    y_start = 1
  end
  if y_end >= ga.ysize
    y_end = ga.ysize
  end

  if x_start > x_end
    x_start, x_end = x_end, x_start
  end
  if x_start < 1
    x_start = 1
  end
  if x_end >= ga.xsize
    x_end = ga.xsize
  end

  r_tiles = (y_end - y_start + 1) ÷ y_chunk_size
  remaining_r = (y_end - y_start + 1) % y_chunk_size
  scanline = fill(0.0f0, y_chunk_size * (x_end - x_start + 1))

  for r in 1:(r_tiles)
    #println("read: $(x_start - 1), $((r - 1) * y_chunk_size + (y_start - 1)), $((x_end - x_start + 1)), $y_chunk_size,")
    GDAL.gdalrasterio(band, GDAL.GF_Read, x_start - 1, (r - 1) * y_chunk_size + (y_start - 1), (x_end - x_start + 1), y_chunk_size, scanline, (x_end - x_start + 1), y_chunk_size, GDAL.GDT_Float32, 0, 0)
    private_insert_data!(ga, scanline, x_start, x_end, (r - 1) * y_chunk_size + y_start, (r - 1) * y_chunk_size + y_start + y_chunk_size - 1)
  end

  if (remaining_r != 0)
    #println("GDAL.gdalrasterio(band,GDAL.GF_Read,$(x_start-1),$((r_tiles)*y_chunk_size+y_start),$(x_end - x_start + 1),$remaining_r,scanline,$(x_end - x_start + 1),$remaining_r,GDAL.GDT_Float32,0,0)")
    GDAL.gdalrasterio(band, GDAL.GF_Read, x_start - 1, (r_tiles) * y_chunk_size + y_start - 1, (x_end - x_start + 1), remaining_r, scanline, (x_end - x_start + 1), remaining_r, GDAL.GDT_Float32, 0, 0)
    private_insert_data!(ga, scanline, x_start, x_end, (r_tiles) * y_chunk_size + y_start, y_end)
  end
  GDAL.gdalclose(dataset)
end

function read_box_around!(ga::SparseGeoArray{DT,IT}, p::Tuple{Real,Real}, radius::Real, y_chunk_size=1, f=identity) where {DT<:Real,IT<:Integer}
  if (radius >= earth_circumference_km / 2)
    return read_geotiff_data_complete!(sga, sga.filename)
  else

    sgat = SparseGeoArray{DT,IT}(Dict{Tuple{IT,IT},DT}(), sga.nodatavalue, sga.f, sga.crs, sga.metadata, sga.xsize, sga.ysize, sga.projref, sga.circular, sga.filename)

    p_east = go_direction(p, radius, East())
    p_west = go_direction(p, radius, West())
    p_north = go_direction(p, radius, North())
    p_south = go_direction(p, radius, South())

    bb = bounding_boxes(sga, p_east[1], p_west[1], p_south[2], p_north[2])

    for b in bb
      read_geotiff_data_partial!(sgat, b[1], b[3], b[2], b[4], y_chunk_size=y_chunk_size)
    end
    return sgat
  end
end

function partial_read_around!(sga::SparseGeoArray{DT,IT}, p::Tuple{Real,Real}, radius::Real, y_chunk_size=1, f=identity) where {DT<:Real,IT<:Integer}

  if (radius >= earth_circumference_km / 2)
    read_geotiff_data_complete!(sga, sga.filename)
  else
    sgat = SparseGeoArray{DT,IT}(Dict{Tuple{IT,IT},DT}(), sga.nodatavalue, sga.f, sga.crs, sga.metadata, sga.xsize, sga.ysize, sga.projref, sga.circular, sga.filename)

    p_east = go_direction(p, radius, East())
    p_west = go_direction(p, radius, West())
    p_north = go_direction(p, radius, North())
    p_south = go_direction(p, radius, South())

    bb = bounding_boxes(sga, p_east[1], p_west[1], p_south[2], p_north[2])

    for b in bb
      read_geotiff_data_partial!(sgat, b[1], b[3], b[2], b[4], y_chunk_size=y_chunk_size)
      for (indices, value) in sgat.data
        if (distance(Tuple(coords(sga::SparseGeoArray, indices, Center())), p) <= radius)
          if ((sga[indices[1], indices[2]] == sga.nodatavalue))
            sga[indices[1], indices[2]] = f(value)
          end
        end
      end
    end
  end
end


# todo: handle existing files. 
function save_geotiff_data_complete(ga::SparseGeoArray{DT,IT}, filename::String, y_chunk_size::Integer=1) where {DT<:Real,IT<:Integer}
  fn = split(filename, ".")
  if (size(fn) == 1)
    return
  end

  ext = fn[end]
  driver = GDAL.gdalgetdriverbyname("GTiff")
  if lowercase(ext) in ["tif" "gtif" "geotif" "tiff" "gtiff" "geotiff"]
    driver = GDAL.gdalgetdriverbyname("GTiff")
  end

  opts = ["COMPRESS=DEFLATE", "BIGTIFF=YES"]
  dataset = GDAL.gdalcreate(driver, filename, ga.xsize, ga.ysize, 1, GDAL.GDT_Float32, opts)
  band = GDAL.gdalgetrasterband(dataset, 1)

  GDAL.gdalsetrasternodatavalue(band, ga.nodatavalue)
  GDAL.gdalsetprojection(dataset, ga.projref)
  GDAL.gdalsetgeotransform(dataset, affine_to_geotransform(ga.f))

  r_tiles = ga.ysize ÷ y_chunk_size
  remaining_r = ga.ysize % y_chunk_size
  scanline = fill(0.0f0, y_chunk_size * ga.xsize)

  print("write progress: 0 ")
  p = 0

  for r in 1:(r_tiles)
    #    println("write $((r-1)*y_chunk_size) - $((r*y_chunk_size)-1)") 
    #    println("GDAL.gdalrasterio($band,GDAL.GF_Write,0,$((r-1)*y_chunk_size),$(ga.xsize),$y_chunk_size,scanline,$(ga.xsize),$y_chunk_size,GDAL.GDT_Float16,0,0)") 
    private_get_data(ga, scanline, y_chunk_size, (r - 1) * y_chunk_size)
    GDAL.gdalrasterio(band, GDAL.GF_Write, 0, (r - 1) * y_chunk_size, ga.xsize, y_chunk_size, scanline, ga.xsize, y_chunk_size, GDAL.GDT_Float32, 0, 0)
    if (((r * y_chunk_size) * 100 ÷ ga.ysize) ÷ 10) > p
      p = (((r * y_chunk_size) * 100 ÷ ga.ysize) ÷ 10)
      print("$(p*10) ")
    end
  end

  if (remaining_r != 0)
    private_get_data(ga, scanline, remaining_r, (r_tiles) * y_chunk_size - 1)
    GDAL.gdalrasterio(band, GDAL.GF_Write, 0, (r_tiles) * y_chunk_size - 1, ga.xsize, remaining_r, scanline, ga.xsize, remaining_r, GDAL.GDT_Float32, 0, 0)
    print("100")
  end
  println()
  GDAL.gdalclose(dataset)
end


# todo: handle existing files. 
function save_data_complete_csv(ga::SparseGeoArray{DT,IT}, filename::String, lonlat::Bool=false) where {DT<:Real,IT<:Integer}
  fn = split(filename, ".")
  if (size(fn) == 1)
    return
  end

  open(filename, "w") do f
    for i in 1:6
      write(f, "$(convert(Float32,affine_to_geotransform(ga.f)[i]))")
      if i != 6
        write(f, ",")
      end
    end
    write(f, "\n")
    write(f, "$(ga.projref)\n")
    write(f, "$(ga.xsize),$(ga.ysize)\n")
    write(f, "$(ga.nodatavalue)\n")
    write(f, "$(convert(Int8,lonlat))\n")

    for (indices, data) in ga.data
      if lonlat
        write(f, "$(coords(sga_florida_dtm,indices)[1]),$(coords(sga_florida_dtm,indices)[2]),$data\n")
      else
        write(f, "$(indices[1]-1),$(indices[2]-1),$data\n")
      end
    end
  end

end

redefine(a::A, nd::T, r::Integer, c::Integer) where {A,T} = A(nd, r, c)
redefine(a::Array{T}, nd::T, r::Integer, c::Integer) where {T} = fill(nd, r, c)

function read_geotiff_header!(ga::GeoArrays.GeoArray, filename::String, b::Integer=1)
  dataset = ArchGDAL.readraster(filename)
  band = ArchGDAL.getband(dataset, b)

  ysize = ArchGDAL.height(dataset)
  xsize = ArchGDAL.width(dataset)

  cintref = Ref(Cint(-1))
  nodatavalue = convert(eltype(ga), GDAL.gdalgetrasternodatavalue(band, cintref))

  data = redefine(ga.A, nodatavalue, xsize, ysize)

  ga.A = data
  ga.f = geotransform_to_affine(ArchGDAL.getgeotransform(dataset))
  ga.crs = GeoFormatTypes.WellKnownText(GeoFormatTypes.CRS(), ArchGDAL.getproj(dataset))
  ga.metadata = getmetadata(dataset)
  ga.metadata["NoData Value"] = Dict("NoData Value" => string(nodatavalue))

  ArchGDAL.destroy(dataset)
end


function read_geotiff_data_categorised!(gas::Dict{CT,SparseGeoArray{DT,IT}}, filename_data::String, filename_categories::String, band::Integer=1, row_chunk_size::Integer=1) where {CT<:Integer,DT<:Real,IT<:Integer}
  sga_data = SparseGeoArray{DT,IT}()
  read_geotiff_header!(sga_data, filename_data, band)
  dataset_data = GDAL.gdalopen(filename_data, GDAL.GA_ReadOnly)
  band_data = GDAL.gdalgetrasterband(dataset_data, band)

  sga_categories = SparseGeoArray{DT,IT}()
  read_geotiff_header!(sga_categories, filename_categories, band)
  dataset_categories = GDAL.gdalopen(filename_categories, GDAL.GA_ReadOnly)
  band_categories = GDAL.gdalgetrasterband(dataset_categories, band)

  if (sga_data.xsize != sga_categories.xsize)
    error("DimensionError: attempt categorized read of $filename_data ($(sga_data.xsize)×$(sga_data.ysize)) and $filename_categories ($(sga_categories.xsize)×$(sga_categories.ysize))")
  end
  if (sga_data.ysize != sga_categories.ysize)
    error("DimensionError: attempt categorized read of $filename_data ($(sga_data.xsize)×$(sga_data.ysize)) and $filename_categories ($(sga_categories.xsize)×$(sga_categories.ysize))")
  end
  if (sga_data.projref != sga_categories.projref)
    error("ProjRefError: attempt categorized read of $filename_data ($(sga_data.projref)) and $filename_categories ($(sga_categories.projref))")
  end
  if (sga_data.f != sga_categories.f)
    error("GeoTransfomError: attempt categorized read of $filename_data ($(sga_data.f)) and $filename_categories ($(sga_categories.f))")
  end

  r_tiles = sga_data.ysize ÷ convert(IT, row_chunk_size)
  remaining_r = sga_data.ysize % convert(IT, row_chunk_size)
  scanline_data = fill(0.0f0, row_chunk_size * sga_data.xsize)
  scanline_categories = fill(0.0f0, row_chunk_size * sga_data.xsize)
  print("read progress: 0 ")
  p = 0

  for r in 1:(r_tiles)
    GDAL.gdalrasterio(band_data, GDAL.GF_Read, 0, (r - 1) * row_chunk_size, sga_data.xsize, row_chunk_size, scanline_data, sga_data.xsize, row_chunk_size, GDAL.GDT_Float32, 0, 0)
    GDAL.gdalrasterio(band_categories, GDAL.GF_Read, 0, (r - 1) * row_chunk_size, sga_data.xsize, row_chunk_size, scanline_categories, sga_data.xsize, row_chunk_size, GDAL.GDT_Float32, 0, 0)

    private_insert_categorised_data!(gas, sga_data, sga_categories, scanline_data, scanline_categories, row_chunk_size, (r - 1) * row_chunk_size)
    if (((r * row_chunk_size) * 100 ÷ sga_data.ysize) ÷ 10) > p
      p = (((r * row_chunk_size) * 100 ÷ sga_data.ysize) ÷ 10)
      print("$(p*10) ")
    end
  end

  if (remaining_r != 0)
    GDAL.gdalrasterio(band_data, GDAL.GF_Read, 0, (r_tiles) * row_chunk_size - 1, sga_data.xsize, remaining_r, scanline_data, sga_data.xsize, remaining_r, GDAL.GDT_Float32, 0, 0)
    GDAL.gdalrasterio(band_categories, GDAL.GF_Read, 0, (r_tiles) * row_chunk_size - 1, sga_data.xsize, remaining_r, scanline_categories, sga_data.xsize, remaining_r, GDAL.GDT_Float32, 0, 0)
    private_insert_categorised_data!(gas, sga_data, sga_categories, scanline_data, scanline_categories, remaining_r, (r_tiles) * row_chunk_size - 1)
  end
  println()
  GDAL.gdalclose(dataset_data)
  GDAL.gdalclose(dataset_categories)
end

function read_geotiff_data_filtered!(ga::SparseGeoArray{DT,IT}, filename::String, f::Function, band::Integer=1, row_chunk_size::Integer=1) where {DT<:Real,IT<:Integer}
  read_geotiff_header!(ga, filename, band)
  dataset = GDAL.gdalopen(filename, GDAL.GA_ReadOnly)
  band = GDAL.gdalgetrasterband(dataset, band)

  r_tiles = ga.ysize ÷ row_chunk_size
  remaining_r = ga.ysize % row_chunk_size
  scanline = fill(0.0f0, row_chunk_size * ga.xsize)

  print("read progress: 0 ")
  p = 0

  for r in 1:(r_tiles)
    GDAL.gdalrasterio(band, GDAL.GF_Read, 0, (r - 1) * row_chunk_size, ga.xsize, row_chunk_size, scanline, ga.xsize, row_chunk_size, GDAL.GDT_Float32, 0, 0)
    for i in eachindex(scanline)
      if (!f(scanline[i], convert(Int32, ((i - 1) % ga.xsize) + 1), convert(Int32, (r - 1) * row_chunk_size + ((i - 1) ÷ ga.xsize + 1))))
        scanline[i] = ga.nodatavalue
      end
    end
    private_insert_data!(ga, scanline, 1, ga.xsize, (r - 1) * row_chunk_size + 1, r * row_chunk_size)
    if (((r * row_chunk_size) * 100 ÷ ga.ysize) ÷ 10) > p
      p = (((r * row_chunk_size) * 100 ÷ ga.ysize) ÷ 10)
      print("$(p*10) ")
    end
  end

  if (remaining_r != 0)
    GDAL.gdalrasterio(band, GDAL.GF_Read, 0, (r_tiles) * row_chunk_size - 1, ga.xsize, remaining_r, scanline, ga.xsize, remaining_r, GDAL.GDT_Float32, 0, 0)
    for i in eachindex(scanline)
      if (!f(scanline[i], convert(Int32, ((i - 1) % ga.xsize) + 1), convert(Int32, (r_tiles - 1) * row_chunk_size + ((i - 1) ÷ ga.xsize + 1))))
        scanline[i] = ga.nodatavalue
      end
    end
    (ga, scanline, 1, ga.xsize, (r_tiles) * row_chunk_size + 1, (r_tiles) * row_chunk_size + 1 + remaining_r)
  end
  println()
  GDAL.gdalclose(dataset)
end


function private_insert_data!(ga::SparseGeoArray{DT,IT}, data::Vector{Float32}, ysize::Integer, r_offset::Integer) where {DT<:Real,IT<:Integer}
  for j in 1:ga.xsize
    for i in 1:ysize
      val = data[((i-1)*ga.xsize+(j-1))+1]
      if val != ga.nodatavalue
        ga.data[(j, i + r_offset)] = val
      end
    end
  end
end


function private_insert_data!(ga::SparseGeoArray{DT,IT}, data::Vector{Float32}, x_start::Integer, x_end::Integer, y_start::Integer, y_end::Integer) where {DT<:Real,IT<:Integer}
  xs = (x_end - x_start + 1)
  for y in y_start:y_end
    for x in x_start:x_end
      val = data[((y-y_start)*xs+(x-x_start)+1)]
      if val != ga.nodatavalue
        ga.data[(x, y)] = val
      end
    end
  end
end


function private_get_data(ga::SparseGeoArray{DT,IT}, data::Vector{Float32}, ysize::Integer, r_offset::Integer) where {DT<:Real,IT<:Integer}
  for j in 1:ga.xsize
    for i in 1:ysize
      data[((i-1)*ga.xsize+(j-1))+1] = ga[j, i+r_offset]
    end
  end
end


function private_insert_categorised_data!(gas::Dict{CT,SparseGeoArray{DT,IT}}, ga_data::SparseGeoArray{DT,IT}, ga_categories::SparseGeoArray{DT,IT}, data::Vector{DT}, categories::Vector{DT}, ysize::Integer, r_offset::Integer) where {CT<:Integer,DT<:Real,IT<:Integer}
  for j in 1:ga_data.xsize
    for i in 1:ysize
      val = data[((i-1)*ga_data.xsize+(j-1))+1]
      cat = convert(CT, categories[((i-1)*ga_data.xsize+(j-1))+1])
      if val != ga_data.nodatavalue && cat != ga_categories.nodatavalue
        if !haskey(gas, cat)
          ga_t = SparseGeoArray{DT,IT}(Dict{Tuple{IT,IT},DT}(), ga_data.nodatavalue, ga_data.f, ga_data.crs, ga_data.metadata, ga_data.xsize, ga_data.ysize, ga_data.projref, ga_data.circular, ga_data.filename)
          gas[cat] = ga_t
        end
        gas[cat][(j, i + r_offset)] = val
      end
    end
  end
end




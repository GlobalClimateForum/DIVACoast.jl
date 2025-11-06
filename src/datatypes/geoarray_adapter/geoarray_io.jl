import GeoArrays
import ArchGDAL
import GDAL
import CoordinateTransformations
import GeoFormatTypes

using StaticArrays

create(a::A, nd::T, r::Integer, c::Integer) where {A<:AbstractArray,T} = A(nd, r, c)
create(a::Array{T}, nd::T, r::Integer, c::Integer) where {T} = fill(nd, r, c)

function insert_data!(gr::T1, data::T2, x_start::Integer, x_end::Integer, y_start::Integer, y_end::Integer, nodatavalue) where {T1,T2}
  xs = (x_end - x_start + 1)
  for y in y_start:y_end
    for x in x_start:x_end
      val = data[((y-y_start)*xs+(x-x_start)+1)]
      if val != nodatavalue
        gr[x, y] = val
      end
    end
  end
end


function read_geotiff_data(data::C, ds, band; show_progress=false) where {C<:AbstractArray}
  buffer = Array{ArchGDAL.pixeltype(band)}(undef, ArchGDAL.blocksize(band)..., 1)
  ndv = convert(ArchGDAL.pixeltype(band), ArchGDAL.getnodatavalue(band))

  total_p = ArchGDAL.width(ds) * ArchGDAL.height(ds)
  current_fill = 0
  p = 0
  if show_progress
    print("read progress: 0 ")
  end

  for (cols, rows) in ArchGDAL.windows(band)
    ArchGDAL.read!(ds.ds, buffer, [1], rows, cols)
    insert_data!(data, buffer, cols[1], cols[length(cols)], rows[1], rows[length(rows)], ndv)
    current_fill += (cols[length(cols)] - cols[1] + 1) * (rows[length(rows)] - rows[1] + 1)

    if show_progress
      if floor(Int, current_fill / total_p * 10) > p
        p = floor(Int, current_fill / total_p * 10)
        print("$(p*10) ")
      end
    end
  end

  if show_progress
    println()
  end
end

function read_geotiff_to_geoarray_2d(::Type{C}, ::Type{E}, init, fn::String, b::Int; show_progress=false) where {C<:AbstractArray,E<:Number}
  ds = ArchGDAL.readraster(fn)
  band = ArchGDAL.getband(ds, b)
  ndv = convert(ArchGDAL.pixeltype(band), ArchGDAL.getnodatavalue(band))

  data = C{E}(init, ArchGDAL.width(ds), ArchGDAL.height(ds))
  data .= ndv
  read_geotiff_data(data, ds, band, show_progress=show_progress)

  ret = GeoArrays.GeoArray(data)
  ret.f = GeoArrays.geotransform_to_affine(ArchGDAL.getgeotransform(ds))
  ret.crs = GeoFormatTypes.WellKnownText(GeoFormatTypes.CRS(), ArchGDAL.getproj(ds))
  ret.metadata = GeoArrays.getmetadata(ds)
  ret.metadata["NoData Value"] = Dict("NoData Value" => string(ndv))
  ArchGDAL.destroy(ds)

  return ret
end

function read_geotiff_to_geoarray_2d(::Type{C}, ::Type{E}, ::Type{I}, init, fn::String, b::Int; show_progress=false) where {C<:AbstractArray,E<:Number,I<:Number}
  ds = ArchGDAL.readraster(fn)
  band = ArchGDAL.getband(ds, b)
  ndv = convert(ArchGDAL.pixeltype(band), ArchGDAL.getnodatavalue(band))

  data = C{E,I}(init, ArchGDAL.width(ds), ArchGDAL.height(ds))
  read_geotiff_data(data, ds, band, show_progress=show_progress)

  ret = GeoArrays.GeoArray(data)
  ret.f = GeoArrays.geotransform_to_affine(ArchGDAL.getgeotransform(ds))
  ret.crs = GeoFormatTypes.WellKnownText(GeoFormatTypes.CRS(), ArchGDAL.getproj(ds))
  ret.metadata = GeoArrays.getmetadata(ds)
  ret.metadata["NoData Value"] = Dict("NoData Value" => string(ndv))
  ArchGDAL.destroy(ds)

  return ret
end

function read_geotiff_data_complete!(ga, filename::String, b::Integer=1; show_progress=false)

  read_geotiff_header!(ga, filename, b)

  ds = ArchGDAL.readraster(filename)
  band = ArchGDAL.getband(ds, b)

  read_geotiff_data(ga.A, ds, band, show_progress=show_progress)
  ArchGDAL.destroy(ds)
end


#
# Double check.
#
function read_geotiff_data_partial!(ga::GeoArray, x_start::Integer, x_end::Integer, y_start::Integer, y_end::Integer, band::Integer=1)

  dataset = GDAL.gdalopen(filename(ga), GDAL.GA_ReadOnly)
  band = GDAL.gdalgetrasterband(dataset, band)
  y_chunk_size = 1

  if y_start > y_end
    y_start, y_end = y_end, y_start
  end
  if y_start < 1
    y_start = 1
  end
  if y_end >= size(ga)[2]
    y_end = size(ga)[2]
  end

  if x_start > x_end
    x_start, x_end = x_end, x_start
  end
  if x_start < 1
    x_start = 1
  end
  if x_end >= size(ga)[1]
    x_end = size(ga)[1]
  end

  r_tiles = (y_end - y_start + 1) ÷ y_chunk_size
  remaining_r = (y_end - y_start + 1) % y_chunk_size
  scanline = fill(0.0f0, y_chunk_size * (x_end - x_start + 1))

  for r in 1:(r_tiles)
    #println("read: $(x_start - 1), $((r - 1) * y_chunk_size + (y_start - 1)), $((x_end - x_start + 1)), $y_chunk_size,")
    GDAL.gdalrasterio(band, GDAL.GF_Read, x_start - 1, (r - 1) * y_chunk_size + (y_start - 1), (x_end - x_start + 1), y_chunk_size, scanline, (x_end - x_start + 1), y_chunk_size, GDAL.GDT_Float32, 0, 0)
    insert_data!(ga.A, scanline, x_start, x_end, (r - 1) * y_chunk_size + y_start, (r - 1) * y_chunk_size + y_start + y_chunk_size - 1, no_data_value(ga))
  end

  if (remaining_r != 0)
    #println("GDAL.gdalrasterio(band,GDAL.GF_Read,$(x_start-1),$((r_tiles)*y_chunk_size+y_start),$(x_end - x_start + 1),$remaining_r,scanline,$(x_end - x_start + 1),$remaining_r,GDAL.GDT_Float32,0,0)")
    GDAL.gdalrasterio(band, GDAL.GF_Read, x_start - 1, (r_tiles) * y_chunk_size + y_start - 1, (x_end - x_start + 1), remaining_r, scanline, (x_end - x_start + 1), remaining_r, GDAL.GDT_Float32, 0, 0)
    insert_data!(ga.A, scanline, x_start, x_end, (r_tiles) * y_chunk_size + y_start, y_end, no_data_value(ga))
  end
  GDAL.gdalclose(dataset)
end


function read_box_around!(ga::GeoArray, p::Tuple{Real,Real}, radius::Real, y_chunk_size=1, f=identity)
  if (radius >= earth_circumference_km / 2)
    return read_geotiff_data_complete!(sga, filename(sga))
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

function partial_read_around!(sga::GeoArray, p::Tuple{Real,Real}, radius::Real, y_chunk_size=1, f=identity)

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

function write_geotiff(ga::GeoArrays.GeoArray, filename::String, y_chunk_size::Integer=1)
  GeoArrays.write(filename, ga; nodata=no_data_value(ga), options=Dict("compress" => "deflate", "bigtiff" => "yes", "blockxsize" => string(size(ga)[1]), "blockysize" => "1"))
end

# todo: handle existing files. 
function save_geotiff_data_complete(ga::GeoArrays.GeoArray, filename::String, y_chunk_size::Integer=1)
  fn = split(filename, ".")
  if (size(fn) == 1)
    return
  end

  ext = fn[end]
  driver = GDAL.gdalgetdriverbyname("GTiff")
  if lowercase(ext) in ["tif" "gtif" "geotif" "tiff" "gtiff" "geotiff"]
    driver = GDAL.gdalgetdriverbyname("GTiff")
  end

  opts = ["COMPRESS=DEFLATE", "BIGTIFF=YES", "BLOCKXSIZE=" * string(size(ga)[1]), "BLOCKYSIZE=1"]
  dataset = GDAL.gdalcreate(driver, filename, size(ga)[1], size(ga)[2], 1, GDAL.GDT_Float32, opts)
  band = GDAL.gdalgetrasterband(dataset, 1)

  GDAL.gdalsetrasternodatavalue(band, no_data_value(ga))
  GDAL.gdalsetprojection(dataset, GeoFormatTypes.val(ga.crs))
  GDAL.gdalsetgeotransform(dataset, GeoArrays.affine_to_geotransform(ga.f))

  r_tiles = size(ga)[2] ÷ y_chunk_size
  remaining_r = size(ga)[2] % y_chunk_size
  #scanline = fill(0.0f0, y_chunk_size * size(ga)[1])

  print("write progress: 0 ")
  p = 0

  #for r in 1:size(ga)[2]
  for r in 1:r_tiles
    scanline = ga[:, ((r-1)*y_chunk_size+1):(r*y_chunk_size)]
    GDAL.gdalrasterio(band, GDAL.GF_Write, 0, (r - 1) * y_chunk_size, size(ga)[1], y_chunk_size, scanline, size(ga)[1], y_chunk_size, GDAL.GDT_Float32, 0, 0)

    if (((r * y_chunk_size) * 100 ÷ size(ga)[2]) ÷ 10) > p
      p = (((r * y_chunk_size) * 100 ÷ size(ga)[2]) ÷ 10)
      print("$(p*10) ")
    end
  end

  if (remaining_r != 0)
    scanline = ga[:, ((r_tiles)*y_chunk_size-1):(size(ga)[2])]
    GDAL.gdalrasterio(band, GDAL.GF_Write, 0, (r_tiles) * y_chunk_size - 1, size(ga)[1], remaining_r, scanline, size(ga)[1], remaining_r, GDAL.GDT_Float32, 0, 0)
    print("100")
  end

  println()
  GDAL.gdalclose(dataset)
end

# todo: handle existing files. 
function save_geotiff_data_complete(ga::GeoArrays.GeoArray{DT, 2, SparseArrayADOR{DT, IT}}, filename::String, y_chunk_size::Integer=1) where {DT,IT}
  fn = split(filename, ".")
  if (size(fn) == 1)
    return
  end

  ext = fn[end]
  driver = GDAL.gdalgetdriverbyname("GTiff")
  if lowercase(ext) in ["tif" "gtif" "geotif" "tiff" "gtiff" "geotiff"]
    driver = GDAL.gdalgetdriverbyname("GTiff")
  end

  opts = ["COMPRESS=DEFLATE", "BIGTIFF=YES", "BLOCKXSIZE=" * string(size(ga)[1]), "BLOCKYSIZE=1"]
  dataset = GDAL.gdalcreate(driver, filename, size(ga)[1], size(ga)[2], 1, GDAL.GDT_Float32, opts)
  band = GDAL.gdalgetrasterband(dataset, 1)

  GDAL.gdalsetrasternodatavalue(band, no_data_value(ga))
  GDAL.gdalsetprojection(dataset, GeoFormatTypes.val(ga.crs))
  GDAL.gdalsetgeotransform(dataset, GeoArrays.affine_to_geotransform(ga.f))

  r_tiles = size(ga)[2] ÷ y_chunk_size
  remaining_r = size(ga)[2] % y_chunk_size

  print("write progress: 0 ")
  p = 0

  it = iterate(GeoArrayIndexValueIterator(ga))

  for r in 1:r_tiles
    scanline = fill(no_data_value(ga), y_chunk_size * size(ga)[1])

    while it !== nothing
      ind_val, state = it
      if ind_val[1][2] > (r * y_chunk_size)
        break
      end
      row = ind_val[1][2] - ((r-1) * y_chunk_size)
      scanline[(row-1) * size(ga)[1] + ind_val[1][1]] = ind_val[2]
      it = iterate(GeoArrayIndexValueIterator(ga), state)
    end

    GDAL.gdalrasterio(band, GDAL.GF_Write, 0, (r - 1) * y_chunk_size, size(ga)[1], y_chunk_size, scanline, size(ga)[1], y_chunk_size, GDAL.GDT_Float32, 0, 0)

    if (((r * y_chunk_size) * 100 ÷ size(ga)[2]) ÷ 10) > p
      p = (((r * y_chunk_size) * 100 ÷ size(ga)[2]) ÷ 10)
      print("$(p*10) ")
    end
  end

  if (remaining_r != 0)
    scanline = fill(no_data_value(ga), (remaining_r * size(ga)[1]))

    while it !== nothing
      ind_val, state = it
      row = ind_val[1][2] - (r_tiles*y_chunk_size)
      scanline[row * size(ga)[1] + ind_val[1][1]] = ind_val[2]
      it = iterate(GeoArrayIndexValueIterator(ga), state)
    end

    GDAL.gdalrasterio(band, GDAL.GF_Write, 0, (r_tiles) * y_chunk_size - 1, size(ga)[1], remaining_r, scanline, size(ga)[1], remaining_r, GDAL.GDT_Float32, 0, 0)
    print("100")
  end

  println()
  GDAL.gdalclose(dataset)
end


# todo: handle existing files. 
function save_data_complete_csv(ga::GeoArray, filename::String, lonlat::Bool=false)
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
    write(f, "$(ga.crs)\n")
    write(f, "$(size(ga)[1]),$(size(ga)[2])\n")
    write(f, "$(no_data_value(ga))\n")
    write(f, "$(convert(Int8,lonlat))\n")

    #=    for (indices, data) in ga.data
          if lonlat
            write(f, "$(coords(sga_florida_dtm,indices)[1]),$(coords(sga_florida_dtm,indices)[2]),$data\n")
          else
            write(f, "$(indices[1]-1),$(indices[2]-1),$data\n")
          end
        end
    =#
  end
end


function read_geotiff_header!(ga::GeoArrays.GeoArray, filename::String, b::Integer=1)
  dataset = ArchGDAL.readraster(filename)
  band = ArchGDAL.getband(dataset, b)

  ysize = ArchGDAL.height(dataset)
  xsize = ArchGDAL.width(dataset)

  cintref = Ref(Cint(-1))
  nodatavalue = convert(eltype(ga), GDAL.gdalgetrasternodatavalue(band, cintref))

  data = create(ga.A, nodatavalue, xsize, ysize)

  ga.A = data
  ga.f = GeoArrays.geotransform_to_affine(ArchGDAL.getgeotransform(dataset))
  ga.crs = GeoFormatTypes.WellKnownText(GeoFormatTypes.CRS(), ArchGDAL.getproj(dataset))
  ga.metadata = GeoArrays.getmetadata(dataset)
  ga.metadata["NoData Value"] = Dict("NoData Value" => string(nodatavalue))
  ga.metadata["FILENAME"] = Dict("FILENAME" => filename)

  ArchGDAL.destroy(dataset)
end

function insert_categorized_data!(ga_data::GeoArray{E1,N1,C1}, gas::Dict{CT,GeoArray{E2,N2,C2}}, data::Array{DT1}, categories::Array{DT2}, x_start::Integer, x_end::Integer, y_start::Integer, y_end::Integer, ndv_data, ndv_cat) where {CT<:Integer,E1,N1,C1,E2,N2,C2,DT1,DT2}
  xs = (x_end - x_start + 1)
  for y in y_start:y_end
    for x in x_start:x_end
      cat = categories[((y-y_start)*xs+(x-x_start)+1)]
      dat = data[((y-y_start)*xs+(x-x_start)+1)]
      if cat != ndv_cat && dat != ndv_data
        if !haskey(gas, cat)
          gas[cat] = empty_copy_from_geo_array(C2, ga_data, ndv_data)
        end
        gas[cat][x, y] = dat
      end
    end
  end
end


function read_geotiff_data_categorised!(gas::Dict{CT,GeoArray{E,N,C}}, filename_data::String, filename_categories::String, b::Integer=1; show_progress=false) where {CT<:Integer,E,N,C}
  ga_data = empty_geo_array(SparseArrayDOK{Float32,Int32})
  read_geotiff_header!(ga_data, filename_data, b)

  ds_data = ArchGDAL.readraster(filename_data)
  band_data = ArchGDAL.getband(ds_data, b)
  buffer_data = Array{ArchGDAL.pixeltype(band_data)}(undef, ArchGDAL.blocksize(band_data)..., 1)
  ndv_data = convert(ArchGDAL.pixeltype(band_data), ArchGDAL.getnodatavalue(band_data))

  ga_categories = empty_geo_array(SparseArrayDOK{Float32,Int32})
  read_geotiff_header!(ga_categories, filename_categories, b)

  ds_categories = ArchGDAL.readraster(filename_categories)
  band_categories = ArchGDAL.getband(ds_categories, b)
  buffer_categories = Array{ArchGDAL.pixeltype(band_categories)}(undef, ArchGDAL.blocksize(band_categories)..., 1)
  ndv_categories = convert(ArchGDAL.pixeltype(band_categories), ArchGDAL.getnodatavalue(band_categories))

  if (size(ga_data)[1] != size(ga_categories)[1]) || (size(ga_data)[2] != size(ga_categories)[2])
    error("DimensionError: attempt categorized read of $filename_data ($(size(ga_data)[1])×$(size(ga_data)[2])) and $filename_categories ($(size(ga_categories)[1])×$(size(ga_categories)[2]))")
  end
  if (ga_data.crs != ga_categories.crs)
    error("ProjRefError: attempt categorized read of $filename_data ($(sga_data.projref)) and $filename_categories ($(sga_categories.projref))")
  end
  if (ga_data.f != ga_categories.f)
    error("GeoTransformError: attempt categorized read of $filename_data ($(ga_data.f)) and $filename_categories ($(ga_categories.f))")
  end
  if (ArchGDAL.blocksize(band_data) != ArchGDAL.blocksize(band_categories))
    warn("different blocksize might be inefficient: data from $filename_data has $(ArchGDAL.blocksize(band_data))) while categories data from $filename_categories has $(ArchGDAL.blocksize(band_categories))")
  end

  total_p = ArchGDAL.width(ds_data) * ArchGDAL.height(ds_data)
  current_fill = 0
  p = 0
  if show_progress
    print("read progress: 0 ")
  end

  for (cols, rows) in ArchGDAL.windows(band_data)
    ArchGDAL.read!(ds_data.ds, buffer_data, [1], rows, cols)
    ArchGDAL.read!(ds_categories.ds, buffer_categories, [1], rows, cols)
    #if haskey(gas,1082) println("before: ",gas[1082].A.memory[16495]) end
    insert_categorized_data!(ga_data, gas, buffer_data, buffer_categories, cols[1], cols[length(cols)], rows[1], rows[length(rows)], ndv_data, ndv_categories)
    #if haskey(gas,1082) println("after: ",gas[1082].A.memory[16495]) end
    current_fill += (cols[length(cols)] - cols[1] + 1) * (rows[length(rows)] - rows[1] + 1)

    if show_progress
      if floor(Int, current_fill / total_p * 10) > p
        p = floor(Int, current_fill / total_p * 10)
        print("$(p*10) ")
      end
    end
  end

  if show_progress
    println()
  end
end

function read_geotiff_data_filtered!(ga::GeoArray, filename::String, f::Function, band::Integer=1)
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
        scanline[i] = no_data_value(ga)
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
        scanline[i] = no_data_value(ga)
      end
    end
    (ga, scanline, 1, ga.xsize, (r_tiles) * row_chunk_size + 1, (r_tiles) * row_chunk_size + 1 + remaining_r)
  end
  println()
  GDAL.gdalclose(dataset)
end



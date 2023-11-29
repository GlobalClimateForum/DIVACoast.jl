function read_geotiff_data_complete(sgr :: SparseGeoArray{DT, IT}, filename :: String, band :: Integer = 1, row_chunk_size :: Integer = 1) where {DT <: Real, IT <: Integer}

  read_geotiff_header(sgr, filename, band)
  dataset = GDAL.gdalopen(filename, GDAL.GA_ReadOnly)
  band = GDAL.gdalgetrasterband(dataset, band)
  
  r_tiles = sgr.ysize ÷ row_chunk_size
  remaining_r = sgr.ysize % row_chunk_size
  scanline = fill(0.0f0, row_chunk_size * sgr.xsize)

  print("read progress: 0 ")
  p = 0

  for r in 1:(r_tiles) 
    GDAL.gdalrasterio(band,GDAL.GF_Read,0,(r-1)*row_chunk_size,sgr.xsize,row_chunk_size,scanline,sgr.xsize,row_chunk_size,GDAL.GDT_Float32,0,0)
    private_insert_data(sgr, scanline, 1, sgr.xsize, (r-1)*row_chunk_size+1, r*row_chunk_size)
    if (((r*row_chunk_size)*100 ÷ sgr.ysize) ÷ 10)>p
      p=(((r*row_chunk_size)*100 ÷ sgr.ysize) ÷ 10)
      print("$(p*10) ")
    end
  end
  
  if (remaining_r != 0) 
    GDAL.gdalrasterio(band,GDAL.GF_Read,0,(r_tiles)*row_chunk_size-1,sgr.xsize,remaining_r,scanline,sgr.xsize,remaining_r,GDAL.GDT_Float32,0,0)
    private_insert_data(sgr, scanline, 1, sgr.xsize, (r_tiles)*row_chunk_size+1, (r_tiles)*row_chunk_size + 1 + remaining_r)
  end
  println()
  GDAL.gdalclose(dataset)
end


function read_geotiff_data_partial(sgr :: SparseGeoArray{DT, IT}, x_start :: Integer, x_end :: Integer, y_start :: Integer, y_end :: Integer, band :: Integer = 1; y_chunk_size :: Integer = 1) where {DT <: Real, IT <: Integer}

  dataset = GDAL.gdalopen(sgr.filename, GDAL.GA_ReadOnly)
  band = GDAL.gdalgetrasterband(dataset, band)
  
  if y_start>y_end  y_start,y_end=y_end,y_start end
  if y_start<1        y_start=1 end
  if y_end>=sgr.ysize y_end=sgr.ysize end

  if x_start>x_end  x_start,x_end=x_end,x_start end
  if x_start<1        x_start=1 end
  if x_end>=sgr.xsize x_end=sgr.xsize end

  r_tiles = (y_end - y_start + 1) ÷ y_chunk_size
  remaining_r = (y_end - y_start + 1) % y_chunk_size
  scanline = fill(0.0f0, y_chunk_size * (x_end - x_start + 1))

  for r in 1:(r_tiles) 
    GDAL.gdalrasterio(band,GDAL.GF_Read,x_start-1,(r-1)*y_chunk_size+(y_start-1),(x_end - x_start + 1),y_chunk_size,scanline,(x_end - x_start + 1),y_chunk_size,GDAL.GDT_Float32,0,0)
    private_insert_data(sgr, scanline, x_start, x_end, (r-1)*y_chunk_size+y_start, (r-1)*y_chunk_size+y_start+y_chunk_size-1)
  end
  
  if (remaining_r != 0) 
#    println("GDAL.gdalrasterio(band,GDAL.GF_Read,$(x_start-1),$((r_tiles)*y_chunk_size+y_start),$(x_end - x_start + 1),$y_chunk_size,scanline,$(x_end - x_start + 1),$remaining_r,GDAL.GDT_Float32,0,0)")
    GDAL.gdalrasterio(band,GDAL.GF_Read,x_start-1,(r_tiles)*y_chunk_size+y_start,(x_end - x_start + 1),remaining_r,scanline,(x_end - x_start + 1),remaining_r,GDAL.GDT_Float32,0,0)
    private_insert_data(sgr, scanline, x_start, x_end, (r_tiles)*y_chunk_size+y_start+1, y_end)
  end
  GDAL.gdalclose(dataset)
end


function partial_read_around(sga :: SparseGeoArray{DT, IT}, p :: Tuple{Real, Real}, radius :: Real, y_chunk_size=1, f=identity) where {DT <: Real, IT <: Integer}
        
  if (radius>=earth_circumference_km/2) 
    read_geotiff_data_complete(sga,sga.filename)
  else
    sgat= SparseGeoArray{DT,IT}(Dict{Tuple{IT,IT},DT}(), sga.nodatavalue, sga.f, sga.crs, sga.metadata, sga.xsize, sga.ysize, sga.projref, sga.circular, sga.filename)

    p_east = go_direction(p, radius, East())
    p_west = go_direction(p, radius, West())
    p_north = go_direction(p, radius, North())
    p_south = go_direction(p, radius, South())

    bb = bounding_boxes(sga, p_east[1],p_west[1],p_south[2],p_north[2])

    for b in bb
      read_geotiff_data_partial(sgat, b[1], b[3], b[2], b[4], y_chunk_size = y_chunk_size)
      for (indices,value) in sgat.data
        if (distance(Tuple(coords(sga::SparseGeoArray, indices, Center())), p) <= radius) 
          if ((sga[indices[1],indices[2]]==sga.nodatavalue)) sga[indices[1],indices[2]]=f(value) end
        end
      end
    end
  end
end


# todo: handle existing files. 
function save_geotiff_data_complete(sgr :: SparseGeoArray{DT, IT}, filename :: String, y_chunk_size :: Integer = 1) where {DT <: Real, IT <: Integer}
  fn = split(filename, ".")
  if (size(fn)==1) return end

  ext = fn[end]
  driver = GDAL.gdalgetdriverbyname("GTiff")
  if lowercase(ext) in ["tif" "gtif" "geotif" "tiff" "gtiff" "geotiff"] 
    driver = GDAL.gdalgetdriverbyname("GTiff")
  end

  opts = ["COMPRESS=DEFLATE", "BIGTIFF=YES"]
  dataset = GDAL.gdalcreate(driver, filename, sgr.xsize, sgr.ysize, 1, GDAL.GDT_Float32, opts)
  band = GDAL.gdalgetrasterband(dataset, 1)

  GDAL.gdalsetrasternodatavalue(band,sgr.nodatavalue)
  GDAL.gdalsetprojection(dataset, sgr.projref)
  GDAL.gdalsetgeotransform(dataset, affine_to_geotransform(sgr.f))

  r_tiles = sgr.ysize ÷ y_chunk_size
  remaining_r = sgr.ysize % y_chunk_size
  scanline = fill(0.0f0, y_chunk_size * sgr.xsize)

  print("write progress: 0 ")
  p = 0

  for r in 1:(r_tiles) 
#    println("write $((r-1)*y_chunk_size) - $((r*y_chunk_size)-1)") 
#    println("GDAL.gdalrasterio($band,GDAL.GF_Write,0,$((r-1)*y_chunk_size),$(sgr.xsize),$y_chunk_size,scanline,$(sgr.xsize),$y_chunk_size,GDAL.GDT_Float16,0,0)") 
    private_getData(sgr, scanline, y_chunk_size, (r-1)*y_chunk_size)
    GDAL.gdalrasterio(band,GDAL.GF_Write,0,(r-1)*y_chunk_size,sgr.xsize,y_chunk_size,scanline,sgr.xsize,y_chunk_size,GDAL.GDT_Float32,0,0)
    if (((r*y_chunk_size)*100 ÷ sgr.ysize) ÷ 10)>p
      p=(((r*y_chunk_size)*100 ÷ sgr.ysize) ÷ 10)
      print("$(p*10) ")
    end
  end

  if (remaining_r != 0) 
    private_getData(sgr, scanline, remaining_r, (r_tiles)*y_chunk_size-1)
    GDAL.gdalrasterio(band,GDAL.GF_Write,0,(r_tiles)*y_chunk_size-1,sgr.xsize,remaining_r,scanline,sgr.xsize,remaining_r,GDAL.GDT_Float32,0,0)
    print("100")
  end
  println()
  GDAL.gdalclose(dataset)
end


function read_geotiff_header(sgr :: SparseGeoArray{DT, IT}, filename :: String, band :: Integer = 1) where {DT <: Real, IT <: Integer}
  dataset = GDAL.gdalopen(filename, GDAL.GA_ReadOnly)
  sgr.filename = filename

  sgr.xsize = GDAL.gdalgetrasterxsize(dataset)     
  sgr.ysize = GDAL.gdalgetrasterysize(dataset)     
  sgr.projref = GDAL.gdalgetprojectionref(dataset)
  geotransform = fill(0.0, 6)
  GDAL.gdalgetgeotransform(dataset, geotransform)
  sgr.f=geotransform_to_affine(geotransform)

  band = GDAL.gdalgetrasterband(dataset, band)
  cintref = Ref(Cint(-1))
  sgr.nodatavalue = convert(DT,GDAL.gdalgetrasternodatavalue(band,cintref))

  # epsg!(sgr, sgr.projref)
  GDAL.gdalclose(dataset)
end


function private_insert_data(sgr :: SparseGeoArray{DT, IT}, data :: Vector{Float32}, ysize :: Integer, r_offset :: Integer) where {DT <: Real, IT <: Integer}
  for j in 1:sgr.xsize
    for i in 1:ysize
      val = data[((i-1)*sgr.xsize + (j-1))+1]
      if val!=sgr.nodatavalue sgr.data[(j,i+r_offset)]=val end
    end
  end
end


function private_insert_data(sgr :: SparseGeoArray{DT, IT}, data :: Vector{Float32}, x_start :: Integer, x_end :: Integer, y_start :: Integer, y_end :: Integer) where {DT <: Real, IT <: Integer}
  xs = (x_end-x_start+1)
  for y in y_start:y_end
    for x in x_start:x_end
      val = data[((y-y_start)*xs + (x-x_start)+1)]
      if val!=sgr.nodatavalue sgr.data[(x,y)]=val end
    end
  end
end


function private_getData(sgr :: SparseGeoArray{DT, IT}, data :: Vector{Float32}, ysize :: Integer, r_offset :: Integer) where {DT <: Real, IT <: Integer}
  for j in 1:sgr.xsize
    for i in 1:ysize
      data[((i-1)*sgr.xsize + (j-1))+1] = sgr[j,i+r_offset]
    end
  end
end


function private_insertCategorisedData(sgrs :: Dict{CT,SparseGeoArray{DT, IT}}, sgr_data :: SparseGeoArray{DT, IT}, sgr_categories :: SparseGeoArray{DT, IT}, data :: Vector{DT}, categories :: Vector{DT}, ysize :: Integer, r_offset :: Integer) where {CT <: Integer ,DT <: Real, IT <: Integer}
  for j in 1:sgr_data.xsize
    for i in 1:ysize
      val = data[((i-1)*sgr_data.xsize + (j-1))+1]
      cat = convert(CT,categories[((i-1)*sgr_data.xsize + (j-1))+1])
      if val!=sgr_data.nodatavalue && cat!=sgr_categories.nodatavalue 
        if !haskey(sgrs, cat)
          sgr_t = SparseGeoArray{DT,IT}(Dict{Tuple{IT,IT},DT}(), sgr_data.nodatavalue, sgr_data.f, sgr_data.crs, sgr_data.metadata, sgr_data.xsize, sgr_data.ysize, sgr_data.projref, sgr_data.circular)
          sgrs[cat] = sgr_t
        end
        sgrs[cat][(j,i+r_offset)]=val
      end
    end
  end
end


function readGEOTiffDataCategorised(sgrs :: Dict{CT, SparseGeoArray{DT, IT}}, filename_data :: String, filename_categories :: String, band :: Integer = 1, row_chunk_size :: Integer = 1) where {CT <: Integer, DT <: Real, IT <: Integer}
  sga_data = SparseGeoArray{DT,IT}()
  read_geotiff_header(sga_data, filename_data, band)
  dataset_data = GDAL.gdalopen(filename_data, GDAL.GA_ReadOnly)
  band_data = GDAL.gdalgetrasterband(dataset_data, band)

  sga_categories = SparseGeoArray{DT,IT}()
  private_readGEOTiffHeader(sga_categories, filename_categories, band)
  dataset_categories = GDAL.gdalopen(filename_categories, GDAL.GA_ReadOnly)
  band_categories = GDAL.gdalgetrasterband(dataset_categories, band)

  if (sga_data.xsize != sga_categories.xsize) error("DimensionError: attempt categorized read of $filename_data ($(sga_data.xsize)×$(sga_data.ysize)) and $filename_categories ($(sga_categories.xsize)×$(sga_categories.ysize))") end
  if (sga_data.ysize != sga_categories.ysize) error("DimensionError: attempt categorized read of $filename_data ($(sga_data.xsize)×$(sga_data.ysize)) and $filename_categories ($(sga_categories.xsize)×$(sga_categories.ysize))") end
  if (sga_data.projref != sga_categories.projref) error("ProjRefError: attempt categorized read of $filename_data ($(sga_data.projref)) and $filename_categories ($(sga_categories.projref))") end
  if (sga_data.f != sga_categories.f) error("GeoTransfomError: attempt categorized read of $filename_data ($(sga_data.f)) and $filename_categories ($(sga_categories.f))") end

  r_tiles = sga_data.ysize ÷ convert(IT,row_chunk_size)
  remaining_r = sga_data.ysize % convert(IT,row_chunk_size)
  scanline_data = fill(0.0f0, row_chunk_size * sga_data.xsize)
  scanline_categories = fill(0.0f0, row_chunk_size * sga_data.xsize)
  print("read progress: 0 ")
  p = 0

  for r in 1:(r_tiles) 
    GDAL.gdalrasterio(band_data,GDAL.GF_Read,0,(r-1)*row_chunk_size,sga_data.xsize,row_chunk_size,scanline_data,sga_data.xsize,row_chunk_size,GDAL.GDT_Float32,0,0)
    GDAL.gdalrasterio(band_categories,GDAL.GF_Read,0,(r-1)*row_chunk_size,sga_data.xsize,row_chunk_size,scanline_categories,sga_data.xsize,row_chunk_size,GDAL.GDT_Float32,0,0)

    private_insertCategorisedData(sgrs, sga_data, sga_categories, scanline_data, scanline_categories, row_chunk_size, (r-1)*row_chunk_size)
    if (((r*row_chunk_size)*100 ÷ sga_data.ysize) ÷ 10)>p
      p=(((r*row_chunk_size)*100 ÷ sga_data.ysize) ÷ 10)
      print("$(p*10) ")
    end
  end
  
  if (remaining_r != 0) 
    GDAL.gdalrasterio(band_data,GDAL.GF_Read,0,(r_tiles)*row_chunk_size-1,sga_data.xsize,remaining_r,scanline_data,sga_data.xsize,remaining_r,GDAL.GDT_Float32,0,0)
    GDAL.gdalrasterio(band_categories,GDAL.GF_Read,0,(r_tiles)*row_chunk_size-1,sga_data.xsize,remaining_r,scanline_categories,sga_data.xsize,remaining_r,GDAL.GDT_Float32,0,0)
    private_insertCategorisedData(sgrs, sga_data, sga_categories, scanline_data, scanline_categories,  remaining_r, (r_tiles)*row_chunk_size-1)
  end
  println()
  GDAL.gdalclose(dataset_data)
  GDAL.gdalclose(dataset_categories)
end



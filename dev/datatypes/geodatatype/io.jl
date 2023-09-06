function readGEOTiffDataComplete(sgr :: SparseGeoArray{DT, IT}, filename :: String, band :: Integer = 1, row_chunk_size :: Integer = 1) where {DT <: Real, IT <: Integer}

  private_readGEOTiffHeader(sgr, filename, band)
  dataset = GDAL.gdalopen(filename, GDAL.GA_ReadOnly)
  band = GDAL.gdalgetrasterband(dataset, band)
  
  r_tiles = sgr.ysize ÷ row_chunk_size
  remaining_r = sgr.ysize % row_chunk_size
  scanline = fill(0.0f0, row_chunk_size * sgr.xsize)

  print("read: 0 ")
  p = 0

  for r in 1:(r_tiles) 
#    println("read $((r-1)*row_chunk_size) - $((r*row_chunk_size)-1)") 
#    println("GDAL.gdalrasterio($band,GDAL.GF_Read,0,$((r-1)*row_chunk_size),$(sgr.xsize),$row_chunk_size,scanline,$(sgr.xsize),$row_chunk_size,GDAL.GDT_Float16,0,0)") 
    GDAL.gdalrasterio(band,GDAL.GF_Read,0,(r-1)*row_chunk_size,sgr.xsize,row_chunk_size,scanline,sgr.xsize,row_chunk_size,GDAL.GDT_Float32,0,0)
    private_insertData(sgr, scanline, row_chunk_size, (r-1)*row_chunk_size)
    if (((r*row_chunk_size)*100 ÷ sgr.ysize) ÷ 10)>p
      p=(((r*row_chunk_size)*100 ÷ sgr.ysize) ÷ 10)
      print("$(p*10) ")
    end
  end
  
  if (remaining_r != 0) 
#    println("remaining")
#    println("GDAL.gdalrasterio($band,GDAL.GF_Read,0,$((r_tiles)*row_chunk_size-1),$(sgr.xsize),$remaining_r,scanline,$(sgr.xsize),$remaining_r,GDAL.GDT_Float32,0,0)") 
    GDAL.gdalrasterio(band,GDAL.GF_Read,0,(r_tiles)*row_chunk_size-1,sgr.xsize,remaining_r,scanline,sgr.xsize,remaining_r,GDAL.GDT_Float32,0,0)
#    println("insert data $(remaining_r) $((r_tiles)*row_chunk_size-1)")
    private_insertData(sgr, scanline, remaining_r, (r_tiles)*row_chunk_size-1)
#    print("100")
  end
  println()
  GDAL.gdalclose(dataset)
end


function saveGEOTiffDataComplete(sgr :: SparseGeoArray{DT, IT}, filename :: String, row_chunk_size :: Integer = 1) where {DT <: Real, IT <: Integer}
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
  GDAL.gdalsetgeotransform(dataset, affine_to_geotransform(sgr.f))

  r_tiles = sgr.ysize ÷ row_chunk_size
  remaining_r = sgr.ysize % row_chunk_size
  scanline = fill(0.0f0, row_chunk_size * sgr.xsize)

  print("write: 0 ")
  p = 0

  for r in 1:(r_tiles) 
#    println("write $((r-1)*row_chunk_size) - $((r*row_chunk_size)-1)") 
#    println("GDAL.gdalrasterio($band,GDAL.GF_Write,0,$((r-1)*row_chunk_size),$(sgr.xsize),$row_chunk_size,scanline,$(sgr.xsize),$row_chunk_size,GDAL.GDT_Float16,0,0)") 
    private_getData(sgr, scanline, row_chunk_size, (r-1)*row_chunk_size)
    GDAL.gdalrasterio(band,GDAL.GF_Write,0,(r-1)*row_chunk_size,sgr.xsize,row_chunk_size,scanline,sgr.xsize,row_chunk_size,GDAL.GDT_Float32,0,0)
    if (((r*row_chunk_size)*100 ÷ sgr.ysize) ÷ 10)>p
      p=(((r*row_chunk_size)*100 ÷ sgr.ysize) ÷ 10)
      print("$(p*10) ")
    end
  end

  if (remaining_r != 0) 
    private_getData(sgr, scanline, remaining_r, (r_tiles)*row_chunk_size-1)
    GDAL.gdalrasterio(band,GDAL.GF_Write,0,(r_tiles)*row_chunk_size-1,sgr.xsize,remaining_r,scanline,sgr.xsize,remaining_r,GDAL.GDT_Float32,0,0)
    print("100")
  end
  println()
  GDAL.gdalclose(dataset)
end

function private_readGEOTiffHeader(sgr :: SparseGeoArray{DT, IT}, filename :: String, band :: Integer = 1) where {DT <: Real, IT <: Integer}
  dataset = GDAL.gdalopen(filename, GDAL.GA_ReadOnly)

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

function private_insertData(sgr :: SparseGeoArray{DT, IT}, data :: Vector{Float32}, ysize :: Integer, r_offset :: Integer) where {DT <: Real, IT <: Integer}
  for j in 1:sgr.xsize
    for i in 1:ysize
      val = data[((i-1)*sgr.xsize + (j-1))+1]
      if val!=sgr.nodatavalue sgr.data[(j,i+r_offset)]=val end
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



#
#    void readGEOTiffDataComplete(std::string filename, int raster_band, Logger _log);
#    void readGEOTiffDataComplete(std::string filename, size_type tiles_x, size_type tiles_y, int raster_band, Logger _log);
#    void readGEOTiffDataPartial(std::string filename, size_type x_low, size_type x_high, size_type y_low, size_type y_high, int raster_band, Logger _log, bool do_log=true);
#
#    template<typename F> void readGEOTiffDataCompleteFiltered(std::string filename, size_type tiles_x, size_type tiles_y, int raster_band, F const& f, Logger _log);
#    template<typename F> void readGEOTiffDataCompleteFilteredByArea(std::string filename, size_type tiles_x, size_type tiles_y, int raster_band, F const& f, Logger _log);
#    template<typename F> void readGEOTiffDataPartialFiltered(std::string filename, size_type x_low, size_type x_high, size_type y_low, size_type y_high, int raster_band, F const& f, Logger _log);
#
#    void readCSVHeader      (std::string filename, Logger _log);
#    void readCSVDataComplete(std::string filename, Logger _log);
#    // Filtered?
#
#    void readCSVDataPartial (std::string filename, size_type x_low, size_type x_high, size_type y_low, size_type y_high, Logger _log, bool do_log=true);
#
#    void saveGEOTiff(std::string filename, std::string format);
#    void saveGEOTiff(std::string filename, std::string format, size_type tiles_x, size_type tiles_y);
#    void saveInExistingGEOTiff(std::string filename, std::string format, size_type tiles_x, size_type tiles_y);
#    void saveCSV(std::string filename, bool lonlat=false);
#
#


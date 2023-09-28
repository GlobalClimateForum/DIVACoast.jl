function readGEOTiffDataComplete(sgr :: SparseGeoArray{DT, IT}, filename :: String, band :: Integer = 1, row_chunk_size :: Integer = 1) where {DT <: Real, IT <: Integer}

  private_readGEOTiffHeader(sgr, filename, band)
  dataset = GDAL.gdalopen(filename, GDAL.GA_ReadOnly)
  band = GDAL.gdalgetrasterband(dataset, band)
  
  r_tiles = sgr.ysize ÷ row_chunk_size
  remaining_r = sgr.ysize % row_chunk_size
  scanline = fill(0.0f0, row_chunk_size * sgr.xsize)

  print("read progress: 0 ")
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

  print("write progress: 0 ")
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
  private_readGEOTiffHeader(sga_data, filename_data, band)
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


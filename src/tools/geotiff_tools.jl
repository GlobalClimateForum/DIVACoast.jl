export geotiff_connect, geotiff_transform

function geotiff_connect(infilename1::String, infilename2::String, outfilename::String, f::Function)

    sga_in1 = SparseGeoArray{Float32,Int32}()
    read_geotiff_header!(sga_in1, infilename1, 1)
    dataset_in1_data = GDAL.gdalopen(infilename1, GDAL.GA_ReadOnly)
    band_in1_data = GDAL.gdalgetrasterband(dataset_in1_data, 1)

    sga_in2 = SparseGeoArray{Float32,Int32}()
    read_geotiff_header!(sga_in2, infilename2, 1)
    dataset_in2_data = GDAL.gdalopen(infilename2, GDAL.GA_ReadOnly)
    band_in2_data = GDAL.gdalgetrasterband(dataset_in2_data, 1)

    driver = GDAL.gdalgetdriverbyname("GTiff")
    opts = ["COMPRESS=DEFLATE", "BIGTIFF=YES"]
    dataset_out = GDAL.gdalcreate(driver, outfilename, sga_in1.xsize, sga_in2.ysize, 1, GDAL.GDT_Float32, opts)
    band_out_data = GDAL.gdalgetrasterband(dataset_out, 1)

    GDAL.gdalsetrasternodatavalue(band_out_data, sga_in1.nodatavalue)
    GDAL.gdalsetprojection(dataset_out, sga_in1.projref)
    GDAL.gdalsetgeotransform(dataset_out, affine_to_geotransform(sga_in1.f))

    r_tiles = sga_in1.ysize ÷ 1
    remaining_r = sga_in1.ysize % 1
    scanline1 = fill(0.0f0, sga_in1.xsize)
    scanline2 = fill(0.0f0, sga_in1.xsize)
    outline = fill(0.0f0, sga_in1.xsize)

    print("processesing progress: 0 ")
    p = 0

    for r in 1:(r_tiles)
        GDAL.gdalrasterio(band_in1_data, GDAL.GF_Read, 0, (r - 1), sga_in1.xsize, 1, scanline1, sga_in1.xsize, 1, GDAL.GDT_Float32, 0, 0)
        GDAL.gdalrasterio(band_in2_data, GDAL.GF_Read, 0, (r - 1), sga_in2.xsize, 1, scanline2, sga_in2.xsize, 1, GDAL.GDT_Float32, 0, 0)

        for i in 1:size(scanline1, 1)
            outline[i] = f(scanline1[i], scanline2[i])
#            if (scanline2[i]!=sga_in2.nodatavalue) println("transform: $(scanline1[i]) and $(scanline2[i]) to $(outline[i])") end
        end
        GDAL.gdalrasterio(band_out_data, GDAL.GF_Write, 0, (r - 1), sga_in1.xsize, 1, outline, sga_in1.xsize, 1, GDAL.GDT_Float32, 0, 0)
        if ((r * 100 ÷ sga_in1.ysize) ÷ 10) > p
            p = ((r * 100 ÷ sga_in2.ysize) ÷ 10)
            print("$(p*10) ")
        end
    end

    println()
    GDAL.gdalclose(dataset_in1_data)
    GDAL.gdalclose(dataset_in2_data)
    GDAL.gdalclose(dataset_out)
end


function geotiff_transform(infilename1::String, outfilename::String, f::Function)

    sga_in1 = SparseGeoArray{Float32,Int32}()
    read_geotiff_header!(sga_in1, infilename1, 1)
    dataset_in1_data = GDAL.gdalopen(infilename1, GDAL.GA_ReadOnly)
    band_in1_data = GDAL.gdalgetrasterband(dataset_in1_data, 1)

    driver = GDAL.gdalgetdriverbyname("GTiff")
    opts = ["COMPRESS=DEFLATE", "BIGTIFF=YES"]
    dataset_out = GDAL.gdalcreate(driver, outfilename, sga_in1.xsize, sga_in1.ysize, 1, GDAL.GDT_Float32, opts)
    band_out_data = GDAL.gdalgetrasterband(dataset_out, 1)

    GDAL.gdalsetrasternodatavalue(band_out_data, sga_in1.nodatavalue)
    GDAL.gdalsetprojection(dataset_out, sga_in1.projref)
    GDAL.gdalsetgeotransform(dataset_out, affine_to_geotransform(sga_in1.f))

    r_tiles = sga_in1.ysize ÷ 1
    remaining_r = sga_in1.ysize % 1
    scanline1 = fill(0.0f0, sga_in1.xsize)
    outline = fill(0.0f0, sga_in1.xsize)

    print("processesing progress: 0 ")
    p = 0

    for r in 1:(r_tiles)
        GDAL.gdalrasterio(band_in1_data, GDAL.GF_Read, 0, (r - 1), sga_in1.xsize, 1, scanline1, sga_in1.xsize, 1, GDAL.GDT_Float32, 0, 0)

        for i in 1:size(scanline1, 1)
            outline[i] = f(scanline1[i])
            if (scanline1[i] == sga_in1.nodatavalue)
                outline[i] = sga_in1.nodatavalue
            end
        end
        GDAL.gdalrasterio(band_out_data, GDAL.GF_Write, 0, (r - 1), sga_in1.xsize, 1, outline, sga_in1.xsize, 1, GDAL.GDT_Float32, 0, 0)
        if ((r * 100 ÷ sga_in1.ysize) ÷ 10) > p
            p = ((r * 100 ÷ sga_in1.ysize) ÷ 10)
            print("$(p*10) ")
        end
    end

    println()
    GDAL.gdalclose(dataset_in1_data)
    GDAL.gdalclose(dataset_out)
end
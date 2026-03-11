"""
        geotiff_connect(infilename1::String, infilename2::String, outfilename::String, f::Function)

Takes two geofiffs and connects (combines) them pixelwise by a given function. The result is saved in a new geotiff file.

# Arguments
- `infilename1::String` : The path to the first input geotiff file.
- `infilename2::String` : The path to the second input geotiff file.
- `outfilename::String` : The path to the output geotiff file.
- `f::Function` : A function that will be applied pixelwise. Function definition must match the signature: <br> `f(value1::Float32, value2::Float32, sga1::SparseGeoArray, sga2::SparseGeoArray)`
  where `value1` and `value2` are the pixel values from the two input rasters, and `sga1` and `sga2` are the corresponding SparseGeoArray objects.
  <br>**Note:** _The SparseGeoArrays will be created from the input files_

# Example
```julia	
path1 = "path/to/input1.tif"
path2 = "path/to/input2.tif"
path_out = "path/to/output.tif"

takemaximum = (x, y, sga1, sga2) -> x > y ? x : y  # Takes the maximum of both files
geotiff_connect(path1, path2, path_out, takemaximum) 
```
"""
function geotiff_connect(infilename1::String, infilename2::String, outfilename::String, f::Function)

    sga_in1 = empty_geo_array(SparseArrayDOK{Float32,Int32})
    read_geotiff_header!(sga_in1, infilename1, 1)
    dataset_in1_data = GDAL.gdalopen(infilename1, GDAL.GA_ReadOnly)
    band_in1_data = GDAL.gdalgetrasterband(dataset_in1_data, 1)

    sga_in2 = empty_geo_array(SparseArrayDOK{Float32,Int32})
    read_geotiff_header!(sga_in2, infilename2, 1)
    dataset_in2_data = GDAL.gdalopen(infilename2, GDAL.GA_ReadOnly)
    band_in2_data = GDAL.gdalgetrasterband(dataset_in2_data, 1)

    if (size(sga_in1)[1] != size(sga_in1)[1]) 
      # error: different sizes of x dimension in the two input files
    end

    driver = GDAL.gdalgetdriverbyname("GTiff")
    opts = ["COMPRESS=DEFLATE", "BIGTIFF=YES"]
    dataset_out = GDAL.gdalcreate(driver, outfilename, size(sga_in1)[1], size(sga_in1)[2], 1, GDAL.GDT_Float32, opts)
    band_out_data = GDAL.gdalgetrasterband(dataset_out, 1)

    GDAL.gdalsetrasternodatavalue(band_out_data, no_data_value(sga_in1))
    GDAL.gdalsetprojection(dataset_out, GeoFormatTypes.val(sga_in1.crs))
    GDAL.gdalsetgeotransform(dataset_out, GeoArrays.affine_to_geotransform(sga_in1.f))
    #GDAL.gdalgettransformerdstgeotransform

    r_tiles = size(sga_in1)[2] ÷ 1
    remaining_r = size(sga_in1)[2] % 1
    scanline1 = fill(0.0f0, size(sga_in1)[1])
    scanline2 = fill(0.0f0, size(sga_in1)[1])
    outline = fill(0.0f0, size(sga_in1)[1])

    print("processesing progress: 0 ")
    p = 0

    for r in 1:(r_tiles)
        GDAL.gdalrasterio(band_in1_data, GDAL.GF_Read, 0, (r - 1), size(sga_in1)[1], 1, scanline1, size(sga_in1)[1], 1, GDAL.GDT_Float32, 0, 0)
        GDAL.gdalrasterio(band_in2_data, GDAL.GF_Read, 0, (r - 1), size(sga_in2)[1], 1, scanline2, size(sga_in2)[1], 1, GDAL.GDT_Float32, 0, 0)

        for i in 1:size(scanline1, 1)
            # f should also take the SGAs in order to handle no data 
            outline[i] = f(scanline1[i], scanline2[i], sga_in1, sga_in2)
        end
        GDAL.gdalrasterio(band_out_data, GDAL.GF_Write, 0, (r - 1), size(sga_in1)[1], 1, outline, size(sga_in1)[1], 1, GDAL.GDT_Float32, 0, 0)
        if ((r * 100 ÷ size(sga_in1)[2]) ÷ 10) > p
            p = ((r * 100 ÷ size(sga_in2)[2]) ÷ 10)
            print("$(p*10) ")
        end
    end

    println()
    GDAL.gdalclose(dataset_in1_data)
    GDAL.gdalclose(dataset_in2_data)
    GDAL.gdalclose(dataset_out)
end

"""
        function geotiff_transform(infilename1::String, outfilename::String, f::Function)

Applies a function pixelwise to a geotiff file and saves the result in a new geortiff file.

# Arguments
- `infilename1::String` : The path to the input geotiff file.
- `outfilename::String` : The path to the output geotiff file.
- `f::Function` : A function that will be applied pixelwise. Function definition must match the signature: <br> `f(value1::Float32, sga::SparseGeoArray, r::Int, i::Int)`
  where `value1` is the pixel value from the input raster, and `sga` is the corresponding SparseGeoArray object. `r` represents the row number and `i` represents the column number of the pixel in the raster.
  <br>**Note:** _The SparseGeoArray will be created from the input file_

# Example
```julia
input_path = "path/to/input.tif"
output_path = "path/to/output.tif"
square = (x, sga, r, i) -> x * x # Squares the pixel value
geotiff_transform(input_path, output_path, square)
```
"""
function geotiff_transform(infilename1::String, outfilename::String, f::Function)

    sga_in1 = empty_geo_array(SparseArrayDOK{Float32,Int32})
    read_geotiff_header!(sga_in1, infilename1, 1)
    dataset_in1_data = GDAL.gdalopen(infilename1, GDAL.GA_ReadOnly)
    band_in1_data = GDAL.gdalgetrasterband(dataset_in1_data, 1)

    driver = GDAL.gdalgetdriverbyname("GTiff")
    opts = ["COMPRESS=DEFLATE", "BIGTIFF=YES"]
    dataset_out = GDAL.gdalcreate(driver, outfilename, size(sga_in1)[1], size(sga_in1)[2], 1, GDAL.GDT_Float32, opts)
    band_out_data = GDAL.gdalgetrasterband(dataset_out, 1)

    GDAL.gdalsetrasternodatavalue(band_out_data, no_data_value(sga_in1))
    GDAL.gdalsetprojection(dataset_out, GeoFormatTypes.val(sga_in1.crs))
    GDAL.gdalsetgeotransform(dataset_out, GeoArrays.affine_to_geotransform(sga_in1.f))

    r_tiles = size(sga_in1)[2] ÷ 1
    remaining_r = size(sga_in1)[2] % 1
    scanline1 = fill(0.0f0, size(sga_in1)[1])
    outline = fill(0.0f0, size(sga_in1)[1])

    print("processesing progress: 0 ")
    p = 0

    for r in 1:(r_tiles)
        GDAL.gdalrasterio(band_in1_data, GDAL.GF_Read, 0, (r - 1), size(sga_in1)[1], 1, scanline1, size(sga_in1)[1], 1, GDAL.GDT_Float32, 0, 0)

        # if we change the number of lines per read ...
        # global_x =

        for i in 1:size(scanline1, 1)
            outline[i] = f(scanline1[i], sga_in1, r, i)
        end

        GDAL.gdalrasterio(band_out_data, GDAL.GF_Write, 0, (r - 1), size(sga_in1)[1], 1, outline, size(sga_in1)[1], 1, GDAL.GDT_Float32, 0, 0)
        if ((r * 100 ÷ size(sga_in1)[2]) ÷ 10) > p
            p = ((r * 100 ÷ size(sga_in1)[2]) ÷ 10)
            print("$(p*10) ")
        end
    end

    println()
    GDAL.gdalclose(dataset_in1_data)
    GDAL.gdalclose(dataset_out)
end

"""
        function geotiff_collect(maskfilename::String, infilenames::Array{String}, f::Function)

Applies a function pixelwise to one ore multiple geotiff's (`infilenames`) and saves the result in a new geotiff file. The function is applied only to the pixels that are not
masked by the mask geotiff (`maskfilename`). The result is saved in a new geotiff file.

# Arguments
- `maskfilename::String` : The path to the mask geotiff file.
- `infilenames::Array{String}` : An array of paths to the input geotiff files.
- `f::Function` : A function that will be applied pixelwise. Function definition must match the signature: <br> `f(mask_value::Float32, values::Array{Float32}, sga_mask::SparseGeoArray, sga_ins::Array{SparseGeoArray})`
  where `mask_value` is the pixel value from the mask raster, `values` is an array of pixel values from the input rasters, and `sga_mask` and `sga_ins` are the corresponding SparseGeoArray objects.
  <br>**Note:** _The SparseGeoArrays will be created from the input files_
"""
function geotiff_collect(maskfilename::String, infilenames::Array{String}, f::Function)

    sga_mask = empty_geo_array(SparseArrayDOK{Float32,Int32})
    read_geotiff_header!(sga_mask, maskfilename, 1)
    dataset_mask_data = GDAL.gdalopen(maskfilename, GDAL.GA_ReadOnly)
    band_mask_data = GDAL.gdalgetrasterband(dataset_mask_data, 1)

    sga_ins = Array{SparseArrayDOK{Float32,Int32}}(undef, size(infilenames, 1))
    for i in 1:size(infilenames, 1)
        sga_ins[i] = SparseArrayDOK{Float32,Int32}()
        read_geotiff_header!(sga_ins[i], infilenames[i], 1)
    end

    datasets_indata = map(fn -> GDAL.gdalopen(fn, GDAL.GA_ReadOnly), infilenames)
    bands_indata = map(ds -> GDAL.gdalgetrasterband(ds, 1), datasets_indata)
    #bands_indata = map(fn -> GDAL.gdalgetrasterband(GDAL.gdalopen(fn, GDAL.GA_ReadOnly),1),infilenames)

    r_tiles = size(sga_mask)[2] ÷ 1
    remaining_r = size(sga_mask)[2] % 1
    scanline_mask = fill(0.0f0, size(sga_mask)[1])
    scanlines_inp = fill(fill(0.0f0, size(sga_mask)[1]), size(infilenames, 1))
    vals = fill(0.0f0, size(infilenames, 1))

    print("processesing progress: 0 ")
    p = 0

    for r in 1:(r_tiles)
        GDAL.gdalrasterio(band_mask_data, GDAL.GF_Read, 0, (r - 1), size(sga_mask)[1], 1, scanline_mask, size(sga_mask)[1], 1, GDAL.GDT_Float32, 0, 0)

        for i in 1:size(infilenames, 1)
            GDAL.gdalrasterio(bands_indata[i], GDAL.GF_Read, 0, (r - 1), size(sga_mask)[1], 1, scanlines_inp[i], size(sga_mask)[1], 1, GDAL.GDT_Float32, 0, 0)
        end

        for i in 1:size(scanline_mask, 1)
            for j in 1:size(infilenames, 1)
                vals[j] = scanlines_inp[j][i]
            end

            f(scanline_mask[i], vals, sga_mask, sga_ins)
        end

        if ((r * 100 ÷ size(sga_mask)[2]) ÷ 10) > p
            p = ((r * 100 ÷ size(sga_mask)[2]) ÷ 10)
            print("$(p*10) ")
        end
    end

    println()

    GDAL.gdalclose(dataset_mask_data)
    for i in 1:size(infilenames, 1)
        GDAL.gdalclose(datasets_indata[i])
    end
end
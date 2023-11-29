include("../../../lib/diva_library_julia/dev/jdiva_lib.jl")
using .jdiva
using DataFrames
using CSV
using Statistics

df = DataFrame(CSV.File("Metadataset.csv"))
df = select(df, "Longitude", "Latitude")
df = unique(df)

function createMaskDataset(df, filename_in, filename_out, radius, f = identity) 
  datafile = SparseGeoArray{Float32, Int32}()
  read_geotiff_header(datafile,filename_in)
  datafile.nodatavalue=-9998

  print("processing row ")
  for (i,row) in enumerate(eachrow( df ))
    print("\e[2K") # clear whole line
    print("\e[1G") # move cursor to column 1
    print("processing row $i of $(size(df,1))")
    partial_read_around(datafile, (row.Longitude, row.Latitude), radius, 500, f)
  end
  save_geotiff_data_complete(datafile,filename_out)
end

function createDataset(df, filename_in, filename_out, radius, f = identity) 
  datafile = SparseGeoArray{Float32, Int32}()
  read_geotiff_header(datafile,filename_in)

  print("processing row ")
  for (i,row) in enumerate(eachrow( df ))
    print("\e[2K") # clear whole line
    print("\e[1G") # move cursor to column 1
    print("processing row $i of $(size(df,1))")
    partial_read_around(datafile, (row.Longitude, row.Latitude), radius, 500, f)
  end
  println()
  save_geotiff_data_complete(datafile,filename_out,1000)
end

#createMaskDataset(df,"../../../data/example_Global/tif/Global_ghs_pop_coastal_masked.tif","mask_25km_around_study_sites.tif",25, x -> 1.0)
#createMaskDataset(df,"../../../data/example_Global/tif/Global_ghs_pop_coastal_masked.tif","mask_50km_around_study_sites.tif",50, x -> 1.0)
#createMaskDataset(df,"../../../data/example_Global/tif/Global_ghs_pop_coastal_masked.tif","mask_75km_around_study_sites.tif",75, x -> 1.0)

#createDataset(df,"../../../data/example_Global/tif/Global_ghs_pop_coastal_masked.tif","population_25km_around_study_sites.tif",25)
#createDataset(df,"../../../data/example_Global/tif/Global_ghs_pop_coastal_masked.tif","population_50km_around_study_sites.tif",50)
#createDataset(df,"../../../data/example_Global/tif/Global_ghs_pop_coastal_masked.tif","population_75km_around_study_sites.tif",75)

createDataset(df,"../../../data/global_saltmarshes/WCMC027_Saltmarsh_v6_1/01_Data/WCMC027_Saltmarshes_Py_v6_1.tif","saltmarshes_25km_around_study_sites.tif",25)
createDataset(df,"../../../data/global_saltmarshes/WCMC027_Saltmarsh_v6_1/01_Data/WCMC027_Saltmarshes_Py_v6_1.tif","saltmarshes_50km_around_study_sites.tif",50)
createDataset(df,"../../../data/global_saltmarshes/WCMC027_Saltmarsh_v6_1/01_Data/WCMC027_Saltmarshes_Py_v6_1.tif","saltmarshes_75km_around_study_sites.tif",75)

createDataset(df,"../../../data/global_mangroves/gmw_v3_2020/tif/gmw_v3_2020.tif","mangroves_25km_around_study_sites.tif",25)
createDataset(df,"../../../data/global_mangroves/gmw_v3_2020/tif/gmw_v3_2020.tif","mangroves_50km_around_study_sites.tif",50)
createDataset(df,"../../../data/global_mangroves/gmw_v3_2020/tif/gmw_v3_2020.tif","mangroves_75km_around_study_sites.tif",75)

createDataset(df,"../../../data/global_tidal_flats/tif/tidalflats.tif","tidalflats_25km_around_study_sites.tif",25)
createDataset(df,"../../../data/global_tidal_flats/tif/tidalflats.tif","tidalflats_50km_around_study_sites.tif",50)
createDataset(df,"../../../data/global_tidal_flats/tif/tidalflats.tif","tidalflats_75km_around_study_sites.tif",75)

createDataset(df,"../../../data/example_Global/tif/WCMC008_CoralReef2018_Py_v4_1.tif","coralreefs_25km_around_study_sites.tif",25)
createDataset(df,"../../../data/example_Global/tif/WCMC008_CoralReef2018_Py_v4_1.tif","coralreefs_50km_around_study_sites.tif",50)
createDataset(df,"../../../data/example_Global/tif/WCMC008_CoralReef2018_Py_v4_1.tif","coralreefs_75km_around_study_sites.tif",75)


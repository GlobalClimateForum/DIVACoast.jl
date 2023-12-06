#include("../../../../../lib/diva_library_julia/dev/jdiva_lib.jl")
include("../../../dev/jdiva_lib.jl")
using .jdiva
using DataFrames
using CSV
using Statistics

df = DataFrame(CSV.File("Metadataset.csv"))
df = select(df, "Longitude", "Latitude")
df = unique(df)
#delete!(df, collect(10:size(df,1)))
CSV.write("study_sites.csv",df)


function attachData(df, filename, columnname_prefix, f = (s,x,y) -> s[x,y]) 
  df[!, :colname] .= false
  df[!, :colname25] .= 0.0
  df[!, :colname50] .= 0.0
  df[!, :colname75] .= 0.0

  datafile = SparseGeoArray{Float32, Int32}()
  read_geotiff_header!(datafile,filename)

  print("reading " * columnname_prefix * " data: processing row")
  for (i,row) in enumerate(eachrow( df ))
    print("\e[2K") # clear whole line
    print("\e[1G") # move cursor to column 1
    print("reading " * columnname_prefix * " data: processing row $i of $(size(df,1))")
    partial_read_around!(datafile, (row.Longitude, row.Latitude), 75)
  end
  println()

  print("calculating  " * columnname_prefix * ": processing row")
  for (i,row) in enumerate(eachrow( df ))
    print("\e[2K") # clear whole line
    print("\e[1G") # move cursor to column 1
    print("calculating  " * columnname_prefix * ": processing row $i of $(size(df,1))")

    row.colname = datafile[indices(datafile, row.Longitude, row.Latitude)] != datafile.nodatavalue
    row.colname25 = sga_summarize_within(datafile, (row.Longitude, row.Latitude), 25, sum, f)
    row.colname50 = sga_summarize_within(datafile, (row.Longitude, row.Latitude), 50, sum, f)
    row.colname75 = sga_summarize_within(datafile, (row.Longitude, row.Latitude), 75, sum, f)
  end
  println()

  rename!(df,:colname => "is_" * columnname_prefix)
  rename!(df,:colname25 => columnname_prefix * "_in_25_km_radius")
  rename!(df,:colname50 => columnname_prefix * "_in_50_km_radius")
  rename!(df,:colname75 => columnname_prefix * "_in_75_km_radius")
end

#data_path = "../../../../../data"

#attachData(df, data_path * "/population/global_human_settlement_layer/GHS_POP_E2020_GLOBE_R2023A_4326_3ss_V1_0_resampled.tif", "population")
#CSV.write("study_sites_population.csv",df)
#attachData(df, data_path * "/global_saltmarshes/WCMC027_Saltmarsh_v6_1/01_Data/WCMC027_Saltmarshes_Py_v6_1.tif", "saltmarsh", (s,x,y) -> area(s,x,y))
#CSV.write("study_sites_population_saltmarshes.csv",df)
#attachData(df, data_path * "/global_mangroves/gmw_v3_2020/tif/gmw_v3_2020.tif", "mangrove", (s,x,y) -> area(s,x,y))
#CSV.write("study_sites_population_saltmarshes_mangroves.csv",df)
#attachData(df, data_path * "/global_tidal_flats/tif/tidalflats.tif", "tidalflat", (s,x,y) -> area(s,x,y))
#CSV.write("study_sites_population_saltmarshes_mangroves_tidalflats.csv",df)
#attachData(df, data_path * "/global_coral_reefs/14_001_WCMC008_CoralReefs2018_v4_1/01_Data/WCMC008_CoralReef2018_Py_v4_1.tif", "coralreef", (s,x,y) -> area(s,x,y))
#CSV.write("study_sites_population_saltmarshes_mangroves_tidalflats_coralreefs.csv",df)

sga_GDP_capita = SparseGeoArray{Float32, Int32}("/home/honsel/Projects/sebastianoData/GDP_per_capita_PPP_2015_v2.tif")
for (i,row) in enumerate(eachrow(df))
  println(get_closest_value(sga_GDP_capita, (row.Longitude, row.Latitude))
end

include("./dev/jdiva_lib.jl")
using .jdiva

# read an geotiff file into sga
sga = SparseGeoArray{Float32,Int32}("./testdata/UKIRL/UKIRL_meritDEM.tif")
sgb = SparseGeoArray{Float32,Int32}("./testdata/UKIRL/UKIRL_GHS_POP_E2020_GLOBE_R2023A_4326_3ss_V1_0.tif")


function extreme_populated_elevation(sgr_elevation, sgr_population, comparator)
#  ee = -Inf
  extr_populated_elevation = NaN
  extr_populated_elevation_ind = (-1,-1)
  for (coordinates, elevation) in sgr_elevation.data
#    println("$coordinates, $elevation, $extr_populated_elevation -- $(comparator(elevation,extr_populated_elevation)) or $(extr_populated_elevation==NaN)")
    if ((comparator(elevation,extr_populated_elevation)) || (extr_populated_elevation===NaN)) && sgr_population[coordinates]!=sgr_population.nodatavalue
      extr_populated_elevation=elevation
      extr_populated_elevation_ind=coordinates
    end
  end
  return(extr_populated_elevation,extr_populated_elevation_ind)
end

#@time highest_elevation1(sga)
#@time highest_elevation2(sga)
#@time highest_elevation3(sga)
#@time highest_elevation4(sga) 

highest_populated = extreme_populated_elevation(sga,sgb,>)
lowest_populated = extreme_populated_elevation(sga,sgb,<)

println(highest_populated)
println(coords(sga,highest_populated[2]))
println(lowest_populated)
println(coords(sga,lowest_populated[2]))

sgc = SparseGeoArray{Float32,Int32}("./testdata/UKIRL/UKIRL_gpw_v4_population_count_rev11_2020_30_sec.tif")

highest_populated = extreme_populated_elevation(sga,sgc,>)
lowest_populated = extreme_populated_elevation(sga,sgc,<)

println(highest_populated)
println(coords(sga,highest_populated[2]))
println(lowest_populated)
println(coords(sga,lowest_populated[2]))

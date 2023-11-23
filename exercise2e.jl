include("./dev/jdiva_lib.jl")
using .jdiva

# read an geotiff file into sga
#sga = SparseGeoArray{Float32,Int32}("./testdata/UKIRL/UKIRL_merit_coastplain_elecz_12m.tif")

elevations :: Array{Float32} = [0,0.5,1.0,1.5,2.0,2.5,3.0,3.5,4.0,4.5,5.0,5.5,6.0,6.5,7.0,7.5,8.0,8.5,9.0,9.5,10.0,10.5,11.0,11.5,12.0]
areas      :: Array{Float32} = zeros(size(elevations,1))

function ind(el, min, step) 
  d = el - min
  if d<0 return 1 end
  if floor(d/step)<1 return 2 end
  convert(Int16, floor(d/step)+2)
end

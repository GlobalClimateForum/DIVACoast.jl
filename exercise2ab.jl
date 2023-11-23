include("./dev/jdiva_lib.jl")
using .jdiva

# read an geotiff file into sga
sga = SparseGeoArray{Float32,Int32}("./testdata/UKIRL/UKIRL_meritDEM.tif")

function highest_elevation1(sga)
  he = -Inf
  hc = (0,0)
  for x in 1:sga.xsize
    for y in 1:sga.ysize
      if (sga[x,y]>he)
        he=sga[x,y]
        hc=(x,y)
      end
    end
  end
  return(he,hc)
end

function highest_elevation2(sga)
  he = -Inf
  hc = (0,0)
  for (coordinates, elevation) in sga.data
    if (elevation>he)
      he=elevation
      hc=coordinates
    end
  end
  return(he,hc)
end

highest_elevation3(sga) = sort(collect(sga.data), by=x->x[2])[end]

highest_elevation4(sga) = findmax(sga.data)

function extreme_elevation(sga, f)
#  ee = -Inf
  ee = collect(sga.data)[begin][2]
  ec = (-1,-1)
  for (coordinates, elevation) in sga.data
    if (f(elevation,ee))
      ee=elevation
      ec=coordinates
    end
  end
  return(ee,ec)
end

println(highest_elevation1(sga))
println(highest_elevation2(sga))
println(highest_elevation3(sga))
println(highest_elevation4(sga))

println(coords(sga,highest_elevation2(sga)[2]))

@time highest_elevation1(sga)
@time highest_elevation2(sga)
@time highest_elevation3(sga)
@time highest_elevation4(sga) 

println(extreme_elevation(sga,>))
println(extreme_elevation(sga,<))


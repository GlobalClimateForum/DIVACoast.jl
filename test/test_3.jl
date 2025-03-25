include("../src/DIVACoast.jl")
using .DIVACoast

println("Radius of the Earth is: $(DIVACoast.earth_radius_km)km")
println("Circumference of the Earth is: $(DIVACoast.earth_circumference_km)km")

using GDAL 

println("This script uses GDAL.")


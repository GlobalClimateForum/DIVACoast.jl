include("../logger/jdiva_logger.jl")

using Logging
using Dates
using StructArrays

include("../jdiva_lib.jl")
using Main.ExtendedLogging

io = open(".jdiva_log", "w+")
simple_logger = Logging.SimpleLogger(io)
logger = Main.ExtendedLogging.ExtendedLogger(simple_logger,io,now())

using Main.jdiva.HypsometricProfiles

mutable struct area_data 
  area :: Float32
end

mutable struct x1_data 
  area_lu1 :: Float32
  area_lu2 :: Float32
  area_lu3 :: Float32
  area_lu4 :: Float32
end

mutable struct x2_data 
  pop     :: Float32
  assets0 :: Float32
  assets1 :: Float32
  assets2 :: Float32
end

StructArray{x1_data}((area_lu1=[1,1,2,2,2],area_lu2=[0,0,0,0,0],area_lu3=[10,10,20,20,10],area_lu4=[5,4,3,2,1]))

hp = Main.jdiva.HypsometricProfiles.HypsometricProfileFixedStrarray(1, 0, [1f0, 2f0, 3f0, 4f0, 5f0], [1f0, 1f0, 1f0, 1f0, 1f0], StructArray{x1_data}((area_lu1=[1,1,2,2,2],area_lu2=[0,0,0,0,0],area_lu3=[10,10,20,20,10],area_lu4=[5,4,3,2,1])), StructArray{x2_data}((pop=[1,1,2,2,2],assets0=[0,0,0,0,0],assets1=[10,10,20,20,10],assets2=[5,4,3,2,1])), logger)

println(Main.jdiva.HypsometricProfiles.exposure(hp,-1))
println(Main.jdiva.HypsometricProfiles.exposure(hp,2))
println(Main.jdiva.HypsometricProfiles.exposure(hp,7))
println(Main.jdiva.HypsometricProfiles.exposure(hp,4.9))

println()
println("sed(hp,[0.9,1.2]):")

sed(hp,[0.9,1.2])
println(hp)

println(Main.jdiva.HypsometricProfiles.exposure(hp,-1))
println(Main.jdiva.HypsometricProfiles.exposure(hp,2))
println(Main.jdiva.HypsometricProfiles.exposure(hp,7))
println(Main.jdiva.HypsometricProfiles.exposure(hp,4.9))


println()
println("sed_above(hp,2.5,[0.9,1.2]):")

sed_above(hp,2.5,[0.9,1.2])
println(hp)

println(Main.jdiva.HypsometricProfiles.exposure(hp,-1))
println(Main.jdiva.HypsometricProfiles.exposure(hp,2))
println(Main.jdiva.HypsometricProfiles.exposure(hp,7))
println(Main.jdiva.HypsometricProfiles.exposure(hp,4.9))

println()
println("sed_below(hp,2.5,[0.5,1.5]):")

sed_below(hp,2.5,[0.5,1.5])
println(hp)

println(Main.jdiva.HypsometricProfiles.exposure(hp,-1))
println(Main.jdiva.HypsometricProfiles.exposure(hp,2))
println(Main.jdiva.HypsometricProfiles.exposure(hp,7))
println(Main.jdiva.HypsometricProfiles.exposure(hp,4.9))

#=
println()
println("remove_below(hp,3.8):")

println(remove_below(hp,3.8))
println(hp)

println(Main.jdiva.HypsometricProfiles.exposure(hp,-1))
println(Main.jdiva.HypsometricProfiles.exposure(hp,2))
println(Main.jdiva.HypsometricProfiles.exposure(hp,7))
println(Main.jdiva.HypsometricProfiles.exposure(hp,4.9))

println()
println("remove_below(hp,10):")

println(remove_below(hp,10))
println(hp)

println(Main.jdiva.HypsometricProfiles.exposure(hp,-1))
println(Main.jdiva.HypsometricProfiles.exposure(hp,2))
println(Main.jdiva.HypsometricProfiles.exposure(hp,7))
println(Main.jdiva.HypsometricProfiles.exposure(hp,4.9))

println()
println("add_above(hp,0,10,100)")

add_above(hp,0,10,100)
println(hp)

println(Main.jdiva.HypsometricProfiles.exposure(hp,-1))
println(Main.jdiva.HypsometricProfiles.exposure(hp,2))
println(Main.jdiva.HypsometricProfiles.exposure(hp,7))
println(Main.jdiva.HypsometricProfiles.exposure(hp,4.9))

println()
println("add_between(hp,2,3,10,100)")

add_between(hp,2,3,10,100)
println(hp)

println(Main.jdiva.HypsometricProfiles.exposure(hp,-1))
println(Main.jdiva.HypsometricProfiles.exposure(hp,2))
println(Main.jdiva.HypsometricProfiles.exposure(hp,7))
println(Main.jdiva.HypsometricProfiles.exposure(hp,4.9))
=#

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

hp = Main.jdiva.HypsometricProfiles.HypsometricProfileFixedStrarray(1f0, [-1f0, 0f0, 1f0, 2f0, 3f0, 4f0, 5f0], [0f0, 1f0, 1f0, 1f0, 1f0, 1f0, 1f0],
                                                                    StructArray{NamedTuple{(:area_lu1, :area_lu2, :area_lu3, :area_lu4), NTuple{4, Float32}}}((area_lu1=[0,1,1,1,2,2,2],area_lu2=[0,0,0,0,0,0,0],area_lu3=[0,10,10,10,20,20,10],area_lu4=[0,6,5,4,3,2,1])),
                                                                    StructArray{NamedTuple{(:pop, :assets0, :assets1, :assets2), NTuple{4, Float32}}}((pop=[0f0,1f0,1f0,1f0,2f0,2f0,2f0],assets0=[0f0,0f0,0f0,0f0,0f0,0f0,0f0],assets1=[0f0,10f0,10f0,10f0,20f0,20f0,10f0],assets2=[0f0,6f0,5f0,4f0,3f0,2f0,1f0])), logger)


#println(hp)
println(" -2 $(Main.jdiva.HypsometricProfiles.exposure(hp,-2.0f0))")
println("2.0 $(Main.jdiva.HypsometricProfiles.exposure(hp,2.0f0))")
println("3.5 $(Main.jdiva.HypsometricProfiles.exposure(hp,3.5))")
println("7.0 $(Main.jdiva.HypsometricProfiles.exposure(hp,7.0f0))")
println("4.9 $(Main.jdiva.HypsometricProfiles.exposure(hp,4.9))")

println("sed(hp,[0.9f0,1.2f0,1.5f0,0.2f0]):")
sed(hp,[0.9f0,1.2f0,1.5f0,0.2f0])

println(" -2 $(Main.jdiva.HypsometricProfiles.exposure(hp,-2.0f0))")
println("2.0 $(Main.jdiva.HypsometricProfiles.exposure(hp,2.0f0))")
println("3.5 $(Main.jdiva.HypsometricProfiles.exposure(hp,3.5))")
println("7.0 $(Main.jdiva.HypsometricProfiles.exposure(hp,7.0f0))")
println("4.9 $(Main.jdiva.HypsometricProfiles.exposure(hp,4.9))")

println()
println("sed_above(hp,[0.9f0,1.2f0,1.5f0,0.2f0],2.5):")
sed_above(hp,[0.9f0,1.2f0,1.5f0,0.2f0],3.5)

println(" -2 $(Main.jdiva.HypsometricProfiles.exposure(hp,-2.0f0))")
println("2.0 $(Main.jdiva.HypsometricProfiles.exposure(hp,2.0f0))")
println("3.5 $(Main.jdiva.HypsometricProfiles.exposure(hp,3.5))")
println("7.0 $(Main.jdiva.HypsometricProfiles.exposure(hp,7.0f0))")
println("4.9 $(Main.jdiva.HypsometricProfiles.exposure(hp,4.9))")

println()
println("sed_below(hp,[0.5,0.5,0.5,0.5],3.5):")
sed_below(hp,[0.5f0,0.5f0,0.5f0,0.5f0],3.5)
#println(hp.cummulativeDynamicExposure.assets2)

println(" -2 $(Main.jdiva.HypsometricProfiles.exposure(hp,-2.0f0))")
println("2.0 $(Main.jdiva.HypsometricProfiles.exposure(hp,2.0f0))")
println("3.5 $(Main.jdiva.HypsometricProfiles.exposure(hp,3.5))")
println("7.0 $(Main.jdiva.HypsometricProfiles.exposure(hp,7.0f0))")
println("4.9 $(Main.jdiva.HypsometricProfiles.exposure(hp,4.9))")


println()
println("remove_below(hp,3.8):")
println(remove_below(hp,3.8))

println(" -2 $(Main.jdiva.HypsometricProfiles.exposure(hp,-2.0f0))")
println("2.0 $(Main.jdiva.HypsometricProfiles.exposure(hp,2.0f0))")
println("3.5 $(Main.jdiva.HypsometricProfiles.exposure(hp,3.5))")
println("7.0 $(Main.jdiva.HypsometricProfiles.exposure(hp,7.0f0))")
println("4.9 $(Main.jdiva.HypsometricProfiles.exposure(hp,4.9))")

println()
println("remove_below(hp,10):")
println(remove_below(hp,10))

println(" -2 $(Main.jdiva.HypsometricProfiles.exposure(hp,-2.0f0))")
println("2.0 $(Main.jdiva.HypsometricProfiles.exposure(hp,2.0f0))")
println("3.5 $(Main.jdiva.HypsometricProfiles.exposure(hp,3.5))")
println("7.0 $(Main.jdiva.HypsometricProfiles.exposure(hp,7.0f0))")
println("4.9 $(Main.jdiva.HypsometricProfiles.exposure(hp,4.9))")

println()
println("add_above(hp,2,[10f0,20f0,30f0,40f0])")
add_above(hp,2,[10f0,20f0,30f0,40f0])

println(" -2 $(Main.jdiva.HypsometricProfiles.exposure(hp,-2.0f0))")
println("2.0 $(Main.jdiva.HypsometricProfiles.exposure(hp,2.0f0))")
println("3.5 $(Main.jdiva.HypsometricProfiles.exposure(hp,3.5))")
println("7.0 $(Main.jdiva.HypsometricProfiles.exposure(hp,7.0f0))")
println("4.9 $(Main.jdiva.HypsometricProfiles.exposure(hp,4.9))")


println()
println("add_between(hp,2,3,[100f0,100f0,100f0,100f0]")
add_between(hp,2f0,3f0,[100f0,100f0,100f0,100f0])

println(" -2 $(Main.jdiva.HypsometricProfiles.exposure(hp,-2.0f0))")
println("2.0 $(Main.jdiva.HypsometricProfiles.exposure(hp,2.0f0))")
println("3.5 $(Main.jdiva.HypsometricProfiles.exposure(hp,3.5))")
println("7.0 $(Main.jdiva.HypsometricProfiles.exposure(hp,7.0f0))")
println("4.9 $(Main.jdiva.HypsometricProfiles.exposure(hp,4.9))")

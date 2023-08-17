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

hp = Main.jdiva.HypsometricProfiles.HypsometricProfileFlex(1.0f0, [-1f0, 0f0, 1f0, 2f0, 3f0, 4f0, 5f0], [0f0, 1f0, 1f0, 2f0, 3f0, 2f0, 1f0], 
StructArray{NamedTuple{(:area_lu1, :area_lu2, :area_lu3, :area_lu4), NTuple{4, Float32}}}((area_lu1=[0f0,1f0,1f0,1f0,2f0,2f0,2f0],area_lu2=[0f0,0f0,0f0,0f0,0f0,0f0,0f0],area_lu3=[0f0,10f0,10f0,10f0,20f0,20f0,10f0],area_lu4=[0f0,6f0,5f0,4f0,3f0,2f0,1f0])),
StructArray{NamedTuple{(:pop, :assets0, :assets1, :assets2), NTuple{4, Float32}}}((pop=[0f0,1f0,1f0,1f0,2f0,2f0,2f0],assets0=[0f0,0f0,0f0,0f0,0f0,0f0,0f0],assets1=[0f0,10f0,10f0,10f0,20f0,20f0,10f0],assets2=[0f0,6f0,5f0,4f0,3f0,2f0,1f0])),
logger)

println("orig:")
println(hp)

println(" -2 $(Main.jdiva.HypsometricProfiles.exposure(hp,-2.0f0))")
println("2.0 $(Main.jdiva.HypsometricProfiles.exposure(hp,2.0f0))")
println("3.5 $(Main.jdiva.HypsometricProfiles.exposure(hp,3.5))")
println("7.0 $(Main.jdiva.HypsometricProfiles.exposure(hp,7.0f0))")
println("4.9 $(Main.jdiva.HypsometricProfiles.exposure(hp,4.9))")

println(" -2 $(Main.jdiva.HypsometricProfiles.exposure_named(hp,-2.0f0))")
println("2.0 $(Main.jdiva.HypsometricProfiles.exposure_named(hp,2.0f0))")
println("3.5 $(Main.jdiva.HypsometricProfiles.exposure_named(hp,3.5))")
println("7.0 $(Main.jdiva.HypsometricProfiles.exposure_named(hp,7.0f0))")
println("4.9 $(Main.jdiva.HypsometricProfiles.exposure_named(hp,4.9))")

println()
println("sed(hp,[0.9,1.2,0.75,0.2]):")
sed(hp,[0.9,1.2,0.75,0.2])

println(" -2 $(Main.jdiva.HypsometricProfiles.exposure_named(hp,-2.0f0))")
println("2.0 $(Main.jdiva.HypsometricProfiles.exposure_named(hp,2.0f0))")
println("3.5 $(Main.jdiva.HypsometricProfiles.exposure_named(hp,3.5))")
println("7.0 $(Main.jdiva.HypsometricProfiles.exposure_named(hp,7.0f0))")
println("4.9 $(Main.jdiva.HypsometricProfiles.exposure_named(hp,4.9))")

println()
println("sed(hp,(pop = 0.9, assets1=4/3, assets2=5, assets0=1.2)):")
sed(hp,(pop = 0.9, assets1=4/3, assets2=5, assets0=1.2))

println(" -2 $(Main.jdiva.HypsometricProfiles.exposure_named(hp,-2.0f0))")
println("2.0 $(Main.jdiva.HypsometricProfiles.exposure_named(hp,2.0f0))")
println("3.5 $(Main.jdiva.HypsometricProfiles.exposure_named(hp,3.5))")
println("7.0 $(Main.jdiva.HypsometricProfiles.exposure_named(hp,7.0f0))")
println("4.9 $(Main.jdiva.HypsometricProfiles.exposure_named(hp,4.9))")


println()
println("sed_above(hp,2.5,[0.9,1.2,0.75,0.2]:")
sed_above(hp,2.5,[0.9,1.2,0.75,0.2])

println(" -2 $(Main.jdiva.HypsometricProfiles.exposure_named(hp,-2.0f0))")
println("2.0 $(Main.jdiva.HypsometricProfiles.exposure_named(hp,2.0f0))")
println("2.5 $(Main.jdiva.HypsometricProfiles.exposure_named(hp,2.5))")
println("3.5 $(Main.jdiva.HypsometricProfiles.exposure_named(hp,3.5))")
println("7.0 $(Main.jdiva.HypsometricProfiles.exposure_named(hp,7.0f0))")
println("4.9 $(Main.jdiva.HypsometricProfiles.exposure_named(hp,4.9))")

println()
println("sed_below(hp,3.5,(assets1=0.5, assets2=10, assets0=1.0, pop = 0.9)):")
sed_below(hp,3.5,(assets1=0.5, assets2=10, assets0=1.0, pop = 0.9))

println(" -2 $(Main.jdiva.HypsometricProfiles.exposure_named(hp,-2.0f0))")
println("2.0 $(Main.jdiva.HypsometricProfiles.exposure_named(hp,2.0f0))")
println("2.5 $(Main.jdiva.HypsometricProfiles.exposure_named(hp,2.5))")
println("3.5 $(Main.jdiva.HypsometricProfiles.exposure_named(hp,3.5))")
println("7.0 $(Main.jdiva.HypsometricProfiles.exposure_named(hp,7.0f0))")
println("4.9 $(Main.jdiva.HypsometricProfiles.exposure_named(hp,4.9))")


println()
println("remove_below_named(hp,3.8):")
println(Main.jdiva.HypsometricProfiles.remove_below_named(hp,3.8))

println(" -2 $(Main.jdiva.HypsometricProfiles.exposure_named(hp,-2.0f0))")
println("2.0 $(Main.jdiva.HypsometricProfiles.exposure_named(hp,2.0f0))")
println("2.5 $(Main.jdiva.HypsometricProfiles.exposure_named(hp,2.5))")
println("3.5 $(Main.jdiva.HypsometricProfiles.exposure_named(hp,3.5))")
println("7.0 $(Main.jdiva.HypsometricProfiles.exposure_named(hp,7.0f0))")
println("4.9 $(Main.jdiva.HypsometricProfiles.exposure_named(hp,4.9))")


println()
println("remove_below(hp,10):")
println(remove_below(hp,10))

println(" -2 $(Main.jdiva.HypsometricProfiles.exposure_named(hp,-2.0f0))")
println("2.0 $(Main.jdiva.HypsometricProfiles.exposure_named(hp,2.0f0))")
println("2.5 $(Main.jdiva.HypsometricProfiles.exposure_named(hp,2.5))")
println("3.5 $(Main.jdiva.HypsometricProfiles.exposure_named(hp,3.5))")
println("7.0 $(Main.jdiva.HypsometricProfiles.exposure_named(hp,7.0f0))")
println("4.9 $(Main.jdiva.HypsometricProfiles.exposure_named(hp,4.9))")


println()
println("add_above(hp,0,[100,0,10,50])")
add_above(hp,0,[100,0,10,50])

println(" -2 $(Main.jdiva.HypsometricProfiles.exposure_named(hp,-2.0f0))")
println("2.0 $(Main.jdiva.HypsometricProfiles.exposure_named(hp,2.0f0))")
println("2.5 $(Main.jdiva.HypsometricProfiles.exposure_named(hp,2.5))")
println("3.5 $(Main.jdiva.HypsometricProfiles.exposure_named(hp,3.5))")
println("7.0 $(Main.jdiva.HypsometricProfiles.exposure_named(hp,7.0f0))")
println("4.9 $(Main.jdiva.HypsometricProfiles.exposure_named(hp,4.9))")

println()
println("add_between(hp,2,3,[100,0,10,50])")
add_between(hp,2,3,[100,0,10,50])
println("added")

println(" -2 $(Main.jdiva.HypsometricProfiles.exposure_named(hp,-2.0f0))")
println("2.0 $(Main.jdiva.HypsometricProfiles.exposure_named(hp,2.0f0))")
println("2.5 $(Main.jdiva.HypsometricProfiles.exposure_named(hp,2.5))")
println("3.5 $(Main.jdiva.HypsometricProfiles.exposure_named(hp,3.5))")
println("7.0 $(Main.jdiva.HypsometricProfiles.exposure_named(hp,7.0f0))")
println("4.9 $(Main.jdiva.HypsometricProfiles.exposure_named(hp,4.9))")


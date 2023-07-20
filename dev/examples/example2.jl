include("../logger/jdiva_logger.jl")

using Logging
using Dates

include("../jdiva_lib.jl")
using Main.ExtendedLogging

io = open(".jdiva_log", "w+")
simple_logger = Logging.SimpleLogger(io)
logger = Main.ExtendedLogging.ExtendedLogger(simple_logger,io,now())

using Main.jdiva.HypsometricProfiles
hp = Main.jdiva.HypsometricProfiles.HypsometricProfileFixed(1, 0, [1, 2, 3, 4, 5], [1, 1, 1, 1, 1], [1, 1, 1, 1, 1], [1, 1, 1, 1, 1], logger)

println(hp)

println(Main.jdiva.HypsometricProfiles.exposure(hp,-1))
println(Main.jdiva.HypsometricProfiles.exposure(hp,2))
println(Main.jdiva.HypsometricProfiles.exposure(hp,7))
println(Main.jdiva.HypsometricProfiles.exposure(hp,4.9))

sed(hp,0.9,1.2)

println(hp)

println(Main.jdiva.HypsometricProfiles.exposure(hp,-1))
println(Main.jdiva.HypsometricProfiles.exposure(hp,2))
println(Main.jdiva.HypsometricProfiles.exposure(hp,7))
println(Main.jdiva.HypsometricProfiles.exposure(hp,4.9))

sed_above(hp,2.5,0.9,1.2)

println(hp)

println(Main.jdiva.HypsometricProfiles.exposure(hp,-1))
println(Main.jdiva.HypsometricProfiles.exposure(hp,2))
println(Main.jdiva.HypsometricProfiles.exposure(hp,7))
println(Main.jdiva.HypsometricProfiles.exposure(hp,4.9))

sed_below(hp,2.5,0.9,1.2)

println(hp)

println(Main.jdiva.HypsometricProfiles.exposure(hp,-1))
println(Main.jdiva.HypsometricProfiles.exposure(hp,2))
println(Main.jdiva.HypsometricProfiles.exposure(hp,7))
println(Main.jdiva.HypsometricProfiles.exposure(hp,4.9))

println(remove_below(hp,3.8))

println(hp)

println(Main.jdiva.HypsometricProfiles.exposure(hp,-1))
println(Main.jdiva.HypsometricProfiles.exposure(hp,2))
println(Main.jdiva.HypsometricProfiles.exposure(hp,7))
println(Main.jdiva.HypsometricProfiles.exposure(hp,4.9))

println(remove_below(hp,10))

println(hp)

println(Main.jdiva.HypsometricProfiles.exposure(hp,-1))
println(Main.jdiva.HypsometricProfiles.exposure(hp,2))
println(Main.jdiva.HypsometricProfiles.exposure(hp,7))
println(Main.jdiva.HypsometricProfiles.exposure(hp,4.9))

add_above(hp,0,10,100)

println(hp)

println(Main.jdiva.HypsometricProfiles.exposure(hp,-1))
println(Main.jdiva.HypsometricProfiles.exposure(hp,2))
println(Main.jdiva.HypsometricProfiles.exposure(hp,7))
println(Main.jdiva.HypsometricProfiles.exposure(hp,4.9))

println(remove_below(hp,10))

add_between(hp,2,3,10,100)

println(hp)

println(Main.jdiva.HypsometricProfiles.exposure(hp,-1))
println(Main.jdiva.HypsometricProfiles.exposure(hp,2))
println(Main.jdiva.HypsometricProfiles.exposure(hp,7))
println(Main.jdiva.HypsometricProfiles.exposure(hp,4.9))

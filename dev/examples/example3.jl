include("../logger/jdiva_logger.jl")

using Logging
using Dates

include("../jdiva_lib.jl")
using Main.ExtendedLogging

io = open(".jdiva_log", "w+")
simple_logger = Logging.SimpleLogger(io)
logger = Main.ExtendedLogging.ExtendedLogger(simple_logger,io,now())

using Main.jdiva.HypsometricProfiles

hp = Main.jdiva.HypsometricProfiles.HypsometricProfileFixedArray(1, [-1f0, 0f0, 1f0, 2f0, 3f0, 4f0, 5f0], [0f0, 1f0, 1f0, 2f0, 3f0, 2f0, 1f0], [0f0 1f0 1f0 1f0 1f0 1f0 1f0; 0f0 2f2 2f0 2f0 2f0 2f0 2f0], [0f0 1f0 1f0 1f0 1f0 1f0 1f0; 0f0 4f0 4f0 4f0 4f0 4f0 4f0], [], [], logger)


function test(hp)
  if (hp.minElevation < -100) 
    println("ALARM!")
  end
end


function test(n :: Int64)
  for i in 1:n
    global hp = Main.jdiva.HypsometricProfiles.HypsometricProfileFixedArray(1, [-1f0, 0f0, 1f0, 2f0, 3f0, 4f0, 5f0], [0f0, 1f0, 1f0, 2f0, 3f0, 2f0, 1f0], [0f0 1f0 1f0 1f0 1f0 1f0 1f0; 0f0 2f2 2f0 2f0 2f0 2f0 2f0], [0f0 1f0 1f0 1f0 1f0 1f0 1f0; 0f0 4f0 4f0 4f0 4f0 4f0 4f0], [], [], logger)
    test(hp)
  end
end

println()
println("orig:")
println(hp)

@time test(1)
@time test(100)
@time test(100000)


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

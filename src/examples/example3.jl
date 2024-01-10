include("../jdiva_lib.jl")

using StructArrays

using .jdiva



hp = HypsometricProfile(1.0f0, [-1f0, 0f0, 1f0, 2f0, 3f0, 4f0, 5f0], [0f0, 1f0, 1f0, 2f0, 3f0, 2f0, 1f0], 
[0f0 0f0 0f0 0f0; 1f0 0f0 10f0 6f0; 1f0 0f0 10f0 5f0; 2f0 0f0 20f0 4f0; 2f0 0f0 20f0 3f0; 2f0 0f0 20f0 2f0; 1f0 0f0 10f0 1f0;],
["area_lu1","area_lu2","area_lu3","area_lu4"], ["km^2","km^2","km^2","km^2"],
[0f0 0f0 0f0; 1000f0 10f0 6f0; 1000f0 10f0 5f0; 2000f0 20f0 4f0; 2000f0 20f0 3f0; 2000f0 20f0 2f0; 1000f0 10f0 1f0;],
["pop","assets1","assets2"], ["","EUR","USD"])

println("orig:")
println(hp)

println(" -2 $(exposure(hp,-2.0f0))")
println("2.0 $(exposure(hp,2.0f0))")
println("3.5 $(exposure(hp,3.5))")
println("7.0 $(exposure(hp,7.0f0))")
println("4.9 $(exposure(hp,4.9))")

println(" -2 $(exposure_named(hp,-2.0f0))")
println("2.0 $(exposure_named(hp,2.0f0))")
println("3.5 $(exposure_named(hp,3.5))")
println("7.0 $(exposure_named(hp,7.0f0))")
println("4.9 $(exposure_named(hp,4.9))")

println()
println("sed(hp,[0.9,1.2,0.75]):")
sed(hp,[0.9,1.2,0.75])

println(" -2 $(exposure_named(hp,-2.0f0))")
println("2.0 $(exposure_named(hp,2.0f0))")
println("3.5 $(exposure_named(hp,3.5))")
println("7.0 $(exposure_named(hp,7.0f0))")
println("4.9 $(exposure_named(hp,4.9))")

println()
println("sed(hp,(pop = 0.9, assets1=4/3, assets2=5)):")
sed(hp,(pop = 0.9, assets1=4/3, assets2=5))

println(" -2 $(exposure_named(hp,-2.0f0))")
println("2.0 $(exposure_named(hp,2.0f0))")
println("3.5 $(exposure_named(hp,3.5))")
println("7.0 $(exposure_named(hp,7.0f0))")
println("4.9 $(exposure_named(hp,4.9))")


println()
println("sed_above(hp,2.5,[0.9,1.2,0.75]:")
sed_above(hp,2.5,[0.9,1.2,0.75])

println(" -2 $(exposure_named(hp,-2.0f0))")
println("2.0 $(exposure_named(hp,2.0f0))")
println("3.5 $(exposure_named(hp,3.5))")
println("7.0 $(exposure_named(hp,7.0f0))")
println("4.9 $(exposure_named(hp,4.9))")

println()
println("sed_below(hp,3.5,(assets1=0.5, assets2=10, assets0=1.0)):")
sed_below(hp,3.5,(assets1=0.5, assets2=10, pop=1.0))

println(" -2 $(exposure_named(hp,-2.0f0))")
println("2.0 $(exposure_named(hp,2.0f0))")
println("3.5 $(exposure_named(hp,3.5))")
println("7.0 $(exposure_named(hp,7.0f0))")
println("4.9 $(exposure_named(hp,4.9))")


println()
println("remove_below_named(hp,3.8):")
println(remove_below_named(hp,3.8))

println(" -2 $(exposure_named(hp,-2.0f0))")
println("2.0 $(exposure_named(hp,2.0f0))")
println("3.5 $(exposure_named(hp,3.5))")
println("7.0 $(exposure_named(hp,7.0f0))")
println("4.9 $(exposure_named(hp,4.9))")


println()
println("remove_below(hp,10):")
println(remove_below(hp,10))

println(" -2 $(exposure_named(hp,-2.0f0))")
println("2.0 $(exposure_named(hp,2.0f0))")
println("3.5 $(exposure_named(hp,3.5))")
println("7.0 $(exposure_named(hp,7.0f0))")
println("4.9 $(exposure_named(hp,4.9))")


println()
println("add_above(hp,0,[100,0,10])")
add_above(hp,0,[100,0,10])

println(" -2 $(exposure_named(hp,-2.0f0))")
println("2.0 $(exposure_named(hp,2.0f0))")
println("3.5 $(exposure_named(hp,3.5))")
println("7.0 $(exposure_named(hp,7.0f0))")
println("4.9 $(exposure_named(hp,4.9))")

println()
println("add_between(hp,2,3,[100,0,10])")
add_between(hp,2,3,[100,0,10])

println(" -2 $(exposure_named(hp,-2.0f0))")
println("2.0 $(exposure_named(hp,2.0f0))")
println("3.5 $(exposure_named(hp,3.5))")
println("7.0 $(exposure_named(hp,7.0f0))")
println("4.9 $(exposure_named(hp,4.9))")


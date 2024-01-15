include("../src/jdiva_lib.jl")
using .jdiva

hp = HypsometricProfile(1.0f0, [-1f0, 0f0, 1f0, 2f0, 3f0, 4f0, 5f0], [0f0, 1f0, 1f0, 2f0, 3f0, 2f0, 1f0], 
[0f0 0f0 0f0 0f0; 1f0 0f0 10f0 6f0; 1f0 0f0 10f0 5f0; 2f0 0f0 20f0 4f0; 2f0 0f0 20f0 3f0; 2f0 0f0 20f0 2f0; 1f0 0f0 10f0 1f0;],
["area_lu1","area_lu2","area_lu3","area_lu4"], ["km^2","km^2","km^2","km^2"],
[0f0 0f0 0f0; 1000f0 10f0 6f0; 1000f0 10f0 5f0; 2000f0 20f0 4f0; 2000f0 20f0 3f0; 2000f0 20f0 2f0; 1000f0 10f0 1f0;],
["pop","assets1","assets2"], ["","EUR","USD"])

println("orig:")
println(hp)

add_static_exposure!(hp, hp.elevation, [0f0, 0f0, -1f0, -2f0, -3f0, -4f0, -5f0], "test", "cubicles")
add_dynamic_exposure!(hp, hp.elevation, [0f0, 1.1f0, 1.1f0, 1.1f0, -1.1f0, 1.1f0, 2.2f0], "money", "DM")

println("modified:")
println(hp)

remove_dynamic_exposure!(hp, 1)
println("modified:")
println(hp)

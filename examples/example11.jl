include("../src/jdiva_lib.jl")
using .jdiva

hp = HypsometricProfile(5.0f0, [-1f0, 0f0, 1.5f0, 2f0, 3.5f0, 4f0, 5.5f0], [0f0, 10f0, 20f0, 20f0, 3f0, 20f0, 5f0], 
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

# does not work anymore, as partial_damage is no longer exported
#println(partial_damage(hp, 2.5f0, 2, 3, 0.0f0, [0f0,0f0,0f0,0f0,0f0], [0f0,1f0,0.5f0,3f0]))
#println(partial_damage(hp, 1.50001f0, 2, 3, 0.0f0, [0f0,0f0,0f0,0f0,0f0], [0f0,1f0,0.5f0,3f0]))
#println(partial_damage(hp, 1.5f0, 2, 0.0f0, [0f0,0f0,0f0,0f0,0f0], [0f0,1f0,0.5f0,3f0]))

#==
println("damage:")
for i in 0:0.1:3
  d = damage(hp, i, 0f0, [0f0,0f0,0f0,0f0,0f0], [0f0,1f0,0.5f0,3f0])
  e = exposure(hp, i)
  println("$i:")
  println("exp: $e")
  println("dam: $d")
end

println()
println("damage comparison:")
println(exposure(hp, 4f0))
println(damage(hp, 4f0, 0f0, [0f0,0f0,0f0,0f0,0f0], [0f0,1f0,0.5f0,3f0]))
println(damage(hp, 4f0, d->1f0, [d->1f0,d->1f0,d->1f0,d->1f0,d->1f0], [d->1,d->d/(d+1.0f0),d->d/(d+0.5f0),d->d/(d+3.0f0)]))
println(exposure(hp, 10f0))
println(damage(hp, 10f0, 0f0, [0f0,0f0,0f0,0f0,0f0], [0f0,1f0,0.5f0,3f0]))
println(damage(hp, 10f0, d->1f0, [d->1f0,d->1f0,d->1f0,d->1f0,d->1f0], [d->1,d->d/(d+1.0f0),d->d/(d+0.5f0),d->d/(d+3.0f0)]))
==#

hp_new = HypsometricProfile(1.0f0, [0f0, 1f0, 2f0, 3f0, 4f0, 5f0], [0f0, 10f0, 10f0, 10f0, 10f0, 10f0], Matrix{Float32}(undef, 0, 0), Vector{String}(), Vector{String}(), reshape([0f0; 50f0; 50f0; 50f0; 50f0; 50f0;],6,1),["assets"], ["USD"])
println()
println("damage comparison:")
println(exposure(hp_new, 5f0))
@time println(damage(hp_new, 5f0, 0f0, Vector{Float32}(), [1f0]))
@time println(damage(hp_new, 5f0, 0f0, Vector{Float32}(), [1f0]))
@time println(damage(hp_new, 5f0, d->1f0, Vector{Function}(), convert(Vector{Function},[d->d/(d+1.0f0)])))
@time println(damage(hp_new, 5f0, d->1f0, Vector{Function}(), convert(Vector{Function},[d->d/(d+1.0f0)])))
println("theory: $((0.005/0.0001) * (log(1/6) + 5))")

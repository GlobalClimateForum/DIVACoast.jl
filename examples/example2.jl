include("../jdiva_lib.jl")

using .jdiva

hp = HypsometricProfileFixedClassical(1, [-1, 0, 1, 2, 3, 4, 5], [0, 1, 1, 1, 1, 1, 1], [0, 1, 1, 1, 1, 1, 1], [0, 1, 1, 1, 1, 1, 1])

println()
println("orig:")

println(hp)

println(exposure(hp,-1))
println(exposure(hp,2))
println(exposure(hp,7))
println(exposure(hp,4.9))


println()
println("sed(hp,0.9,1.2):")

sed(hp,0.9,1.2)
println(hp)

println(exposure(hp,-1))
println(exposure(hp,2))
println(exposure(hp,7))
println(exposure(hp,4.9))

println()
println("sed_above(hp,2.5,0.9,1.2):")

sed_above(hp,2.5,0.9,1.2)
println(hp)

println(exposure(hp,-1))
println(exposure(hp,2))
println(exposure(hp,7))
println(exposure(hp,4.9))

println()
println("sed_above(hp,2.5,0.9,1.2):")

sed_below(hp,2.5,0.9,1.2)
println(hp)

println(exposure(hp,-1))
println(exposure(hp,2))
println(exposure(hp,7))
println(exposure(hp,4.9))

println()
println("remove_below(hp,3.8):")

println(remove_below(hp,3.8))
println(hp)

println(exposure(hp,-1))
println(exposure(hp,2))
println(exposure(hp,7))
println(exposure(hp,4.9))

println()
println("remove_below(hp,10):")

println(remove_below(hp,10))
println(hp)

println(exposure(hp,-1))
println(exposure(hp,2))
println(exposure(hp,7))
println(exposure(hp,4.9))

println()
println("add_above(hp,0,10,100)")

add_above(hp,0,10,100)
println(hp)

println(exposure(hp,-1))
println(exposure(hp,2))
println(exposure(hp,7))
println(exposure(hp,4.9))

println()
println("add_between(hp,2,3,10,100)")

add_between(hp,2,3,10,100)
println(hp)

println(exposure(hp,-1))
println(exposure(hp,2))
println(exposure(hp,7))
println(exposure(hp,4.9))

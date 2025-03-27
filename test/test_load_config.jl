# cd(@__DIR__)
include("../src/DIVACoast.jl")
using .DIVACoast
using Test

println(earth_circumference_km)
# @testset "DIVACoast - Configuration" begin
#     @test earth_circumference_km == 40075
#     @test earth_radius_km == 6371
# end
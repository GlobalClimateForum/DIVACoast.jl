# cd(@__DIR__)
#include("../src/DIVACoast.jl")
#using .DIVACoast
#using Test

println(DIVACoast.earth_circumference_km)

@testset "DIVACoast - Configuration" begin
    @test DIVACoast.earth_circumference_km == 40075
    @test DIVACoast.earth_radius_km == 6371
end
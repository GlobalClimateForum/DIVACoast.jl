cd(@__DIR__)

using Pkg
# Activate enviroment (checks dependencies)
Pkg.activate("../.")
# Installs missing dependencies
Pkg.instantiate()
# Includes DIVACoast.jl module
include("../src/DIVACoast.jl")
# Adds DIVACoast.jl module to the current namespace
#using .DIVACoast
#using Test

println(DIVACoast.earth_circumference_km)

@testset "DIVACoast - Configuration" begin
    @test DIVACoast.earth_circumference_km == 40075
    @test DIVACoast.earth_radius_km == 6371
end
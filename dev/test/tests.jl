using Main.jdiva.HypsometricProfiles
const diva = Main.jdiva.HypsometricProfiles
using Test

# Test script to test HypsometricProfiles - fixed classical
# exposure() returns vector of (exposed_elevation, population, assets)

const exp1 = [x for x in 1:5]
pushfirst!(exp1, 0)
println(exp1)



hp = diva.HypsometricProfileFixedClassical(0, [1, 2, 3, 4, 5], exp1, [0, 1, 1, 1, 1], [0, 1, 1, 1, 1], logger)

@test Main.jdiva.HypsometricProfiles.exposure(hp, 5) == (5.0f0, 3.5f0, 2.3f0)

#Testing exposure() function
@testset "exposure()" begin
    @test Main.jdiva.HypsometricProfiles.exposure(hp,-1) == (0.0f0, 0.0f0, 0.0f0)
    @test Main.jdiva.HypsometricProfiles.exposure(hp, 0) == (0.0f0, 0.0f0, 0.0f0)
    @test Main.jdiva.HypsometricProfiles.exposure(hp, 1) == (1.0f0, 1.0f0, 1.0f0)
    @test Main.jdiva.HypsometricProfiles.exposure(hp, 100) == (5.0f0, 5.0f0, 5.0f0)
    @test Main.jdiva.HypsometricProfiles.exposure(hp, 5.1) == (5.0f0, 5.0f0, 5.0f0)
    @test Main.jdiva.HypsometricProfiles.exposure(hp, 20) == (5.0f0, 5.0f0, 5.0f0)
end

#Testing sed_above() function
Main.jdiva.HypsometricProfiles.sed_above(hp,2,0.5,0.1) #population above 2m * 0.5 + assets above 2m * 0.1
@testset "sed_above()" begin
    @test Main.jdiva.HypsometricProfiles.exposure(hp, 5) == (5.0f0, 3.5f0, 2.3f0)
    @test Main.jdiva.HypsometricProfiles.exposure(hp, 5.1) == (5.0f0, 3.5f0, 2.3f0)
    @test Main.jdiva.HypsometricProfiles.exposure(hp, 5.1) == (5.0f0, 0.0f0, 0.0f0)
end




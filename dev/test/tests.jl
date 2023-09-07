# Just a scratch pad.
include("../jdiva_lib.jl")
using .jdiva
using Test


# Creates a random Hypsometric Profile
function initHypsometricProfile()
  
  elevation = [i for i in 1:100]
  area  = [1 for i in 1:99]
  pushfirst!(area, 0)

  coastPop = [rand(20:40) for p in 1:30]
  terraPop = [rand(10:30) for p in 1:50]
  mountPop = [rand(1:10) for p in 1:19]
  population = vcat(coastPop, terraPop, mountPop)
  pushfirst!(population, 0)

  coastAst = [rand(80:100) for a in 1:30]
  terraAst = [rand(50:80) for a in 1:50]
  mountAst = [rand(20:100) for a in 1:19]
  asset = vcat(coastAst, terraAst, mountAst)
  pushfirst!(asset, 0)

  return (HypsometricProfileFixedClassical(1, elevation, area, population, asset), [1,elevation, area,population,asset])

end

println("Starting Tests for: Hypsometric Profile - Fixed Classsical")

hpTest, hpSettings = initHypsometricProfile()

@testset "Hypsometric Profile - Fixed Classical" begin

  @testset "attributes" begin
    @test hpTest.maxElevation == maximum(hpTest.elevation)
    @test hpTest.minElevation == minimum(hpTest.elevation)
    randomIndex = rand(2:length(hpTest.elevation))
    @test hpTest.delta == hpTest.elevation[randomIndex] - hpTest.elevation[randomIndex - 1]
    @test last(hpTest.cummulativeArea) == sum(hpSettings[3]) 
  end

  @testset "exposure(), exposure_named()" begin
    @test exposure(hpTest, maximum(hpSettings[2])) == exposure(hpTest, hpTest.maxElevation)
    @test exposure(hpTest, 0) == (0, 0, 0)
    @test exposure(hpTest, 100) == (last(hpTest.cummulativeArea), last(hpTest.cummulativePopulation), last(hpTest.cummulativeAssets))
    @test exposure(hpTest, 1) == (hpTest.cummulativeArea[1], hpTest.cummulativePopulation[1], hpTest.cummulativeAssets[1])
    @test exposure(hpTest, 0.5) == (hpTest.cummulativeArea[1] * 0.5, hpTest.cummulativePopulation[1] * 0.5, hpTest.cummulativeAssets[1] * 0.5)
  end
end



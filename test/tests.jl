# Just a scratch pad.
include("../jdiva_lib.jl")
using .jdiva
using Test
using StructArrays


# Creates a random Hypsometric Profile
function initHypsometricProfile(profileType, returnSettings = false)

    elevation = [i for i in 1:100]
    area  = vcat([0], [1 for i in 1:99])
    
    population = vcat([0],[rand(20:40) for p in 1:30], [rand(10:30) for p in 1:50], [rand(1:10) for p in 1:19])
    asset = vcat([0], [rand(80:100) for a in 1:30], [rand(50:80) for a in 1:50], [rand(20:100) for a in 1:19])

    populationD = vcat([0], [rand(10:20) for p in 1:30], [rand(10:30) for p in 1:50],[rand(1:10) for p in 1:19])
    assetD      = vcat([0], [rand(60:100) for a in 1:30], [rand(50:80) for a in 1:50], [rand(20:100) for a in 1:19])

    width = Float32(1.0)
    elevation = convert(Array{Float32,1}, elevation)
    area = convert(Array{Float32,1}, area)

    s_exp = StructArray{NamedTuple{(:pop, :assets0), NTuple{2, Float32}}}(
      (pop = convert(Array{Float32, 1}, population), assets0 = convert(Array{Float32,1}, asset)))

    d_exp = StructArray{NamedTuple{(:pop2, :assets1), NTuple{2, Float32}}}(
      (pop2 = convert(Array{Float32, 1}, populationD), assets1 = convert(Array{Float32,1}, assetD)))

    settings = [1,elevation, area,population,asset]

    if profileType == "fixedClassic"
      profile = HypsometricProfileFixedClassical(width, elevation, area, asset, population)
    elseif profileType == "fixedStrArr"
      profile = HypsometricProfileFixedStrarray(width, elevation, area, s_exp, d_exp)
    elseif profileType == "fixedArr"
      profile = HypsometricProfileFixed(width,elevation, area, s_exp, d_exp)
    elseif profileType == ""
      profile = HypsometricProfile(width, elevation, area, s_exp, d_exp)
    end

    if returnSettings
      return((profile, settings))
    else
      return(profile)
    end

end

function runTests(profile)

  hpTest, hpSettings  = initHypsometricProfile(profile, true)

    @testset "Hypsometric Profile - $profile" begin
  
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
  
      @testset "sed(), sed_above(), sed_below()" begin
        
        hpTest2 = deepcopy(hpTest)
        
        sed(hpTest, 1, 1) 
        @test exposure(hpTest,50) == exposure(hpTest2,50)
        
        sed_below(hpTest, 50, 0.5, 0.5)
        sed(hpTest2, 0.5, 0.5)
  
        @test exposure(hpTest, 50) == exposure(hpTest2, 50)
  
        hpTest2 = deepcopy(hpTest)
        
        sed(hpTest,0.5, 0.3)
        sed_above(hpTest, 50, 0.5, 0.3)
        
        @test exposure(hpTest, 50) == exposure(hpTest2, 50)
      end
  
      @testset "remove_below(), add_above(), add_below(), add_between()" begin
        hpTest = initHypsometricProfile(profile)
        hpTest2 = deepcopy(hpTest)
  
        remove_below(hpTest, 100)
        remove_below(hpTest2, 100)
  
        add_between(hpTest, 50, 100, 100, 100)
        add_above(hpTest2, 50, 100, 100)
  
        @test exposure(hpTest, 100) == exposure(hpTest2, 100)
      end
    end
end


for profile in ["fixedClassic", "fixedStrArr", ""]

  println("Test Hypsometric Profile: $profile")

  runTests(profile)

end

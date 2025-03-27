# Test Hypsometric Profile
exit()
# Creates a random Hypsometric Profile
function initHypsometricProfile(returnSettings = false)

    elevation = [i for i in 1:100]
    area  = vcat([0], [1 for i in 1:99])
    
    population = vcat([0],[rand(20:40) for p in 1:30], [rand(10:30) for p in 1:50], [rand(1:10) for p in 1:19])
    asset = vcat([0], [rand(80:100) for a in 1:30], [rand(50:80) for a in 1:50], [rand(20:100) for a in 1:19])

    populationD = vcat([0], [rand(10:20) for p in 1:30], [rand(10:30) for p in 1:50],[rand(1:10) for p in 1:19])
    assetD      = vcat([0], [rand(60:100) for a in 1:30], [rand(50:80) for a in 1:50], [rand(20:100) for a in 1:19])

    width = Float32(1.0)
    elevation = convert(Array{Float32,1}, elevation)
    area = convert(Array{Float32,1}, area)

    settings = [1, elevation, area, population, asset]

    profile = HypsometricProfile(width, elevation, area, asset, population)

    if returnSettings
      return((profile, settings))
    else
      return(profile)
    end

end

function runTests()

  hpTest, hpSettings  = initHypsometricProfile(true)

    @testset "Hypsometric Profile" begin
  
      @testset "attributes" begin
        @test hpTest.maxElevation == maximum(hpTest.elevation)
        @test hpTest.minElevation == minimum(hpTest.elevation)
        randomIndex = rand(2:length(hpTest.elevation))
        @test hpTest.delta == hpTest.elevation[randomIndex] - hpTest.elevation[randomIndex - 1]
        @test last(hpTest.cummulativeArea) == sum(hpSettings[3]) 
      end
  
      @testset "exposure(), exposure_named()" begin
        @test exposure_below_bathtub(hpTest, maximum(hpSettings[2])) == exposure_below_bathtub(hpTest, hpTest.maxElevation)
        @test exposure_below_bathtub(hpTest, 0) == (0, 0, 0)
        @test exposure_below_bathtub(hpTest, 100) == (last(hpTest.cummulativeArea), last(hpTest.cummulativePopulation), last(hpTest.cummulativeAssets))
        @test exposure_below_bathtub(hpTest, 1) == (hpTest.cummulativeArea[1], hpTest.cummulativePopulation[1], hpTest.cummulativeAssets[1])
        @test exposure_below_bathtub(hpTest, 0.5) == (hpTest.cummulativeArea[1] * 0.5, hpTest.cummulativePopulation[1] * 0.5, hpTest.cummulativeAssets[1] * 0.5)
      end
  
      @testset "sed(), sed_above(), sed_below()" begin
        
        hpTest2 = deepcopy(hpTest)
        
        sed(hpTest, 1, 1) 
        @test exposure_below_bathtub(hpTest,50) == exposure_below_bathtub(hpTest2,50)
        
        sed_below(hpTest, 50, 0.5, 0.5)
        sed(hpTest2, 0.5, 0.5)
  
        @test exposure_below_bathtub(hpTest, 50) == exposure_below_bathtub(hpTest2, 50)
  
        hpTest2 = deepcopy(hpTest)
        
        sed(hpTest,0.5, 0.3)
        sed_above(hpTest, 50, 0.5, 0.3)
        
        @test exposure_below_bathtub(hpTest, 50) == exposure_below_bathtub(hpTest2, 50)
      end
  
      @testset "remove_below(), add_above(), add_below(), add_between()" begin
        hpTest = initHypsometricProfile(profile)
        hpTest2 = deepcopy(hpTest)
  
        remove_below(hpTest, 100)
        remove_below(hpTest2, 100)
  
        add_between(hpTest, 50, 100, 100, 100)
        add_above(hpTest2, 50, 100, 100)
  
        @test exposure_below_bathtub(hpTest, 100) == exposure_below_bathtub(hpTest2, 100)
      end
    end
end


for profile in ["fixedClassic", "fixedStrArr", ""]

  println("Test Hypsometric Profile: $profile")

  runTests()

end

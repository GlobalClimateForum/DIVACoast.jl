# Test Hypsometric Profile
#exit()

# Creates a random Hypsometric Profile
function initHypsometricProfile(returnSettings = false)

    elevation = [i for i in 1:100]
    area  = vcat([0], [1 for i in 1:99])
    
    population = vcat([0],[rand(20:40) for p in 1:30], [rand(10:30) for p in 1:50], [rand(1:10) for p in 1:19])
    asset = vcat([0], [rand(80:100) for a in 1:30], [rand(50:80) for a in 1:50], [rand(20:100) for a in 1:19])
    exposure_data = convert(Array{Float32, 2}, hcat(population, asset))

    populationD = vcat([0], [rand(10:20) for p in 1:30], [rand(10:30) for p in 1:50],[rand(1:10) for p in 1:19])
    assetD      = vcat([0], [rand(60:100) for a in 1:30], [rand(50:80) for a in 1:50], [rand(20:100) for a in 1:19])

    width = Float32(1.0)
    elevation = convert(Array{Float32,1}, elevation)
    area = convert(Array{Float32,1}, area)

    settings = [1, elevation, area, population, asset]

    profile = HypsometricProfile(width, "km", elevation, "m", area, "km2", exposure_data, ["people","USD"])

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
        @test maximum(hpSettings[2]) == maximum(hpTest.elevation)
        @test minimum(hpSettings[2]) == minimum(hpTest.elevation)
        #randomIndex = rand(2:length(hpTest.elevation))
        #@test hpTest.delta == hpTest.elevation[randomIndex] - hpTest.elevation[randomIndex - 1]
        @test sum(hpSettings[3]) == hpTest.cummulativeArea[end]
      end
  
      @testset "exposure_below_bathtub()" begin
        #@test exposure_below_bathtub(hpTest, maximum(hpSettings[2])) == exposure_below_bathtub(hpTest, maximum(hpSettings.elevation))
        @test exposure_below_bathtub(hpTest, 0) == (0.0f0, Float32[0.0, 0.0])
        #@test exposure_below_bathtub(hpTest, 100) == (sum(hpTest.area), sum(hpTest.exposure_data[1]), sum(hpTest.exposure_data[2]))
        @test exposure_below_bathtub(hpTest, 100)[1] == sum(hpSettings[3])
        @test exposure_below_bathtub(hpTest, 100)[2][1] == sum(hpSettings[4])
        @test exposure_below_bathtub(hpTest, 100)[2][2] == sum(hpSettings[5])
      end
  
      @testset "exposure_growth!(), exposure_growth_above!(), exposure_growth_below!()" begin
        
        hpTest2 = deepcopy(hpTest)
        exposure_growth!(hpTest, [1,1]) 

        @test exposure_below_bathtub(hpTest,50) == exposure_below_bathtub(hpTest2,50)
        
        exposure_growth_below!(hpTest, 50, [0.5, 0.3])
        exposure_growth!(hpTest2, [0.5, 0.3])

        @test exposure_below_bathtub(hpTest, 50) == exposure_below_bathtub(hpTest2, 50)
  
        exposure_growth_above!(hpTest, 51, [0.5, 0.3])

        @test exposure_below_bathtub(hpTest, 100) == exposure_below_bathtub(hpTest2, 100)
      end
  
      @testset "remove_exposure_below!(), add_exposure_above!(), add_exposure_below!(), add_exposure_between!()" begin
        hpTest, hpSettings  = initHypsometricProfile(true)
        hpTest2 = deepcopy(hpTest)
  
        remove_exposure_below!(hpTest, 100)
        remove_exposure_below!(hpTest2, 100)
  
        add_exposure_between!(hpTest, 50, 100, [100, 100])
        add_exposure_above!(hpTest2, 50, [100, 100])
  
        @test exposure_below_bathtub(hpTest, 100) == exposure_below_bathtub(hpTest2, 100)
      end
    end
end


for profile in ["fixedClassic", "fixedStrArr", ""]

  println("Test Hypsometric Profile: $profile")

  runTests()

end

# Test Hypsometric Profiles


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

    profile = HypsometricProfile(width, "km", elevation, "m", area, "km2", exposure_data, ["population", "assets"] ,["people","USD"])

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
        randomIndex = rand(2:length(hpTest.elevation))
        @test sum(hpSettings[3]) == hpTest.cumulativeArea[end]
      end
    end

    @testset "Modify hypsometric profiles" begin
      ## Test land raising
      @testset "land raising" begin
        hp = deepcopy(hpTest)
        hp2 = deepcopy(hpTest)
        volume2 = land_raising!(hp2, 20.0f0)
        volume = land_raising!(hp, 20.5f0)
        @test volume2 > 0
        @test volume > 0
        @test volume > volume2
        @test hp.elevation[1] == 20.5f0
        @test hp.cumulativeArea[1] == 0f0
        @test hp.cumulativeArea[end] == sum(hpSettings[3])
        @test hp.cumulativeArea[50] == hp2.cumulativeArea[50] 
        @test hp.cumulativeExposure[50] == hp2.cumulativeExposure[50]
        @test hp.cumulativeExposure[end,:] == [sum(hpSettings[4]), sum(hpSettings[5])]  
        @test hp.cumulativeExposure[end,:] == hp2.cumulativeExposure[end,:]

        # Test land raising to a higher elevation than the highest point
        volume = land_raising!(hp, 105f0)
        @test volume > 0
        @test hp.elevation[1] == 105f0
        @test hp.cumulativeArea[1] == 0f0
        @test hp.cumulativeArea[end] == sum(hpSettings[3])
        @test hp.cumulativeExposure[end,:] == [sum(hpSettings[4]), sum(hpSettings[5])] 
      end
    end
end

runTests()


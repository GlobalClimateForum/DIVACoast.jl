# Test Hypsometric Profile
#exit()

# Creates a random Hypsometric Profile
function initHypsometricProfile(returnSettings=false)

  elevation = [i for i in 1:100]
  area = vcat([0], [1 for i in 1:99])

  population = vcat([0], [rand(20:40) for p in 1:30], [rand(10:30) for p in 1:50], [rand(1:10) for p in 1:19])
  asset = vcat([0], [rand(80:100) for a in 1:30], [rand(50:80) for a in 1:50], [rand(20:100) for a in 1:19])
  exposure_data = convert(Array{Float32,2}, hcat(population, asset))

  populationD = vcat([0], [rand(10:20) for p in 1:30], [rand(10:30) for p in 1:50], [rand(1:10) for p in 1:19])
  assetD = vcat([0], [rand(60:100) for a in 1:30], [rand(50:80) for a in 1:50], [rand(20:100) for a in 1:19])

  width = convert(Float32,rand() * 5)
  elevation = convert(Array{Float32,1}, elevation)
  area = convert(Array{Float32,1}, area)

  settings = [1, elevation, area, population, asset]

  profile = HypsometricProfile(width, "km", elevation, "m", area, "km2", exposure_data, ["population", "assets"], ["people", "USD"])

  if returnSettings
    return ((profile, settings))
  else
    return (profile)
  end

end

function runTests()

  number_of_tests = 1

  @testset "Hypsometric Profile" begin
    @testset "exposure()" begin
      for i in 1:number_of_tests
        hpTest, hpSettings = initHypsometricProfile(true)
        @test exposure(hpTest, 0, BathtubInundation()) == (0.0f0, Float32[0.0, 0.0])

        @test exposure(hpTest, 100, BathtubInundation())[1] == sum(hpSettings[3])
        @test exposure(hpTest, 100, BathtubInundation())[2][1] == sum(hpSettings[4])
        @test exposure(hpTest, 100, BathtubInundation())[2][2] == sum(hpSettings[5])

        el = rand() * 100
        el = 100.0f0
        @test exposure(hpTest, el, :area, BathtubInundation()) == exposure(hpTest, el, BathtubInundation())[1]
        @test exposure(hpTest, el, :population, BathtubInundation()) == exposure(hpTest, el, BathtubInundation())[2][1]
        @test exposure(hpTest, el, :assets, BathtubInundation()) == exposure(hpTest, el, BathtubInundation())[2][2]

        println(exposure(hpTest, 0, LinearDistanceAttenuatedInundation(0.1)))
        @test exposure(hpTest, 0, LinearDistanceAttenuatedInundation(0.1)) == (0.0f0, Float32[0.0, 0.0])

      end
    end

    @testset "exposure_growth!(), exposure_growth_above!(), exposure_growth_below!()" begin
      for i in 1:number_of_tests
        hpTest, hpSettings = initHypsometricProfile(true)

        hpTest2 = deepcopy(hpTest)
        multiply_exposure!(hpTest, [1, 1])

        @test exposure(hpTest, 50, BathtubInundation()) == exposure(hpTest2, 50, BathtubInundation())

        multiply_exposure_below!(hpTest, 50, [0.5, 0.3])
        multiply_exposure!(hpTest2, [0.5, 0.3])

        @test exposure(hpTest, 50, BathtubInundation()) == exposure(hpTest2, 50, BathtubInundation())

        multiply_exposure_above!(hpTest, 51, [0.5, 0.3])

        @test exposure(hpTest, 100, BathtubInundation()) == exposure(hpTest2, 100, BathtubInundation())
      end
    end

    @testset "remove_exposure_below!(), add_exposure_above!(), add_exposure_below!(), add_exposure_between!()" begin
      for i in 1:number_of_tests
        hpTest, hpSettings = initHypsometricProfile(true)
        hpTest2 = deepcopy(hpTest)

        remove_exposure_below!(hpTest, 100)
        remove_exposure_below!(hpTest2, 100)

        add_exposure_between!(hpTest, 50, 100, [100, 100])
        add_exposure_above!(hpTest2, 50, [100, 100])

        @test exposure(hpTest, 100, BathtubInundation()) == exposure(hpTest2, 100, BathtubInundation())

        multiply_exposure_below!(hpTest, 50, 100, "population")
        multiply_exposure_above!(hpTest, 51, 100, "population")
        println(exposure(hpTest, 100, BathtubInundation()))

        @test exposure(hpTest, 100, "assets", BathtubInundation()) == exposure(hpTest2, 100, "assets", BathtubInundation())
        @test exposure(hpTest, 100, "population", BathtubInundation()) == 100 * exposure(hpTest2, 100, "population", BathtubInundation())

        multiply_exposure!(hpTest2, 100, "population")
        @test exposure(hpTest, 100, "population", BathtubInundation()) == exposure(hpTest2, 100, "population", BathtubInundation())

      end
    end
  end
end

runTests()


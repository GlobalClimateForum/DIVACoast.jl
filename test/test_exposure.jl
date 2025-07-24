# Test Hypsometric Profile
#exit()

# Creates a random Hypsometric Profile
function initHypsometricProfile(returnSettings=false)

  elevation = [i for i in 1:100]
  area = vcat([0], [rand() for i in 1:99])

  population = vcat([0], [rand(20:40) for p in 1:30], [rand(10:30) for p in 1:50], [rand(1:10) for p in 1:19])
  asset = vcat([0], [rand(80:100) for a in 1:30], [rand(50:80) for a in 1:50], [rand(20:100) for a in 1:19])
  exposure_data = convert(Array{Float32,2}, hcat(population, asset))

  populationD = vcat([0], [rand(10:20) for p in 1:30], [rand(10:30) for p in 1:50], [rand(1:10) for p in 1:19])
  assetD = vcat([0], [rand(60:100) for a in 1:30], [rand(50:80) for a in 1:50], [rand(20:100) for a in 1:19])

  width = convert(Float32, rand() * 5)
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

  #  @testset "Exposure" begin
  @testset "exposure()" begin
    for i in 1:number_of_tests
      hpTest, hpSettings = initHypsometricProfile(true)

      @test exposure(hpTest, 0, BathtubInundation()) == (0.0f0, Float32[0.0, 0.0])
      @test isapprox(exposure(hpTest, 100, BathtubInundation())[1], sum(hpSettings[3]), atol=0.0001)
      @test isapprox(exposure(hpTest, 100, BathtubInundation())[2][1], sum(hpSettings[4]), atol=0.0001)
      @test isapprox(exposure(hpTest, 100, BathtubInundation())[2][2], sum(hpSettings[5]), atol=0.0001)

      el = rand() * 105
      @test isapprox(exposure(hpTest, el, :area, BathtubInundation()), exposure(hpTest, el, BathtubInundation())[1], atol=0.0001)
      @test isapprox(exposure(hpTest, el, :population, BathtubInundation()), exposure(hpTest, el, BathtubInundation())[2][1], atol=0.0001)
      @test isapprox(exposure(hpTest, el, :assets, BathtubInundation()), exposure(hpTest, el, BathtubInundation())[2][2], atol=0.0001)

      @test exposure(hpTest, 0, LinearDistanceAttenuatedInundation(0.1)) == (0.0f0, Float32[0.0, 0.0])
      @test isapprox(exposure(hpTest, el, :area, LinearDistanceAttenuatedInundation(0.1)), exposure(hpTest, el, LinearDistanceAttenuatedInundation(0.1))[1], atol=0.0001)
      @test isapprox(exposure(hpTest, el, :population, LinearDistanceAttenuatedInundation(0.1)), exposure(hpTest, el, LinearDistanceAttenuatedInundation(0.1))[2][1], atol=0.0001)
      @test isapprox(exposure(hpTest, el, :assets, LinearDistanceAttenuatedInundation(0.1)), exposure(hpTest, el, LinearDistanceAttenuatedInundation(0.1))[2][2], atol=0.0001)
    end
  end

  @testset "multiply_exposure!(), multiply_exposure_above!(), multiply_exposure_below!()" begin
    for i in 1:number_of_tests
      hpTest, hpSettings = initHypsometricProfile(true)
      hpTest2 = deepcopy(hpTest)

      el = rand() * 105 +1
      multiply_exposure!(hpTest, [1, 1])
      @test exposure(hpTest, el, BathtubInundation()) == exposure(hpTest2, el, BathtubInundation())

      # area should not be affected
      multiply_exposure!(hpTest, 2.0, :area)
      @test exposure(hpTest, el, :area, BathtubInundation()) == exposure(hpTest2, el, :area, BathtubInundation())

      multiply_exposure!(hpTest, 1.2, :assets)
      @test isapprox(exposure(hpTest, el, :assets, BathtubInundation()), exposure(hpTest2, el, :assets, BathtubInundation()) * 1.2, atol=0.001)
      @test isapprox(exposure(hpTest, el, :assets, LinearDistanceAttenuatedInundation(0.25)), exposure(hpTest2, el, :assets, LinearDistanceAttenuatedInundation(0.25)) * 1.2, atol=0.001)
      @test isapprox(exposure(hpTest, el, :population, BathtubInundation()), exposure(hpTest2, el, :population, BathtubInundation()), atol=0.001)
      @test isapprox(exposure(hpTest, el, :population, LinearDistanceAttenuatedInundation(0.25)), exposure(hpTest2, el, :population, LinearDistanceAttenuatedInundation(0.25)), atol=0.001)

      multiply_exposure!(hpTest, 0.666, :population)
      @test isapprox(exposure(hpTest, el, :assets, BathtubInundation()), exposure(hpTest2, el, :assets, BathtubInundation()) * 1.2, atol=0.001)
      @test isapprox(exposure(hpTest, el, :assets, LinearDistanceAttenuatedInundation(0.25)), exposure(hpTest2, el, :assets, LinearDistanceAttenuatedInundation(0.25)) * 1.2, atol=0.001)
      @test isapprox(exposure(hpTest, el, :population, BathtubInundation()), exposure(hpTest2, el, :population, BathtubInundation()) * 0.666, atol=0.001)
      @test isapprox(exposure(hpTest, el, :population, LinearDistanceAttenuatedInundation(0.25)), exposure(hpTest2, el, :population, LinearDistanceAttenuatedInundation(0.25)) * 0.666, atol=0.001)

      hpTest = deepcopy(hpTest2)
      multiply_exposure_above!(hpTest, 0.0, [0.8, 0.975])

      el = rand() * 99 + 1
      @test isapprox(exposure(hpTest, el, :area, BathtubInundation()), exposure(hpTest2, el, :area, BathtubInundation()), atol=0.001)
      @test isapprox(exposure(hpTest, el, :area, LinearDistanceAttenuatedInundation(0.25)), exposure(hpTest2, el, :area, LinearDistanceAttenuatedInundation(0.25)), atol=0.001)
      @test isapprox(exposure(hpTest, el, :assets, BathtubInundation()), exposure(hpTest2, el, :assets, BathtubInundation()) * 0.975, atol=0.001)
      @test isapprox(exposure(hpTest, el, :assets, LinearDistanceAttenuatedInundation(0.25)), exposure(hpTest2, el, :assets, LinearDistanceAttenuatedInundation(0.25)) * 0.975, atol=0.001)
      @test isapprox(exposure(hpTest, el, :population, BathtubInundation()), exposure(hpTest2, el, :population, BathtubInundation()) * 0.8, atol=0.001)
      @test isapprox(exposure(hpTest, el, :population, LinearDistanceAttenuatedInundation(0.25)), exposure(hpTest2, el, :population, LinearDistanceAttenuatedInundation(0.25)) * 0.8, atol=0.001)

      hpTest = deepcopy(hpTest2)
      el = rand() * 50 + 1

      multiply_exposure_above!(hpTest, el, [0.5, 0.5])
      @test isapprox(exposure(hpTest, el, :area, BathtubInundation()), exposure(hpTest2, el, :area, BathtubInundation()), atol=0.001)
      @test isapprox(exposure(hpTest, el, :area, LinearDistanceAttenuatedInundation(0.25)), exposure(hpTest2, el, :area, LinearDistanceAttenuatedInundation(0.25)), atol=0.001)
      @test isapprox(exposure(hpTest, el, :assets, BathtubInundation()), exposure(hpTest2, el, :assets, BathtubInundation()), atol=0.001)

      @test isapprox(exposure(hpTest, el, :assets, LinearDistanceAttenuatedInundation(0.25)), exposure(hpTest2, el, :assets, LinearDistanceAttenuatedInundation(0.25)), atol=0.001)

      @test isapprox(exposure(hpTest, el, :population, BathtubInundation()), exposure(hpTest2, el, :population, BathtubInundation()), atol=0.001)
      @test isapprox(exposure(hpTest, el, :population, LinearDistanceAttenuatedInundation(0.25)), exposure(hpTest2, el, :population, LinearDistanceAttenuatedInundation(0.25)), atol=0.001)
      @test exposure(hpTest, el + 10, :assets, BathtubInundation()) < exposure(hpTest2, el + 10, :assets, BathtubInundation())
      @test exposure(hpTest, el + 10, :assets, LinearDistanceAttenuatedInundation(0.25)) < exposure(hpTest2, el + 10, :assets, LinearDistanceAttenuatedInundation(0.25))
      @test exposure(hpTest, el + 10, :population, BathtubInundation()) < exposure(hpTest2, el + 10, :population, BathtubInundation())
      @test exposure(hpTest, el + 10, :population, LinearDistanceAttenuatedInundation(0.25)) <= exposure(hpTest2, el + 10, :population, LinearDistanceAttenuatedInundation(0.25))

      multiply_exposure_above!(hpTest, el, :assets, 2.0)
      @test isapprox(exposure(hpTest, el+10, :assets, BathtubInundation()), exposure(hpTest2, el+10, :assets, BathtubInundation()), atol=0.001)
      @test isapprox(exposure(hpTest, el+10, :assets, LinearDistanceAttenuatedInundation(0.25)), exposure(hpTest2, el+10, :assets, LinearDistanceAttenuatedInundation(0.25)), atol=0.001)

      hpTest = deepcopy(hpTest2)
      el = convert(Float32, rand() * 50)
      multiply_exposure_below!(hpTest, el, [0.75, 0.9])

      @test isapprox(exposure(hpTest, el, :assets, BathtubInundation()), exposure(hpTest2, el, :assets, BathtubInundation()) * 0.9, atol=0.001)
      @test isapprox(exposure(hpTest, el, :assets, LinearDistanceAttenuatedInundation(0.25)), exposure(hpTest2, el, :assets, LinearDistanceAttenuatedInundation(0.25)) * 0.9, atol=0.001)
      @test isapprox(exposure(hpTest, el, :population, BathtubInundation()), exposure(hpTest2, el, :population, BathtubInundation()) * 0.75, atol=0.001)
      @test isapprox(exposure(hpTest, el, :population, LinearDistanceAttenuatedInundation(0.25)), exposure(hpTest2, el, :population, LinearDistanceAttenuatedInundation(0.25)) * 0.75, atol=0.001)

      if exposure(hpTest2, el + 10, :assets, LinearDistanceAttenuatedInundation(0.25)) > exposure(hpTest2, el, :assets, LinearDistanceAttenuatedInundation(0.25))
        @test exposure(hpTest, el + 10, :assets, BathtubInundation()) < exposure(hpTest2, el + 10, :assets, BathtubInundation())
        @test exposure(hpTest, el + 10, :assets, LinearDistanceAttenuatedInundation(0.25)) < exposure(hpTest2, el + 10, :assets, LinearDistanceAttenuatedInundation(0.25))
      end
      if exposure(hpTest2, el + 10, :population, BathtubInundation()) > exposure(hpTest2, el, :population, BathtubInundation())
        @test exposure(hpTest, el + 10, :population, BathtubInundation()) < exposure(hpTest2, el + 10, :population, BathtubInundation())
        @test exposure(hpTest, el + 10, :population, LinearDistanceAttenuatedInundation(0.25)) < exposure(hpTest2, el + 10, :population, LinearDistanceAttenuatedInundation(0.25))
      end

      multiply_exposure_below!(hpTest, el, :population, 1/0.75)
      @test isapprox(exposure(hpTest, el, :population, BathtubInundation()), exposure(hpTest2, el, :population, BathtubInundation()), atol=0.001)
      @test isapprox(exposure(hpTest, el, :population, LinearDistanceAttenuatedInundation(0.25)), exposure(hpTest2, el, :population, LinearDistanceAttenuatedInundation(0.25)), atol=0.001)
      @test isapprox(exposure(hpTest, el + 10, :population, BathtubInundation()), exposure(hpTest2, el + 10, :population, BathtubInundation()), atol=0.001)
      @test isapprox(exposure(hpTest, el + 10, :population, LinearDistanceAttenuatedInundation(0.25)), exposure(hpTest2, el + 10, :population, LinearDistanceAttenuatedInundation(0.25)), atol=0.001)

    end
  end

  
  @testset "remove_exposure_below!(), add_exposure_above!(), add_exposure_between!()" begin
    for i in 1:number_of_tests
      hpTest, hpSettings = initHypsometricProfile(true)
      hpTest2 = deepcopy(hpTest)

      removed_exp = remove_exposure_below!(hpTest, 50)
      @test exposure(hpTest, 50, BathtubInundation())[2] == Float32[0.0, 0.0]
      @test exposure(hpTest, 100, BathtubInundation())[2] .+ removed_exp == exposure(hpTest2, 100, BathtubInundation())[2]
      
      add_exposure_between!(hpTest, 0, 50, removed_exp)
      @test exposure(hpTest, 100, BathtubInundation()) == exposure(hpTest2, 100, BathtubInundation())

      add_exposure_above!(hpTest, 90, removed_exp)
      @test exposure(hpTest2, 100, BathtubInundation())[2] .+ removed_exp == exposure(hpTest, 100, BathtubInundation())[2]
      

    end
  end
end

runTests()


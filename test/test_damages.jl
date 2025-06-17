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


function initSimpleProfile(returnSettings=false)

  elevation = [0,100]
  area = [0,rand()*500]
  population = [0,rand()*2000]
  assets = [0,rand()*45000*population[2]]

  exposure_data = convert(Array{Float32,2}, hcat(population, assets))
  width = convert(Float32, rand() * 5)

  elevation = convert(Array{Float32,1}, elevation)
  area = convert(Array{Float32,1}, area)

  settings = [width, elevation, area, population, assets]

  profile = HypsometricProfile(width, "km", elevation, "m", area, "km2", exposure_data, ["population", "assets"], ["people", "USD"])

  if returnSettings
    return ((profile, settings))
  else
    return (profile)
  end
end


function runTests()

  number_of_tests = 1

  @testset "damage()" begin
    for i in 1:number_of_tests
      hpTest, hpSettings = initHypsometricProfile(true)

      @test damage(hpTest, 0, [:population,:assets], [StandardDDF(0.0), StandardDDF(1.0)], BathtubInundation()) == Float32[0.0, 0.0]
      @test damage(hpTest, 0, :population, StandardDDF(0.0)) == Float32[0.0]
      @test damage(hpTest, 0, [:population,:assets], [StandardDDF(0.0), StandardDDF(1.0)], LinearDistanceAttenuatedInundation(0.1)) == Float32[0.0, 0.0]
      @test damage(hpTest, 0, :assets, StandardDDF(1.0), LinearDistanceAttenuatedInundation(0.1)) == Float32[0.0]

      @test damage(hpTest, 0, [:population,:assets], [d -> 1, d -> d/(d+1)], BathtubInundation()) == Float32[0.0, 0.0]
      @test damage(hpTest, 0, ["population", "assets"], [d -> 1, d -> d/(d+1)], LinearDistanceAttenuatedInundation(0.1)) == Float32[0.0, 0.0]

      el = rand() * 100
      println("fast:")
      @time println(damage(hpTest, el, [:population,:assets], [StandardDDF(0.0), StandardDDF(1.0)], BathtubInundation()))
      println("slow:")
      @time println(damage(hpTest, el, [:population,:assets], [d -> 1, d -> d/(d+1)], BathtubInundation()))
      @test isapprox(damage(hpTest, el, [:population,:assets], [StandardDDF(0.0), StandardDDF(1.0)], BathtubInundation()), damage(hpTest, el, [:population,:assets], [d -> 1, d -> d/(d+1)], BathtubInundation()))
      @test isapprox(damage(hpTest, el, [:population,:assets], [StandardDDF(0.0), StandardDDF(1.0)], LinearDistanceAttenuatedInundation(0.1)), damage(hpTest, el, [:population,:assets], [d -> 1, d -> d/(d+1)], LinearDistanceAttenuatedInundation(0.1)))

      remove_exposure_below!(hpTest, 100.0)
      @test damage(hpTest, el, [:population,:assets], [StandardDDF(0.0), StandardDDF(1.0)], BathtubInundation()) == Float32[0.0, 0.0]
      @test damage(hpTest, el, :popoulation, StandardDDF(0.0), BathtubInundation()) == Float32[0.0]
    end
  end

  @testset "damage() - test math" begin
    for i in 1:number_of_tests
      hpTest, hpSettings = initSimpleProfile(true)

      rho = (exposure(hpTest, 100, :assets, BathtubInundation()) / ((exposure(hpTest, 100, :area, BathtubInundation()) / hpTest.width))) / 1000
      sl = slope(hpTest, 2)

      el = rand() * 50
      @test isapprox(damage(hpTest, el, :assets, d -> d/(d+1))[1], rho/sl * (log(1/(1+el)) + el) , rtol=0.1)
      @test isapprox(damage(hpTest, el, :population, d -> 1)[1], exposure(hpTest, el, BathtubInundation())[2][1] , rtol=0.1)

println(damage(hpTest, el, :assets, StandardDDF(1.0)))
println(damage(hpTest, el, :assets, d -> d/(d+1)))
println(rho/sl * (log(1/(1+el)) + el))

println(damage(hpTest, el, :assets, StandardDDF(1.0), LinearDistanceAttenuatedInundation(0.1)))
println(damage(hpTest, el, :assets, d -> d/(d+1), LinearDistanceAttenuatedInundation(0.1)))
println(rho/(sl+(0.1/1000)) * (log(1/(1+el)) + el))

      @test isapprox(damage(hpTest, el, :assets, d -> d/(d+1), LinearDistanceAttenuatedInundation(0.1))[1], rho/(sl+(0.1/1000)) * (log(1/(1+el)) + el), atol=0.1)
      @test isapprox(damage(hpTest, el, :assets, StandardDDF(1.0), LinearDistanceAttenuatedInundation(0.1))[1], rho/(sl+(0.1/1000)) * (log(1/(1+el)) + el), atol=0.1)
      @test isapprox(damage(hpTest, el, :population, d -> 1, LinearDistanceAttenuatedInundation(0.1))[1], exposure(hpTest, el, LinearDistanceAttenuatedInundation(0.1))[2][1] , rtol=0.1)
      el = rand()*50
      @test isapprox(damage(hpTest, el, :assets, d -> d/(d+1))[1], rho/sl * (log(1/(1+el)) + el), rtol=1e-6)
      @test isapprox(damage(hpTest, el, "population", d -> 1)[1], exposure(hpTest, el, BathtubInundation())[2][1], rtol=1e-6)

    end
  end

end

runTests()



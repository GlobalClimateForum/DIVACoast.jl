# Test Hypsometric Profiles
include("../src/DIVACoast.jl")
using .DIVACoast

using DataFrames

hspfs = load_hsps_nc(Int32, Float32, "./testdata/UKIRL/nc/UKIRL_hspfs_floodplains.nc")


# Try with explicit module reference
df =  to_DF(hspfs[2071])
println(df)

println(typeof(hspfs))
dfs = to_DF(hspfs)
println(first(df, 10))
println(size(dfs))


save(hspfs, "test_hspfs.jld2")
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
        @test hpTest.delta == hpTest.elevation[randomIndex] - hpTest.elevation[randomIndex - 1]
        @test sum(hpSettings[3]) == hpTest.cummulativeArea[end]
      end
  
end

runTests()


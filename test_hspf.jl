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

<<<<<<< HEAD
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
=======
>>>>>>> 2edd5e350b0c144a9a19fc4dd346d0ac7f863cb9

save(hspfs, "test_hspfs.jld2")
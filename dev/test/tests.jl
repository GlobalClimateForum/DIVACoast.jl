# Just a scratch pad.
include("../jdiva_lib.jl")
using .jdiva
using Test

# Creates a random Hypsometric Profile
function initHypsometricProfile(profileType, returnSettings = false)

  if profileType == "fixedClassic"
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

    profile = HypsometricProfileFixedClassical(1, elevation, area, population, asset)
    settings = [1,elevation, area,population,asset]

  elseif profileType == "fixedStrArray"

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

    profile = HypsometricProfileFixedStrarray(1, elevation, area, population, asset)
    settings = [1,elevation, area,population,asset]

  elseif profileType == "flex"

    elevation = sort([rand(1:100) for i in 1:100])
    area = [1 for i in 1:99]
    pushfirst!(area, 0)

    coastPop = [rand(20:40) for p in 1:30]
    terraPop = [rand(10:30) for p in 1:50]
    mountPop = [rand(1:10) for p in 1:19]
    population = [vcat(coastPop, terraPop, mountPop)]
    pushfirst!(population, 0)

    coastAst = [rand(80:100) for a in 1:30]
    terraAst = [rand(50:80) for a in 1:50]
    mountAst = [rand(20:100) for a in 1:19]
    asset = [vcat(coastAst, terraAst, mountAst)]

    pushfirst!(asset, 0)

    profile = HypsometricProfileFlex(1.0, elevation, area, population, asset)
    settings = [1,elevation, area,population,asset]
  
  end

  if returnSettings
    return((profile, settings))
  else
    return(profile)
  end

end

function runTests(profile)

  hpTest, hpSettings  = initHypsometricProfile(profile, true)

  @testset "DIVA Library Tests" begin
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

end


for profile in ["fixedClassic", "fixedStrArray", "flex"]

  profileInitialized = false

  try 
    hpTest, hpSettings = initHypsometricProfile(profile, true)
    profileInitialized = true
  catch 
    println("Could not initialize profile")
  end

  if profileInitialized
    runTests(profile)
  end 

end

include("../logger/jdiva_logger.jl")
using Logging
using Dates
include("../jdiva_lib.jl")
using Main.ExtendedLogging
io = open(".jdiva_log", "w+")
simple_logger = Logging.SimpleLogger(io)
logger = Main.ExtendedLogging.ExtendedLogger(simple_logger,io,now())
using Main.jdiva.HypsometricProfiles
using Test

ENV["JULIA_STACKTRACE_MINIMAL"] = true
hypProf = Main.jdiva.HypsometricProfiles

function initHPFixedClassical()
    exp1 = [1 for exp in 1:6]
    pushfirst!(exp1, 0)
    exp2 = [1 for exp in 1:6]
    pushfirst!(exp2, 0)
    exp3 = [1 for exp in 1:6]
    pushfirst!(exp3, 0)
    elv1 = [elv for elv in -1:5]
    exposures = [exp1, exp2, exp3]
    hp = hypProf.HypsometricProfileFixedClassical(1, elv1, exp1, exp2, exp3, logger)
    return hp
end

minElevation = 0.0f0
maxElevation = 5.0f0
    
@testset "HypsometricProfileFixedClassical" begin
    
    #function exposure should return: area, exp1, exp2
    #function sed() requires a hypsometric Profile and a factor for population development and asset development
    #function sed_above() requires a hypsometric Profile and an elevation, a factor for pop development and a factor for asset development
    
    hp = initHPFixedClassical()
    @testset "exposure() at exposure $i" for i in minElevation:maxElevation
        exposure = hypProf.exposure(hp, i)
        expected = Float32.((i + 1, i + 1, i + 1))
        @test exposure == expected
    end

    @testset "exposure() below min Elevation ($i)" for i in hp.minElevation-2:hp.minElevation
        @test hypProf.exposure(hp, i) == Float32.((0, 0, 0))
    end

    @testset "exposure() below min Elevation ($i)" for i in hp.maxElevation:hp.maxElevation+2
        @test hypProf.exposure(hp, i) == hypProf.exposure(hp, hp.maxElevation)
    end

    @testset "sed() at exposure $i" for i in minElevation:maxElevation
        hypProf.sed(hp, 0.5, 0.5)
        exposure = hypProf.exposure(hp, i)
        expected = [i + 1, (i + 1) * 0.5^((i+1)-minElevation), (i + 1) * 0.5^((i+1)-minElevation)]
        expected = Float32.(expected)
        @test collect(exposure) == expected
    end

    hp = initHPFixedClassical()
    @testset "sed_above(3) at exposure $i" for i in minElevation:maxElevation
        hypProf.sed_above(hp, 3, 0.5, 0.5)
        expectedExp = [e < 3 ? 1 : 0.5 for e in 0:6][1:i + 1]
        expected = Float32.([i + 1, sum(expectedExp), sum(expectedExp)])
        exposure = hypProf.exposure(hp,i)
        @test collect(exposure) == expected
     end

     @testset "sed_below(3) at exposure $i" for i in minElevation:maxElevation
        hp = initHPFixedClassical()
        hypProf.sed_below(hp, 3, 0.5, 0.5)
        expectedExp = [e < 3 ? 0.5 : 1 for e in 0:6][1:i + 1]
        expected = Float32.([i + 1, sum(expectedExp), sum(expectedExp)])
        exposure = hypProf.exposure(hp,i)
        @test collect(exposure) == expected
     end

     @testset "remove_below($i)" for i in minElevation:maxElevation
        hp = initHPFixedClassical()
        hypProf.remove_below(hp, i)

        removeArr = Float32.([0 for r in 1:i-1])
        expected = cat(removeArr, hp.cummulativeAssets[i:end], dims = 1)

        @test expected == hp.cummulativeAssets == hp.cummulativePopulation
     end

     function expectedAddBetween(hp, from, to)
        sliced = hp.cummulativeAssets[from:to]
        add = 1 / length(sliced)
        new = [e + add for e in sliced]
        exp = cat(hp.cummulativeAssets[1:from], new, hp.cummulativeAssets[to:end], dims = 1)
        return Float32.(exp)
        end 

     @testset "add_between(1,$i,1,1)" for i in minElevation:maxElevation

        hp = initHPFixedClassical()
        expected = expectedAddBetween(hp, 1, i)
        hypProf.add_between(hp, 1, i, 1, 1) 
        @test expected == hp.cummulativeAssets

    end
end
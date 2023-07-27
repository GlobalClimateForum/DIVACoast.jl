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

minExposure = 0
maxExposure = 6
    
@testset "HypsometricProfileFixedClassical" begin
    
    #function exposure should return: area, exp1, exp2
    #function sed() requires a hypsometric Profile and a factor for population development and asset development
    #function sed_above() requires a hypsometric Profile and an elevation, a factor for pop development and a factor for asset development
    
    @testset "exposure() at exposure $i" for i in minExposure:maxExposure
        hp = initHPFixedClassical()
        exposure = hypProf.exposure(hp, i)
        expected = Float32.((i + 1, i + 1, i + 1))
        @test exposure == expected
    end

    @testset "sed() at exposure $i" for i in minExposure:maxExposure
        hp = initHPFixedClassical()
        hypProf.sed(hp, 0.5, 0.5)
        exposure = hypProf.exposure(hp, i)
        expected = [i + 1, (i + 1) * 0.5, (i + 1) * 0.5]
        expected = Float32.(expected)
        @test collect(exposure) == expected
    end

     @testset "sed_above(3) at exposure $i" for i in minExposure:maxExposure
        hp = initHPFixedClassical()
        hypProf.sed_above(hp, 3, 0.5, 0.5)
        expectedExp = [e < 3 ? 1 : 0.5 for e in 0:6][1:i + 1]
        expected = Float32.([i + 1, sum(expectedExp), sum(expectedExp)])
        exposure = hypProf.exposure(hp,i)
        @test collect(exposure) == expected
     end

     @testset "sed_below(3) at exposure $i" for i in minExposure:maxExposure
        hp = initHPFixedClassical()
        hypProf.sed_above(hp, 3, 0.5, 0.5)
        expectedExp = [e < 3 ? 0.5 : 1 for e in 0:6][1:i + 1]
        expected = Float32.([i + 1, sum(expectedExp), sum(expectedExp)])
        exposure = hypProf.exposure(hp,i)
        @test collect(exposure) == expected
     end

end
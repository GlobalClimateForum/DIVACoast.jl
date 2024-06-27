include("./jdiva_lib.jl")
using jdiva 

function secretfunction(from::Int, to::Int)
    return "SECRET"
end


for i in LogIter(1:100, "up to hundred", 10)
end

LogFunc(secretfunction, 1, 100, logLevel = Logging.Debug)

include("../logger/jdiva_logger.jl")

using Logging
using Dates

include("../jdiva_lib.jl")
using Main.ExtendedLogging

io = open(".jdiva_log", "w+")
logger = Logging.SimpleLogger(io)
mylogger = Main.ExtendedLogging.ExtendedLogger(logger,io,now())

Main.ExtendedLogging.log(mylogger,Logging.Info,@__FILE__,"test")
Main.ExtendedLogging.log(mylogger,Logging.Warn,@__FILE__,"test")
Main.ExtendedLogging.log(mylogger,Logging.Error,@__FILE__,"test")

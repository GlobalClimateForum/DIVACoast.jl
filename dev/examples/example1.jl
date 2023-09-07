include("../jdiva_lib.jl")

using .jdiva
using Logging
using Dates

io = open(".jdiva_log", "w+")
logger = SimpleLogger(io)
mylogger = ExtendedLogger(logger,io,now())

logg(mylogger,Info,@__FILE__,"","test")
logg(mylogger,Warn,@__FILE__,"","test")
logg(mylogger,Error,@__FILE__,"","test")

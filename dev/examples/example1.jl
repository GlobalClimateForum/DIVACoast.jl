include("../jdiva_lib.jl")

io = open(".jdiva_log", "w+")
logger = SimpleLogger(io)
mylogger = ExtendedLogger(logger,io,now())

log(mylogger,Info,@__FILE__,"test")
log(mylogger,Warn,@__FILE__,"test")
log(mylogger,Error,@__FILE__,"test")

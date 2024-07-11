include("../jdiva_lib.jl")
using .jdiva
using Logging

@info "This is not logged using the DIVA Logger"

global_logger(DIVALogger()) # Set Global Logger to DIVA Logger

@info "This is now logged using the DIVA Logger"

function testfunction(a, b)
    println("Inside the function")
    return nothing
end 

LogFunc(testfunction, "arg1" , "arg2") # Logging a function call

for a in LogIter(1:100, "up to 100", 10) # Logging a Iteration  called 'up to 100'
    c = a + a
end

@debug "This is a hidden Debug log." #  Log is hidden since default min log level is Info

set_loglvl!(Logging.Debug) # Change Log Level of DIVALogger

@debug "This is a visible Debug log." # Debug Log is now visible


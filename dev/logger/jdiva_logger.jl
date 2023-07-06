module ExtendedLogging

export ExtendedLogger, log

using Logging
using Dates

struct ExtendedLogger
    mylogger
    io
    starttime
end

function log(logger,command,caller,message)
    if (command==Logging.Debug) 
	with_logger(logger.mylogger) do
	    @debug "\t$(now()) after  $(now()-logger.starttime) from " * caller * ": " * message
	end
	flush(logger.io)
    end

    if (command==Logging.Info) 
	with_logger(logger.mylogger) do
	    @info "\t$(now()) after  $(now()-logger.starttime) from " * caller * ": " * message
	end
	flush(logger.io)
    end

    if (command==Logging.Warn) 
	with_logger(logger.mylogger) do
	    @warn "\t$(now()) after  $(now()-logger.starttime) from " * caller * ": " * message
	end
	flush(logger.io)
    end

    if (command==Logging.Error) 
	with_logger(logger.mylogger) do
	    @error "\t$(now()) after  $(now()-logger.starttime) from " * caller * ": " * message
	    println("ERROR: $(now()) after  $(now()-logger.starttime) from " * caller * ": " * message)
	end
	flush(logger.io)
	exit() 
    end
end

end

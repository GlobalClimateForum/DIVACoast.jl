using Logging
using Dates

export ExtendedLogger, logg

struct ExtendedLogger
    mylogger
    io
    starttime
end

function ExtendedLogger() 
  io = open(".jdiva_log", "w+")
  ExtendedLogger(SimpleLogger(io),io,now())
end 

function logg(logger,command,caller1,caller2,message)
    if (command==Logging.Debug) 
	with_logger(logger.mylogger) do
	    @debug "\t$(now()) after  $(now()-logger.starttime) from " * caller2 * " in " * caller1 * ": " * message
	end
	flush(logger.io)
    end

    if (command==Logging.Info) 
	with_logger(logger.mylogger) do
	    @info "\t$(now()) after  $(now()-logger.starttime) from " * caller2 * " in " * caller1 * ": " * message
	end
	flush(logger.io)
    end

    if (command==Logging.Warn) 
	with_logger(logger.mylogger) do
	    @warn "\t$(now()) after  $(now()-logger.starttime) from " * caller2 * " in " * caller1 *  ": " * message
	end
	flush(logger.io)
    end

    if (command==Logging.Error) 
	with_logger(logger.mylogger) do
	    @error "\t$(now()) after  $(now()-logger.starttime) from " * caller2 * " in " * caller1 *  ": " * message
	    println("ERROR: $(now()) after  $(now()-logger.starttime) from " * caller2 * " in " * caller1 *  ": " * message)
	end
	flush(logger.io)
	exit() 
    end
end



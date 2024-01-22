using Logging
using Dates

export ExtendedLogger, logg

mutable struct ExtendedLogger
    mylogger::Base.CoreLogging.AbstractLogger
    logfile::String
    io
    starttime::DateTime

    function ExtendedLogger(logfile::String="")
        if logfile != ""
            io = open(".jdiva_log", "w+")
            y = new(SimpleLogger(io), logfile, io, now())
            finalizer(y) do x
                if (y.logfile != "")
                    close(y.io)
                end
            end
            return y
        else
			return new(NullLogger(), logfile, devnull, now())
        end
    end

end

function logg(logger, command, caller1, caller2, message)
    if (command == Logging.Debug && logger.logfile != "")
        with_logger(logger.mylogger) do
            @debug "\t$(now()) after  $(now()-logger.starttime) from " * caller2 * " in " * caller1 * ": " * message
        end
        flush(logger.io)
    end

    if (command == Logging.Info && logger.logfile != "")
        with_logger(logger.mylogger) do
            @info "\t$(now()) after  $(now()-logger.starttime) from " * caller2 * " in " * caller1 * ": " * message
        end
        flush(logger.io)
    end

    if (command == Logging.Warn && logger.logfile != "")
        with_logger(logger.mylogger) do
            @warn "\t$(now()) after  $(now()-logger.starttime) from " * caller2 * " in " * caller1 * ": " * message
        end
        flush(logger.io)
    end

    if (command == Logging.Error)
        if logger.logfile != ""
            with_logger(logger.mylogger) do
                @error "\t$(now()) after  $(now()-logger.starttime) from " * caller2 * " in " * caller1 * ": " * message
            end
            flush(logger.io)
        end
        println("ERROR: $(now()) after  $(now()-logger.starttime) from " * caller2 * " in " * caller1 * ": " * message)
        exit()
    end
end



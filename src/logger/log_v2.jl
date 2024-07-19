using Logging
using Dates

export DIVALogger, LogFunc, LogIter, set_loglvl!

# DIVA Logger struct
mutable struct DIVALogger <: Logging.AbstractLogger
    io::IO
    lvl::Logging.LogLevel
    msg_header::String
    stime::Dates.DateTime
end

## Constructor
DIVALogger() = DIVALogger(stderr,Logging.Info, "JDIVA", now())
DIVALogger(path::String) = DIVALogger(open(path, "w"), Logging.Info, "JDIVA", now())
DIVALogger(lvl::Logging.LogLevel) = DIVALogger(stderr, lvl , "JDIVA", now())

# Method to change the minimum loglevel of a DIVALogger
function set_loglvl!(level::Logging.LogLevel)
    if isa(global_logger(), DIVALogger)
        clogger = current_logger()
        global_logger(DIVALogger(clogger.io, level, clogger.msg_header, clogger.stime))
    else
        @error "Global Logger is not DIVALogger."
    end
end

## Disable min log level
Logging.min_enabled_level(logger::DIVALogger) = logger.lvl

# LogLevels
# -1000 Debug 
# 0     Info
# 1000  Warn
# 2000  Error

## Logger should log when called from Main Module and LogMsg Level is larger then set min lvl
function Logging.shouldlog(logger::DIVALogger, level, _module, group, id)
    return (_module == Main.jdiva || _module == Main) && level >= logger.lvl
end

## Logger should catch exceptions
Logging.catch_exceptions(logger::DIVALogger) = true

## DIVA Logger - Message Handler
function Logging.handle_message(logger::DIVALogger, lvl, msg, _mod, group, id, file, line; kwargs...)
    
    time = now()
    time_f = Dates.format(time, "HH:MM:SS")

    if haskey(kwargs, :caller)
        caller = kwargs[:caller]
        caller = Dict(:line => caller.line, :file => caller.file)
    else
        caller = Dict(:line => line, :file => file)
    end

#    if lvl != Logging.Info
        runtime = Dates.canonicalize(Dates.CompoundPeriod(Dates.DateTime(time) - Dates.DateTime(logger.stime)))
#    end

    if lvl == Logging.Info
        header = "$(logger.msg_header)|$lvl @$time_f(after $runtime) @line:$(caller[:line]) in file $(caller[:file])"
        color = :cyan
        bold = true
    elseif lvl == Logging.Debug
        header = "$(logger.msg_header)|$lvl @$time_f(after $runtime) @line:$(caller[:line]) in file $(caller[:file])"
        color = :green
        bold = true
    elseif lvl == Logging.Error
        header = "$(logger.msg_header)|$lvl @$time_f(after $runtime) @line:$(caller[:line]) in file $(caller[:file])"
        color = :red
        bold = true
    elseif lvl == Logging.Warn
        header = "$(logger.msg_header)|$lvl @$time_f(after $runtime) @line:$(caller[:line]) in file $(caller[:file])"
        color = :red
        bold = true
    else
        header = "$(logger.msg_header)|$lvl @$time_f($runtime):"
        color = :grey
        bold = false
    end

    if logger.io == stderr
        printstyled("[ $header: ", color=color, bold=bold)
        print("$msg\n")
    else
        write(logger.io, "[$header]  $msg\n")
        flush(logger.io)
    end
end

# Wrapper Structures for Logging

## Function Logging
struct LogFunc{F}
    func::F
end

function LogFunc(func::F, args...; logLevel=nothing, kwargs...) where {F}
    
    # Check if global logger is a DIVA logger and retrieve logging level
    if isa(global_logger(), DIVALogger)
        lvl = isnothing(logLevel) ? current_logger().lvl : logLevel
    else
        @error "LogFunc() is only available when global logger is type of DIVALogger."
        return
    end

    trace = stacktrace()
    # lvl = isnothing(logLevel) ? DIVALogger.lvl : logLevel
    fname = String(Symbol(func))
    @logmsg lvl "$(fname)(args$args, kwargs$kwargs) called." caller = trace[3]
    result = func(args...; kwargs...)  # Call the function with args and kwargs
    @logmsg lvl "$(fname)(args$args, kwargs$kwargs) finished." caller = trace[3]
    return result
end

## Iteration Logging
mutable struct LogIter{T}
    iter::T
    name::String
    step_width::Int
    lvl::Logging.LogLevel
    step::Int
end

LogIter(I, n::String) = LogIter(I, n, 1, Logging.Info, 1)
LogIter(I, n::String, w::Integer) = LogIter(I, n, w, Logging.Info, 1)
LogIter(I, n::String, w::Integer, lvl::Logging.LogLevel) = LogIter(I, n, w, lvl, 1)

function Base.iterate(iter::LogIter, state...)
    trace = stacktrace()
    next = isempty(state) ? iterate(iter.iter) : iterate(iter.iter, state...)
    if next !== nothing
        (val, new_state) = next
        if mod(iter.step, iter.step_width) == 0 || iter.step == 1
            @logmsg iter.lvl "Iteration '$(iter.name)' @[$(iter.step)]" caller = trace[3]
        end
        iter.step = iter.step + 1
        return (val, new_state)
    else
        @logmsg iter.lvl "Iteration '$(iter.name)' ended." caller = trace[3]
    end
end
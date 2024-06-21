using Logging
using Dates


struct DIVALogger <: Logging.AbstractLogger
    io::IO
    msg_header::String
end

# Empty Constructor
DIVALogger() = DIVALogger(stderr, "JDIVA")

# Disable min log level
Logging.min_enabled_level(logger::DIVALogger) = Logging.BelowMinLevel

# Logger should always log
function Logging.shouldlog(logger::DIVALogger, level, _module, group, id)
    return true
end

# Logger should catch exceptions
Logging.catch_exceptions(logger::DIVALogger) = true

# DIVA Logger - Message Handler
function Logging.handle_message(logger::DIVALogger, lvl, msg, _mod, group, id, file, line; kwargs...)
    time = Dates.format(now(), "HH:MM:SS")

    if lvl == Logging.Info
        header = "[ $(logger.msg_header)|$lvl @$time : "
        color = :cyan
        bold = true
    elseif lvl == Logging.Debug
        header = "[ $(logger.msg_header)|$lvl @$time @line:$line in file $(group).jl: "
        color = :green
        bold = true
    elseif lvl == Logging.Error
        header = "[ $(logger.msg_header)|$lvl @$time @line:$line in file $(group).jl: "
        color = :red
        bold = true
    elseif lvl == Logging.Warn
        header = "[ $(logger.msg_header)|$lvl @$time @line:$line in file $(group).jl: "
        color = :red
        bold = true
    else 
        header = "$(logger.msg_header)|$lvl @$time : "
        color = :grey 
        bold = false
    end
    printstyled("$header", color=color, bold=bold)
    print("$msg\n")
end

# Function Logging
struct LogFunc{F}
    func::F
end

function LogFunc(func::F,args...; logLevel = nothing, kwargs...) where {F}
    lvl = isnothing(logLevel) ? Logging.Info : logLevel
    fname = String(Symbol(func))
    @logmsg lvl "$(fname)(args$args, kwargs$kwargs) called."
    result = func(args...; kwargs...)  # Call the function with args and kwargs
    @logmsg lvl "$(fname)(args$args, kwargs$kwargs) finished"
    return result
end

# Iteration Logging
mutable struct LogIter{T}
    iter::T
    name::String
    step_width::Int
    lvl::Logging.LogLevel
    step::Int
end

LogIter(I, n::String) = LogIter(I, n, 1, Logging.Info, 1)
LogIter(I, n::String, w::Integer) = LogIter(I, n, w, Logging.Info,  1)
LogIter(I, n::String, w::Integer, lvl::Logging.LogLevel) = LogIter(I, n, w, lvl,  1)

function Base.iterate(iter::LogIter, state...)
    next = isempty(state) ? iterate(iter.iter) : iterate(iter.iter, state...)
    if next !== nothing
        (val, new_state) = next
        if mod(iter.step, iter.step_width) == 0 || iter.step == 1
            @logmsg iter.lvl "Iteration '$(iter.name)' @[$(iter.step)]"
        end
        iter.step = iter.step + 1
        return (val, new_state)
    else
        @logmsg iter.lvl "Iteration '$(iter.name)' ended."
    end
end


# Main
# global_logger(DIVALogger())

function testfunction(from::Int, to::Int)
    return "SECRET"
end


for i in LogIter(1:100000, "random Vector", 10000)
end

LogFunc(testfunction, 1, 100, logLevel = Logging.Debug)

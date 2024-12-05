using JLD2
using FileIO  # For splitext

export jld_load

function jld_load(path::Union{String, IO}, load_func::Union{Function, DataType}, load_args::Vector{Any} = [])
    filebase, _ = splitext(path)
    jldpath = "$filebase.jld2"

    if isfile(jldpath)
        return JLD2.load(jldpath, "data")
    elseif isempty(load_args)
        load = load_func(path)
        @save jldpath data=load
        return load
    else
        load = load_func(path, load_args...)
        @save jldpath data=load
        return load
    end
end

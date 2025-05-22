using JLD2
using Dates
export save, load
include("../nc/HSPs_nc_load.jl")


# Define a union type for the allowed DIVA types
const DIVACoastTypes = Union{HypsometricProfile, ComposedImpactModel, LocalCoastalImpactModel}
const DIVACoastLoadFuncs = Union{typeof(load_hsps_nc)}

function save(object::Type{T}, path::Union{String, IO}) where {T<:DIVACoastTypes}
    metadata = Dict(
        "created" => string(Dates.now()),
        "DIVACoastType" => typeof(object),
        "author" => "DIVACoast.jl"
    )
    jldsave(path; data=object, meta=metadata)
    @info "Saved $(metadata["DIVACoastType"]) to $path"
end


function load(path::Union{String, IO}, ::Type{T}) where {T<:DIVACoastTypes}
    if isfile(path) && endswith(path, ".jld2")
        data = JLD2.load(path, "data")
        metadata = JLD2.load(path, "meta")
        if metadata["DIVACoastType"] == T
            @info "Loaded $(T) created at $(metadata["created"])"
            return data
        else
            error("The file you are trying to load is not a $(T) file.")
        end
    else
        error("File $path does not exist or is not a .jld2 file.")
    end
end

function load(path::Union{String, IO}, load_func::F, load_args::A = []) where {F<:DIVACoastLoadFuncs, A<:Tuple}

    filebase, _  = splitext(path)
    jldpath = "$filebase.jld2"

    if isfile(jldpath)
        data= JLD2.load(jldpath, "data")
        metadata = JLD2.load(jldpath, "meta")
        @info "Loaded $(metadata["DIVACoastType"]) created at $(metadata["created"])"
        return data

    elseif isempty(load_args)
        data = load_func(path)
        metadata = Dict(
            "created" => string(Dates.now()),
            "DIVACoastType" => typeof(data), 
            "author" => "DIVACoast.jl"
        )
        JLD2.save(jldpath; data=data, meta=metadata)
        @info "Saved $(metadata["DIVACoastType"]) to $jldpath"
        return data
    
    elseif !isempty(load_args)
        data = load_func(load_args ..., path) 
        metadata = Dict(
            "created" => string(Dates.now()), 
            "DIVACoastType" => typeof(data), 
            "author" => "DIVACoast.jl"
        )
        JLD2.save(jldpath; data=data, meta=metadata)
        @info "Saved $(metadata["DIVACoastType"]) to $jldpath"
        return data
    end
end



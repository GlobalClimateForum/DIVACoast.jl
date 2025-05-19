using JLD2
using Dates
export save

function save(hpf::Union{HypsometricProfile, Dict}, path::Union{String, IO})
    metadata = Dict(
        "created" => string(Dates.now()),
        "DIVACoastType" => "HypsometricProfile",
        "author" => "DIVACoast.jl"
    )
    jldsave(path; data=hpf, meta=metadata)
    @info "Saved HypsometricProfile to $path"
end

# function jld_load(path::Union{String, IO}, load_func::Union{Function, DataType}, load_args::Vector{Any} = [])
#     filebase, _ = splitext(path)
#     jldpath = "$filebase.jld2"

#     if isfile(jldpath)
#         return JLD2.load(jldpath, "data")
#     elseif isempty(load_args)
#         load = load_func(path)
#         JLD2.@save jldpath data=load
#         return load
#     else
#         load = load_func(path, load_args...)
#         JLD2.@save jldpath data=load
#         return load
#     end
# end

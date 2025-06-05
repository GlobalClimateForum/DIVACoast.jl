using JLD2
using Dates
export save, load, load_hsps, load_local_coastal_impact_model, load_composed_impact_model


# Define a union type for the allowed DIVA types
const DIVACoastTypes = Union{HypsometricProfile, Dict{Int32, HypsometricProfile{Float32}},  ComposedImpactModel, LocalCoastalImpactModel}
const DIVACoastLoadFuncs = Union{typeof(load_hsps_nc)}

"""
        function save(object::T, path::Union{String, IO}) where {T<:DIVACoastTypes}

Saves a DIVACoast object to a JLD2 file. Currently acceptes `HypsometricProfile`, `Dict{Int32, HypsometricProfile{Float32}}`, `ComposedImpactModel`, and `LocalCoastalImpactModel`.
The file will be saved with metadata including the creation date, type of object, and author (DIVACoast).

# Arguments: 
- `object::T`: The DIVACoast object to save.
- `path::Union{String, IO}`: The path or IO stream where the object should be saved.

# Returns:
- `Nothing`: The function does not return a value, but saves the object to the specified path.

# Example:
```julia
hp1 = HypsometricProfile(...)
save(hp1, "path/to/hp1.jld2")
```
"""
function save(object::T, path::Union{String, IO}) where {T<:DIVACoastTypes}
    metadata = Dict(
        "created" => string(Dates.now()),
        "DIVACoastType" => typeof(object),
        "author" => "DIVACoast.jl"
    )
    if typeof(object) == Dict{Number, Any}
        jldopen(path, "a+") do file
            file["meta"] = metadata
            for (key, value) in keys(object)
                file[key] = value
            end
        end
    end
    jldsave(path; data=object, meta=metadata)
    @info "Saved $(metadata["DIVACoastType"]) to $path"
end


"""
        function load(path::Union{String, IO}, ::Type{T}) where {T<:DIVACoastTypes}

Loads a DIVACoast object from a JLD2 file created by the `save` function. 

# Arguments:
- `path ::Union{String, IO}`: The path or IO stream from which to load the object.
- `::Type{T}`: The type of the object to load, which must be one of the defined DIVACoast types (`HypsometricProfile`, `ComposedImpactModel`, `LocalCoastalImpactModel`).

# Returns:
- `data`: The loaded DIVACoast object of type `T`.

# Example:
```julia
hp = load("path/to/hp1.jld2", HypsometricProfile)
```
"""
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


"""
        load(path::Union{String, IO}, load_func::F, load_args::A = []) where {F<:DIVACoastLoadFuncs, A<:Tuple}

Loads a DIVACoast object using a specified loading function and saves it to a JLD2 file to load it directly from JLD2 in the future. 
# Arguments:
- `path::Union{String, IO}`: The path or IO stream from which to load the object.
- `load_func::F`: The function to use for loading the object, which must be one of the defined DIVACoast load functions (`load_hsps_nc`).
- `load_args::A = []`: Optional arguments to pass to the loading function.

# Returns:
- `data`: The loaded DIVACoast object.

# Example:
```julia
hp = load("path/to/hp1.nc", load_hsps_nc, (Int32, Float32)) # Load it using the load_hsps_nc function and save it to JLD2
hp = load("path/to/hp1.nc", load_hsps_nc, (Int32, Float32)) # Will load it from JLD2
```
"""
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
        save(data, jldpath)
        return data
    
    elseif !isempty(load_args)
        data = load_func(load_args ..., path)
        save(data, jldpath)
        return data
    end
end

# Type specific load function aliases
"""
    load_hsps(path::String)

Loads a HypsometricProfile from a JLD2 file. This function is an alias for `load(path, HypsometricProfile)`.

# Arguments: 
- `path::String`: The path to the JLD2 file containing the HypsometricProfile.

# Returns:
- `HypsometricProfile`: The loaded HypsometricProfile object.
"""
load_hsps(path::String) = load(path, HypsometricProfile)


"""
    load_local_coastal_impact_model(path::String)
Loads a LocalCoastalImpactModel from a JLD2 file. This function is an alias for `load(path, LocalCoastalImpactModel)`.

# Arguments:
- `path::String`: The path to the JLD2 file containing the LocalCoastalImpactModel.

# Returns:
- `LocalCoastalImpactModel`: The loaded LocalCoastalImpactModel object.
"""
load_local_coastal_impact_model(path::String) = load(path, LocalCoastalImpactModel)

"""
    load_composed_impact_model(path::String)
Loads a ComposedImpactModel from a JLD2 file. This function is an alias for `load(path, ComposedImpactModel)`.

# Arguments:
- `path::String`: The path to the JLD2 file containing the ComposedImpactModel.
# Returns:
- `ComposedImpactModel`: The loaded ComposedImpactModel object.
"""
load_composed_impact_model(path::String) = load(path, ComposedImpactModel)



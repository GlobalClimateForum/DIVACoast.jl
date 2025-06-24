"""
    HypsometricProfileCollection(profileMap::Dict{KEYT, HypsometricProfile{Float32}}) where KEYT <: Union{String, Int32}
A `HypsometricProfileCollection` wraps a collection of `HypsometricProfile` objects, allowing for easy management and access to multiple hypsometric profiles.
It is initialized with a dictionary mapping keys (either `String` or `Int32`) to `HypsometricProfile{Float32}` objects.
It provides methods to iterate over the profiles, access them by index or key, and convert the collection to a dictionary or a single `HypsometricProfile`.
"""
mutable struct HypsometricProfileCollection
    profiles::Vector{HypsometricProfile}
    ids::Vector{String}

    function HypsometricProfileCollection(profileMap::Dict{KEYT, HypsometricProfile{Float32}}) where KEYT <: Union{String, Int32}
        ids = [string(k) for k in keys(profileMap)]
        profiles = collect(values(profileMap))
        return new(profiles, ids)
    end
end

function Base.convert(::Type{HypsometricProfile}, hspc::HypsometricProfileCollection)
    return sum(hspc.profiles)
end

function HypsometricProfile(hpc::HypsometricProfileCollection)
    return convert(HypsometricProfile, hpc)
end


function Base.iterate(hpc::HypsometricProfileCollection, state=1)
    if state > length(hpc.profiles)
        return nothing
    end
    return (hpc.profiles[state], state + 1)
end

function Base.getindex(hpc::HypsometricProfileCollection, key::Int)
    if key < 1 || key > length(hpc.profiles)
        throw(BoundsError(hpc, key))
    end
    return hpc.profiles[key]
end

function Base.getindex(hpc::HypsometricProfileCollection, key::String)
    idx = findfirst(==(key), hpc.ids)
    if isnothing(idx)
        throw(KeyError(key))
    end
    return hpc.profiles[idx]
end

function Base.getindex(hpc::HypsometricProfileCollection, range::AbstractRange)
    return hpc.profiles[range]
end

function Base.display(io, hpc::HypsometricProfileCollection)
    basestr = ""
    basestr *= "┌ HypsometricProfileCollection\n"
    basestr *= "└ Number of HypsometricProfiles: $(length(hpc.profiles))\n"
    println(basestr)
end

function Base.convert(::Type{Dict}, hpc::HypsometricProfileCollection)
    return Dict{String, HypsometricProfile}(hpc.ids[i] => hpc.profiles[i] for i in 1:length(hpc.profiles))
end


function Base.map(f, hpc::HypsometricProfileCollection)
    return map(f, hpc.profiles)
end

function Base.broadcast(f, hpc::HypsometricProfileCollection)
    return map(f, hpc.profiles)
end

function Base.keys(hpc::HypsometricProfileCollection)
    return hpc.ids
end

function Base.values(hpc::HypsometricProfileCollection)
    return hpc.profiles
end

function Base.length(hpc::HypsometricProfileCollection)
    return length(hpc.profiles)
end
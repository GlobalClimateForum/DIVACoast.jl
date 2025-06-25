using Plots
using DataStructures
include("./kernels.jl")
include("./test_profile.jl")

@kwdef struct FloodProfile{T}
    
    elevation::Matrix{T}
    width::Int
    height::Int
    kernel::Kernel
    seavalue::T where T <: Union{Number, Symbol} = :sea

    exposures::Vector = []

    function FloodProfile(elevation::Matrix{T}) where T
        return new{T}(elevation, size(elevation, 2), size(elevation, 1), Neighbour8(), :sea, [reduce(hcat, assets)])
    end
end
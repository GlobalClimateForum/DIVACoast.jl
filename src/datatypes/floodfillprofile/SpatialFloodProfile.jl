using Plots
using DataStructures
include("./kernels.jl")
include("./test_profile.jl")

struct SpatialFloodProfile{T}
    elevation::Matrix{T}
    width::Int
    height::Int
    kernel::Kernel
    seavalue::T
    seed::CartesianIndex{2}
    exposures::Vector{Matrix{T}}
end

function SpatialFloodProfile(
    elevation::Matrix{T};
    kernel::Kernel=Neighbour8(),
    seavalue::T=zero(T),
    seed::CartesianIndex{2}=CartesianIndex(1, 1),
    exposures::Vector=Vector{Any}()) where T
    width = size(elevation, 2)
    height = size(elevation, 1)
    return SpatialFloodProfile{T}(elevation, width, height, kernel, seavalue, seed, exposures)
end
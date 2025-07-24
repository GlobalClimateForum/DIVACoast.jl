using GeoArrays
using StaticArrays

# Coordinates and indices
struct UpperLeft <: GeoArrays.AbstractStrategy
    offset::Float64
    UpperLeft() = new(1.0)
end
struct LowerRight <: GeoArrays.AbstractStrategy
    offset::Float64
    LowerRight() = new(0.0)
end


abstract type AbstractDirection end
struct East <: AbstractDirection
    step :: StaticArrays.SVector{2}
    East() = new(StaticArrays.SVector{2}(1.0,0.0))
end
struct West <: AbstractDirection
    step :: StaticArrays.SVector{2}
    West() = new(StaticArrays.SVector{2}(-1.0,0.0))
end
struct North <: AbstractDirection
    step :: StaticArrays.SVector{2}
    North() = new(StaticArrays.SVector{2}(0.0,1.0))
end
struct South <: AbstractDirection
    step :: StaticArrays.SVector{2}
    South() = new(StaticArrays.SVector{2}(0.0,-1.0))
end
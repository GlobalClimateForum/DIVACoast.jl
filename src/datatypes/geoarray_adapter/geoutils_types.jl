using GeoArrays

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
    step :: SVector{2}
    East() = new(SVector{2}(1.0,0.0))
end
struct West <: AbstractDirection
    step :: SVector{2}
    West() = new(SVector{2}(-1.0,0.0))
end
struct North <: AbstractDirection
    step :: SVector{2}
    North() = new(SVector{2}(0.0,1.0))
end
struct South <: AbstractDirection
    step :: SVector{2}
    South() = new(SVector{2}(0.0,-1.0))
end
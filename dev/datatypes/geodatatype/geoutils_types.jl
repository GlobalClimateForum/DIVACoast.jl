# Coordinates and indices
abstract type AbstractStrategy end
struct Center <: AbstractStrategy
    offset :: SVector{2}
    Center() = new(SVector{2}(0.5,0.5))
end
struct UpperLeft <: AbstractStrategy
    offset :: SVector{2}
    UpperLeft() = new(SVector{2}(0.0,0.0))
end
struct UpperRight <: AbstractStrategy
    offset :: SVector{2}
    UpperRight() = new(SVector{2}(1.0,0.0))
end
struct LowerLeft <: AbstractStrategy
    offset :: SVector{2}
    LowerLeft() = new(SVector{2}(0.0,1.0))
end
struct LowerRight <: AbstractStrategy
    offset :: SVector{2}
    LowerRight() = new(SVector{2}(1.0,1.0))
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
abstract type Kernel
end

@kwdef struct Neighbour8 <: Kernel
    up::Tuple{Int, Int} = (-1, 0)      # up
    down::Tuple{Int, Int} = (1, 0)     # down   
    left::Tuple{Int, Int} = (0, -1)    # left
    right::Tuple{Int, Int} = (0, 1)    # right      
    upleft::Tuple{Int, Int} = (-1, -1)  # up_left
    upright::Tuple{Int, Int} = (-1, 1)   # up_right
    downleft::Tuple{Int, Int} = (1, -1)  # down_left
    downright::Tuple{Int, Int} = (1, 1)  # down_right
end

@kwdef struct Neighbour4 <: Kernel
    up::Tuple{Int, Int} = (-1, 0)      # up
    down::Tuple{Int, Int} = (1, 0)     # down   
    left::Tuple{Int, Int} = (0, -1)    # left
    right::Tuple{Int, Int} = (0, 1)    # right      
end

function getNBS(m::Matrix, at::CartesianIndex{2}; nb::Kernel = Neighbour8())
    get = (position) -> begin
        new_pos = at .+ CartesianIndex(getfield(nb, position))
        checkbounds(Bool, m, new_pos) ? new_pos : nothing
    end
    return NamedTuple(npos => get(npos) for npos in fieldnames(typeof(nb)))
end

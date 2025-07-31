using Distances


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



function neighbours(m::T, at::CartesianIndex{2}; nb::Kernel = Neighbour8(), returndist = false) where T <: AbstractArray

    get = (position) -> begin
        new_pos = at .+ CartesianIndex(getfield(nb, position))
        checkbounds(Bool, m, new_pos) ? new_pos : nothing
    end

    get_distance = (position) -> begin
        
        new_pos = at .+ CartesianIndex(getfield(nb, position))

        if m isa GeoArrays.GeoArray && checkbounds(Bool, m.A, new_pos)


            lon1, lat1 = GeoArrays.coords(m, at)
            lon2, lat2 = GeoArrays.coords(m, new_pos)

            # Check wether the GeoArray is projected or geographic and choose the appropiate distance function
            projected_ = occursin("PROJCS", string(m.crs)) || !occursin("GEOGCS", string(m.crs))
            dist_ = projected_ ? Distances.euclidean((lon1, lat1), (lon2, lat2)) : distance(lon1, lat1, lon2, lat2) * 1000
            return new_pos, dist_
        
        elseif !(m isa GeoArrays.GeoArray) && checkbounds(Bool, m, new_pos)

            dist_ = √(sum((abs(new_pos[1] - at[1]), abs(new_pos[2] - at[2])) .^ 2))
            return new_pos, dist_
    
        else
            return nothing, nothing
        end
    end

    return NamedTuple(npos => (returndist ? get_distance(npos) : get(npos)) for npos in fieldnames(typeof(nb)))
end

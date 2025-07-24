struct GeoArrayIndexValueIterator{T,N,A<:AbstractArray{T,N}}
    ga::GeoArray{T,N,A}
end

Base.length(iter::GeoArrayIndexValueIterator) = length(iter.ga.A)
Base.eltype(iter::GeoArrayIndexValueIterator) = Tuple{typeof(keys(gas[1].A)),eltype(iter.ga)}

Base.iterate(iter::GeoArrayIndexValueIterator) = ((keys(iter.ga.A)[1], values(iter.ga.A)[1]), 1)
function Base.iterate(iter::GeoArrayIndexValueIterator, state)
    count = state + 1

    if count > length(iter)
        return nothing
    end

    return ((keys(iter.ga.A)[count], values(iter.ga.A)[count]), count)
end

# specialisation for GeoArray{DT, 2, SparseArrayDOK{DT, IT}} (taking advantage of the memory structure of SparseArrayDOK)
function Base.iterate(iter::GeoArrayIndexValueIterator{DT,2,SparseArrayDOK{DT,IT}}) where {DT,IT}
    if length(iter.ga.A.memory) == 0
        nothing
    else
        ((iterate(keys(iter.ga.A.memory))[1], iterate(values(iter.ga.A.memory))[1]), iterate(keys(iter.ga.A.memory))[2])
    end
end

function Base.iterate(iter::GeoArrayIndexValueIterator{DT,2,SparseArrayDOK{DT,IT}}, state) where {DT,IT}
    if iterate(keys(iter.ga.A.memory), state) == nothing
        # case of an empty memory
        return nothing
    end
    return ((iterate(keys(iter.ga.A.memory), state)[1], iterate(values(iter.ga.A.memory), state)[1]), iterate(keys(iter.ga.A.memory), state)[2])
end

# specialisation for GeoArray{DT, 2, SparseArrayADOC{DT, IT}} (taking advantage of the memory structure of SparseArrayADOC)
function Base.iterate(iter::GeoArrayIndexValueIterator{DT,2,SparseArrayADOC{DT,IT}}) where {DT,IT}
    for x in 1:size(iter.ga.A.memory)[1]
        for (y, v) in iter.ga.A.memory[x]
            return (((x, y), v), (x, iterate(keys(iter.ga.A.memory[x]))[2]))
        end
    end
    # case of an empty memory
    return nothing
end

function Base.iterate(iter::GeoArrayIndexValueIterator{DT,2,SparseArrayADOC{DT,IT}}, state) where {DT,IT}
    x = state[1]
    it = state[2]
    if iterate(keys(iter.ga.A.memory[x]), it) == nothing
        for xn in (x+1):size(iter.ga.A.memory)[1]
            for (y, v) in iter.ga.A.memory[xn]
                return (((xn, y), v), (xn, iterate(keys(iter.ga.A.memory[xn]))[2]))
            end
        end
        # case of an empty memory
        return nothing
    else
        return (((x, iterate(keys(iter.ga.A.memory[x]), it)[1]), iterate(values(iter.ga.A.memory[x]), it)[1]), (x, iterate(keys(iter.ga.A.memory[x]),it)[2]))
    end
end

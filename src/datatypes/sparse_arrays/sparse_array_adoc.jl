# SparseArray as array of dictionary of columns
mutable struct SparseArrayADOC{DT,IT} <: AbstractArray{DT,2}
    no_data::DT
    rows::Int
    columns::Int
    memory::Array{Dict{IT,DT}}
end

# Constructors
SparseArrayADOC{DT,IT}(nd::DT, r::Integer, c::Integer) where {DT,IT<:Integer} = SparseArrayADOC{DT,IT}(nd, r, c, [Dict{IT,DT}() for i in 1:r])
SparseArrayADOC{DT,IT}(nd::T, r::Integer, c::Integer) where {DT,IT<:Integer,T} = SparseArrayADOC{DT,IT}(convert(DT, nd), r, c, [Dict{IT,DT}() for i in 1:r])

Base.size(msa::SparseArrayADOC{DT,IT}) where {DT,IT} = (msa.rows, msa.columns)

@inline function Base.getindex(msa::SparseArrayADOC{DT,IT}, i::IT, j::IT)::DT where {DT,IT<:Integer}
    @boundscheck checkbounds(msa, i, j)
    if haskey(msa.memory[i], j)
        return msa.memory[i][j]
    else
        return msa.no_data
    end
end

@inline function Base.getindex(msa::SparseArrayADOC{DT,IT}, i::Int, j::Int)::DT where {DT,IT<:Integer}
    @boundscheck checkbounds(msa, i, j)
    if haskey(msa.memory[i], j)
        return msa.memory[i][j]
    else
        return msa.no_data
    end
end

@inline function Base.getindex(msa::SparseArrayADOC{DT,IT}, I::Vararg{Int,2})::DT where {DT,IT<:Integer}
    @boundscheck checkbounds(msa, I[1], I[2])
    if haskey(msa.memory[I[1]], I[2])
        return msa.memory[I[1]][I[2]]
    else
        return msa.no_data
    end
end

@inline function Base.getindex(msa::SparseArrayADOC{DT,IT}, xrange::AbstractRange, yrange::AbstractRange)::SparseArrayADOC{DT,IT} where {DT<:Real,IT<:Integer}
    memory::[Dict{IT,DT}() for i in 1:size(xrange)[1]]
    # choose the method that is faster for the given data
    for x in xrange
        for y in yrange
            v::DT = get(msa.memory[x], (y), msa.no_data)
            if (v != msa.no_data)
                memory[x-first(xrange)+1][y-first(yrange)+1] = v
            end
        end
    end
    SparseArrayADOC{DT,IT}(msa.no_data, size(xrange)[1], size(yrange)[1], memory)
end

@inline function Base.setindex!(msa::SparseArrayADOC{DT,IT}, v::DT, i::Int, j::Int) where {DT,IT<:Integer}
    @boundscheck checkbounds(msa, i, j)
    if v == msa.no_data && haskey(msa.memory[i], (convert(IT, j)))
        delete!(msa.memory[i], j)
    elseif v != msa.no_data
        msa.memory[i][convert(IT, j)] = v
    end
end

@inline function Base.setindex!(msa::SparseArrayADOC{DT,IT}, v::DT, i::IT, j::IT) where {DT,IT<:Integer}
    @boundscheck checkbounds(msa, i, j)
    if v == msa.no_data && haskey(msa.memory[i], (convert(IT, j)))
        delete!(msa.memory[i], j)
    elseif v != msa.no_data
        msa.memory[i][convert(IT, j)] = v
    end
end

@inline function Base.setindex!(msa::SparseArrayADOC{DT,IT}, v::T, i::Int, j::Int) where {DT,IT<:Integer,T}
    @boundscheck checkbounds(msa, i, j)
    if convert(DT, v) == msa.no_data && haskey(msa.memory[i], (convert(IT, j)))
        delete!(msa.memory[i], j)
    elseif v != msa.no_data
        msa.memory[i][(convert(IT, j))] = convert(DT, v)
    end
end

function crop!(msa::SparseArrayADOC{DT,IT}; min_x::Integer, min_y::Integer, max_x::Integer, max_y::Integer) where {DT,IT<:Integer}
    if max_x < min_x
        min_x, max_x = max_x, min_x
    end
    if max_y < min_y
        min_y, max_y = max_y, min_y
    end

    mem = [Dict{IT,DT}() for i in 1:(max_x-min_x+1)]
    for x in min_x:max_x
        for (ind, value) in msa.memory[x]
            if (ind >= min_y) && (ind <= max_y)
                mem[x-min_x+1][ind-min_y+1] = value
            end
            delete!(msa.memory[x], ind)
        end
    end

    msa.rows = max_x - min_x + 1
    msa.columns = max_y - min_y + 1
    msa.memory = mem
end

function clear_data!(msa::SparseArrayADOC{DT,IT}) where {DT,IT<:Integer}
    # does not make sence for usual Array - thus does not do anything
    for i in 1:size(msa.memory)[1]
        msa.memory[i] = Dict()
    end
end















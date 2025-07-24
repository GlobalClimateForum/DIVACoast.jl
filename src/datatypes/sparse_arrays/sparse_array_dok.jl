# SparseArray as dictionary of keys
mutable struct SparseArrayDOK{DT,IT} <: AbstractArray{DT,2}
    no_data::DT
    rows::Int
    columns::Int
    memory::Dict{Tuple{IT,IT},DT}
end

# Constructors
SparseArrayDOK{DT,IT}(nd::DT, r::Integer, c::Integer) where {DT,IT<:Integer} = SparseArrayDOK{DT,IT}(nd, r, c, Dict{Tuple{IT,IT},DT}())
SparseArrayDOK{DT,IT}(nd::T, r::Integer, c::Integer) where {DT,IT<:Integer,T} = SparseArrayDOK{DT,IT}(convert(DT, nd), r, c, Dict{Tuple{IT,IT},DT}())

Base.size(msa::SparseArrayDOK{DT,IT}) where {DT,IT} = (msa.rows, msa.columns)

@inline function Base.getindex(msa::SparseArrayDOK{DT,IT}, i::IT, j::IT)::DT where {DT,IT<:Integer}
    @boundscheck checkbounds(msa, i, j)
    if haskey(msa.memory, (i, j))
        return msa.memory[(i, j)]
    else
        return msa.no_data
    end
end

@inline function Base.getindex(msa::SparseArrayDOK{DT,IT}, i::Int, j::Int)::DT where {DT,IT<:Integer}
    @boundscheck checkbounds(msa, i, j)
    if haskey(msa.memory, (i, j))
        return msa.memory[(i, j)]
    else
        return msa.no_data
    end
end

@inline function Base.getindex(msa::SparseArrayDOK{DT,IT}, I::Vararg{Int,2})::DT where {DT,IT<:Integer}
    @boundscheck checkbounds(msa, I[1], I[2])
    if haskey(msa.memory, (I[1], I[2]))
        return msa.memory[(I[1], I[2])]
    else
        return msa.no_data
    end
end

@inline function Base.getindex(msa::SparseArrayDOK{DT,IT}, xrange::AbstractRange, yrange::AbstractRange)::SparseArrayDOK{DT,IT} where {DT<:Real,IT<:Integer}
    memory::Dict{Tuple{IT,IT},DT} = Dict{Tuple{IT,IT},DT}()
    # choose the method that is faster for the given data
    if (size(xrange)[1] * size(yrange)[1] < length(msa.memory))
        for y in yrange
            for x in xrange
                v::DT = get(msa.memory, (x, y), msa.no_data)
                if (v != msa.no_data)
                    memory[(x - first(xrange) + 1, y - first(yrange) + 1)] = v
                end
            end
        end
    else
        for (ind, v) in msa.memory
            if (first(xrange) < ind[1] && ind[1] < last(xrange) && first(yrange) < ind[2] && ind[2] < last(yrange))
                memory[(ind[1] - first(xrange) + 1, ind[2] - first(yrange) + 1)] = v
            end
        end
    end
    SparseArrayDOK{DT,IT}(msa.no_data, size(xrange)[1], size(yrange)[1], memory)
end

@inline function Base.setindex!(msa::SparseArrayDOK{DT,IT}, v::DT, i::Int, j::Int) where {DT,IT<:Integer}
    @boundscheck checkbounds(msa, i, j)
    if v == msa.no_data && haskey(msa.memory, (convert(IT, i), convert(IT, j)))
        delete!(msa.memory, (convert(IT, i), convert(IT, j)))
    elseif v != msa.no_data
        msa.memory[(convert(IT, i), convert(IT, j))] = v
    end
end

@inline function Base.setindex!(msa::SparseArrayDOK{DT,IT}, v::T, i::Int, j::Int) where {DT,IT<:Integer,T}
    @boundscheck checkbounds(msa, i, j)
    if convert(DT, v) == msa.no_data && haskey(msa.memory, (convert(IT, i), convert(IT, j)))
        delete!(msa.memory, (convert(IT, i), convert(IT, j)))
    elseif v != msa.no_data
        msa.memory[(convert(IT, i), convert(IT, j))] = convert(DT, v)
    end
end


function crop!(msa::SparseArrayDOK{DT,IT}; min_x::Integer, min_y::Integer, max_x::Integer, max_y::Integer) where {DT,IT<:Integer}
    if max_x < min_x
        min_x, max_x = max_x, min_x
    end
    if max_y < min_y
        min_y, max_y = max_y, min_y
    end

    mem::Dict{Tuple{IT,IT},DT} = Dict{Tuple{IT,IT},DT}()
    for (indices, value) in msa.memory
        if !(((indices[1] < min_x) || (indices[1] > max_x) || (indices[2] < min_y) || (indices[2] > max_y)))
            mem[(indices[1] - min_x + 1, indices[2] - min_y + 1)] = value
        end
        delete!(msa.memory, indices)
    end
    msa.rows = max_x - min_x + 1
    msa.columns = max_y - min_y + 1
    msa.memory = mem
end

function clear_data!(msa::SparseArrayDOK{DT,IT}) where {DT,IT<:Integer}
    msa.memory = Dict()
end
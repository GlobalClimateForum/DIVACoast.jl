# SparseArray as array of dictionary of columns
struct SparseArrayADOC{DT,IT} <: AbstractArray{DT,2}
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
                memory[x - first(xrange) + 1][y - first(yrange) + 1] = v
            end
        end
    end
    SparseArrayADOC{DT,IT}(msa.no_data, size(xrange)[1], size(yrange)[1], memory)
end

@inline function Base.setindex!(msa::SparseArrayADOC{DT,IT}, v::DT, i::Int, j::Int) where {DT,IT<:Integer}
    @boundscheck checkbounds(msa, i, j)
    if v == msa.no_data
        delete!(msa.memory[i], j)
    else
        msa.memory[i][j] = v
    end
end

@inline function Base.setindex!(msa::SparseArrayADOC{DT,IT}, v::DT, i::IT, j::IT) where {DT,IT<:Integer}
    @boundscheck checkbounds(msa, i, j)
    if v == msa.no_data
        delete!(msa.memory[i], j)
    else
        msa.memory[i][j] = v
    end
end

@inline function Base.setindex!(msa::SparseArrayADOC{DT,IT}, v::T, i::Int, j::Int) where {DT,IT<:Integer,T}
    @boundscheck checkbounds(msa, i, j)
    if convert(DT, v) == msa.no_data
        delete!(msa.memory[i], j)
    else
        msa.memory[i][j] = convert(DT, v)
    end
end

@inline function Base.fill!(msa::SparseArrayADOC{DT,IT}, v::T) where {DT,IT<:Integer,T}

end
















# SparseArray as array of dictionary of columns
mutable struct SparseArrayADOR{DT,IT} <: AbstractArray{DT,2}
    no_data::DT
    rows::Int
    columns::Int
    memory::Array{Dict{IT,DT}}
end

# Constructors
SparseArrayADOR{DT,IT}(nd::DT, r::Integer, c::Integer) where {DT,IT<:Integer} = SparseArrayADOR{DT,IT}(nd, r, c, [Dict{IT,DT}() for i in 1:c])
SparseArrayADOR{DT,IT}(nd::T, r::Integer, c::Integer) where {DT,IT<:Integer,T} = SparseArrayADOR{DT,IT}(convert(DT, nd), r, c, [Dict{IT,DT}() for i in 1:c])

Base.size(msa::SparseArrayADOR{DT,IT}) where {DT,IT} = (msa.rows, msa.columns)

@inline function Base.getindex(msa::SparseArrayADOR{DT,IT}, i::IT, j::IT)::DT where {DT,IT<:Integer}
    @boundscheck checkbounds(msa, i, j)
    if haskey(msa.memory[j], i)
        return msa.memory[j][i]
    else
        return msa.no_data
    end
end

@inline function Base.getindex(msa::SparseArrayADOR{DT,IT}, i::Int, j::Int)::DT where {DT,IT<:Integer}
    @boundscheck checkbounds(msa, i, j)
    if haskey(msa.memory[j], i)
        return msa.memory[j][i]
    else
        return msa.no_data
    end
end

@inline function Base.getindex(msa::SparseArrayADOR{DT,IT}, I::Vararg{Int,2})::DT where {DT,IT<:Integer}
    @boundscheck checkbounds(msa, I[1], I[2])
    if haskey(msa.memory[I[2]], I[1])
        return msa.memory[I[2]][I[1]]
    else
        return msa.no_data
    end
end

@inline function Base.getindex(msa::SparseArrayADOR{DT,IT}, xrange::AbstractRange, yrange::AbstractRange)::SparseArrayADOR{DT,IT} where {DT<:Real,IT<:Integer}
    memory::[Dict{IT,DT}() for i in 1:size(yrange)[1]]
    # choose the method that is faster for the given data
    for x in xrange
        for y in yrange
            v::DT = get(msa.memory[y], (x), msa.no_data)
            if (v != msa.no_data)
                memory[y-first(yrange)+1][x-first(xrange)+1] = v
            end
        end
    end
    SparseArrayADOR{DT,IT}(msa.no_data, size(yrange)[1], size(xrange)[1], memory)
end

@inline function Base.setindex!(msa::SparseArrayADOR{DT,IT}, v::DT, i::Int, j::Int) where {DT,IT<:Integer}
    @boundscheck checkbounds(msa, i, j)
    if v == msa.no_data && haskey(msa.memory[j], (convert(IT, i)))
        delete!(msa.memory[j], i)
    elseif v != msa.no_data
        msa.memory[j][convert(IT, i)] = v
    end
end

@inline function Base.setindex!(msa::SparseArrayADOR{DT,IT}, v::DT, i::IT, j::IT) where {DT,IT<:Integer}
    @boundscheck checkbounds(msa, i, j)
    if v == msa.no_data && haskey(msa.memory[j], (convert(IT, i)))
        delete!(msa.memory[j], i)
    elseif v != msa.no_data
        msa.memory[j][convert(IT, i)] = v
    end
end

@inline function Base.setindex!(msa::SparseArrayADOR{DT,IT}, v::T, i::Int, j::Int) where {DT,IT<:Integer,T}
    @boundscheck checkbounds(msa, i, j)
    if convert(DT, v) == msa.no_data && haskey(msa.memory[j], (convert(IT, i)))
        delete!(msa.memory[j], i)
    elseif v != msa.no_data
        msa.memory[j][(convert(IT, i))] = convert(DT, v)
    end
end

function crop!(msa::SparseArrayADOR{DT,IT}; min_x::Integer, min_y::Integer, max_x::Integer, max_y::Integer) where {DT,IT<:Integer}
    if max_x < min_x
        min_x, max_x = max_x, min_x
    end
    if max_y < min_y
        min_y, max_y = max_y, min_y
    end

    mem = [Dict{IT,DT}() for i in 1:(max_y-min_y+1)]
    for y in min_y:max_y
        for (ind, value) in msa.memory[y]
            if (ind >= min_x) && (ind <= max_x)
                mem[y-min_y+1][ind-min_x+1] = value
            end
            delete!(msa.memory[y], ind)
        end
    end

    msa.rows = max_x - min_x + 1
    msa.columns = max_y - min_y + 1
    msa.memory = mem
end

function clear_data!(msa::SparseArrayADOR{DT,IT}) where {DT,IT<:Integer}
    # does not make sence for usual Array - thus does not do anything
    for i in 1:size(msa.memory)[1]
        msa.memory[i] = Dict()
    end
end


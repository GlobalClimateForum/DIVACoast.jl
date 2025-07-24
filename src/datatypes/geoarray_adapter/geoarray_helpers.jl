function find_min_x(a::Array{T}, ndv::T)::Integer where {T}
    for x in 1:size(a)[1]
        for y in 1:size(a)[2]
            if a[x, y] != ndv
                return x
            end
        end
    end
    size(a)[1]
end

function find_min_y(a::Array{T}, ndv::T)::Integer where {T}
    for y in 1:size(a)[2]
        for x in 1:size(a)[1]
            if a[x, y] != ndv
                return y
            end
        end
    end
    size(a)[2]
end

function find_max_x(a::Array{T}, ndv::T)::Integer where {T}
    for x in size(a)[1]:-1:1
        for y in 1:size(a)[2]
            if a[x, y] != ndv
                return x
            end
        end
    end
    1
end

function find_max_y(a::Array{T}, ndv::T)::Integer where {T}
    for y in size(a)[2]:-1:1
        for x in 1:size(a)[1]
            if a[x, y] != ndv
                return y
            end
        end
    end
    1
end

function extent(a::Array{T}, ndv::T) where {T}
    max_x = find_max_x(a, ndv)
    min_x = find_min_x(a, ndv)
    max_y = find_max_y(a, ndv)
    min_y = find_min_y(a, ndv)
    return min_x, min_y, max_x, max_y
end


function extent(a::SparseArrayDOK{DT,IT}, ndv::DT) where {DT,IT<:Integer}
    max_x = 1
    min_x = size(a)[1]
    max_y = 1
    min_y = size(a)[2]
    for (indices, value) in a.memory
        if (indices[1] < min_x)
            min_x = indices[1]
        end
        if (indices[1] > max_x)
            max_x = indices[1]
        end
        if (indices[2] < min_y)
            min_y = indices[2]
        end
        if (indices[2] > max_y)
            max_y = indices[2]
        end
    end
    return min_x, min_y, max_x, max_y
end


function extent(a::SparseArrayADOC{DT,IT}, ndv::DT) where {DT,IT<:Integer}
    max_x = 1
    min_x = size(a)[1]
    max_y = 1
    min_y = size(a)[2]
    for x in 1:size(a)[1]
        if length(a.memory[x]) > 0
            min_x = x
            break
        end
    end

    for x in size(a)[1]:-1:1
        if length(a.memory[x]) > 0
            max_x = x
            break
        end
    end

    for i in 1:size(a)[1]
        for (ind,value) in a.memory[i]
            if (i < min_x)
                min_x = i
            end
            if (i > max_x)
                max_x = i
            end
            if (ind < min_y)
                min_y = ind
            end
            if (ind > max_y)
                max_y = ind
            end
        end
    end

    return min_x, min_y, max_x, max_y
end

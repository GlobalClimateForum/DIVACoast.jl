export extract_coastline, find_coastline, find_waterline

function find_coastline(sga::SparseGeoArray{DT,IT}, land_border_is_coastline :: Bool)::SparseGeoArray{DT,IT} where {DT<:Real,IT<:Integer}
    s = starting_point(sga)
    if s == (-1, -1)
        return boundary(sga)
    end

    ret = empty_copy(sga)
    curr = empty_copy(sga)
    last = empty_copy(sga)
    curr[s] = 1
    while (length(curr.data) > 0)
        propagate(sga, ret, curr, last)
    end
    println()

    if (land_border_is_coastline)
        merge!(ret.data,boundary(sga).data)
    end

    return ret
end

function find_waterline(sga::SparseGeoArray{DT,IT})::SparseGeoArray{DT,IT} where {DT<:Real,IT<:Integer}
    s = starting_point(sga)
    if s == (-1, -1)
        return boundary(sga)
    end

    ret = empty_copy(sga)
    curr = empty_copy(sga)
    last = empty_copy(sga)
    curr[s] = 1
    while (length(curr.data) > 0)
        propagate(sga, ret, curr, last, false)
    end
    println()

    return ret
end

function propagate(sga::SparseGeoArray{DT,IT}, ret::SparseGeoArray{DT,IT}, curr::SparseGeoArray{DT,IT}, last::SparseGeoArray{DT,IT}, coastline :: Bool = true) where {DT<:Real,IT<:Integer}
    next = empty_copy(curr)
    nh = Array{Tuple{IT,IT}}(undef, 8) 
    for d in curr.data
        n = nh8(curr, d[1], nh)
        for i in 1:n
            if sga[nh[i]] != sga.nodatavalue
                if (coastline)
                  ret[nh[i]] = sga[nh[i]]
                else
                  ret[d[1]] = 1
                end
                if (length(ret.data) % 10000 == 0) 
                    println("found points: $(length(ret.data))")
                end            
            elseif last[nh[i]] == last.nodatavalue && curr[nh[i]] == curr.nodatavalue
                next[nh[i]] = 1
            end
        end
    end
    clear_data!(last)
    last.data = copy(curr.data)
    clear_data!(curr)
    curr.data = next.data
end

function starting_point(sga::SparseGeoArray{DT,IT}) where {DT<:Real,IT<:Integer}
    for x in 1:size(sga, 1)
        if sga[x, 1] == sga.nodatavalue
            return (x, 1)
        end
        if sga[x, size(sga, 2)] == sga.nodatavalue
            return (x, size(sga, 2))
        end
    end
    for y in 1:size(sga, 2)
        if sga[1, y] == sga.nodatavalue
            return (1, y)
        end
        if sga[size(sga, 1), y] == sga.nodatavalue
            return (size(sga, 1), y)
        end
    end
    return (-1, -1)
end

function boundary(sga::SparseGeoArray{DT,IT})::SparseGeoArray{DT,IT} where {DT<:Real,IT<:Integer}
    r = empty_copy(sga)
    for x in 1:size(sga, 1)
        if (sga[x, 1]!=sga.nodatavalue) r[x, 1] = sga[x, 1] end
        if (sga[x, size(sga, 2)]!=sga.nodatavalue) r[x, size(sga, 2)] = sga[x, size(sga, 2)] end
    end
    for y in 1:size(sga, 2)
        if (sga[1,y]!=sga.nodatavalue) r[1, y] = sga[1, y] end
        if (sga[size(sga, 1), y]!=sga.nodatavalue) r[size(sga, 1), y] = sga[size(sga, 1), y] end
    end
    return r
end

function extract_coastline(sga::SparseGeoArray{DT,IT})::SparseGeoArray{DT,IT} where {DT<:Real,IT<:Integer}
    ret = empty_copy(sga)
    lf = 0

    nh = Array{Tuple{IT,IT}}(undef, 8) 
    for d in sga.data
        n = nh8(sga, d[1], nh)
        for i in 1:n
            if sga[nh[i]] == sga.nodatavalue
                ret[d[1]] = sga[d[1]]
                break
            end
        end
        if (length(ret.data) % 10000 == 0) && (lf < div(length(ret.data),10000))
            lf = div(length(ret.data),10000)
            println("found coastline points: $(length(ret.data))")
        end
    end

    return ret
end

function extract_coastline(sga::SparseGeoArray{DT,IT})::SparseGeoArray{DT,IT} where {DT<:Real,IT<:Integer}
    ret = empty_copy(sga)
    lf = 0

    nh = Array{Tuple{IT,IT}}(undef, 8) 
    for d in sga.data
        n = nh8(sga, d[1], nh)
        for i in 1:n
            if sga[nh[i]] == sga.nodatavalue
                ret[d[1]] = sga[d[1]]
                break
            end
        end
        if (length(ret.data) % 10000 == 0) && (lf < div(length(ret.data),10000))
            lf = div(length(ret.data),10000)
            println("found coastline points: $(length(ret.data))")
        end
    end

    return ret
end



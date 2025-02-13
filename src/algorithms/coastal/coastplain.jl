export extract_coastplain

using DataStructures

function extract_coastplain(sga_elevation::SparseGeoArray{DT,IT}, sga_coastline::SparseGeoArray{DT,IT}, el_threshold::DT)::SparseGeoArray{DT,IT} where {DT<:Real,IT<:Integer}
    for d in (sga_coastline.data)
        if d[2] > el_threshold
            delete!(sga_coastline.data, d[1])
        end
    end
    for d in (sga_elevation.data)
        if d[2] > el_threshold
            delete!(sga_elevation.data, d[1])
        end
    end

    ret = empty_copy(sga_elevation)
    sizehint!(ret.data, length(sga_elevation.data))

    p::Int = (length(sga_coastline.data) + length(sga_elevation.data)) ÷ 10000
    println("remaining points to check: $(length(sga_coastline.data) + length(sga_elevation.data))  coastplain points found: $(length(ret.data))")
    while (length(sga_coastline.data) > 0)
        if ((length(sga_coastline.data) + length(sga_elevation.data)) ÷ 10000) < p
            p = (length(sga_coastline.data) + length(sga_elevation.data)) ÷ 10000
            println("remaining points to check: $(length(sga_coastline.data) + length(sga_elevation.data))  coastplain points found: $(length(ret.data))")
        end
        propagate(first(sga_coastline.data), sga_elevation, sga_coastline, ret, el_threshold)
    end
    println()

    return ret
end

function extract_coastplain(sga_elevation::SparseGeoArray{DT,IT}, el_threshold::DT)::SparseGeoArray{DT,IT} where {DT<:Real,IT<:Integer}
    sga_coastline = find_coastline(sga_elevation)
    return extract_coastplain(sga_elevation, sga_coastline, el_threshold)
end

function propagate(sp, sga_elevation::SparseGeoArray{DT,IT}, sga_coastline::SparseGeoArray{DT,IT}, ret::SparseGeoArray{DT,IT}, el_threshold::DT) where {DT<:Real,IT<:Integer}
    curr = empty_copy(sga_elevation)
    sizehint!(curr.data, length(sga_elevation.data))

    p::Int = (length(sga_coastline.data) + length(sga_elevation.data)) ÷ 10000
    curr[sp[1]] = sp[2]
    nh = Array{Tuple{IT,IT}}(undef, 8)

    while (length(curr.data) > 0)
        if ((length(sga_coastline.data) + length(sga_elevation.data)) ÷ 10000) < p
            p = (length(sga_coastline.data) + length(sga_elevation.data)) ÷ 10000
            println("remaining points to check: $(length(sga_coastline.data) + length(sga_elevation.data)) ($(length(sga_coastline.data)) + $(length(sga_elevation.data)))  coastplain points found: $(length(ret.data))")
        end
        cp = first(curr.data)[1]
        n = nh8(sga_elevation, cp, nh)
        for i in 1:n
            if sga_elevation[nh[i]] != sga_elevation.nodatavalue
                curr[nh[i]] = 1
            else
                #delete!(sga_coastline.data, nh[i])
                delete!(sga_elevation.data, nh[i])
                #delete!(curr.data, nh[i])
            end
        end
        ret[cp] = sga_elevation[cp]
        delete!(curr.data, cp)
        delete!(sga_coastline.data, cp)
        delete!(sga_elevation.data, cp)
    end
end


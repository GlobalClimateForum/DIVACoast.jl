
# union : union of all values in sga1 and sga2 in a new sga
# result contains all data that is in sga1 OR sga2
# if a grid cell is present in both but with different values the value of sga1 should be used
# (thus union does not commute, we can have union(x,y)!=union(y,x)
# take into account different dimensions (coordinates, sizes adf transformation), we can reject sga's with different projections

function getExtent(sga)

    if !(typeof(sga) <: AbstractArray)
        sga = [sga]
    end

    sgaIndexExt = sga -> [(1,1), (size(sga)[1],1), (size(sga)[1], size(sga)[2]), (1, size(sga)[2])]
    sgaCoordExt = sga -> [coords(sga, corner) for corner in sgaIndexExt(sga)]
    unionExtent = reduce(vcat, [sgaCoordExt(s) for s in sga])
    xSorted = sort(unionExtent, by = first)
    ySorted = sort(unionExtent, by = last)
    return(
        uppL = (xSorted[1][1], ySorted[end][2]),
        uppR = (xSorted[end][1], ySorted[end][2]),
        lwrL = (xSorted[1][1], ySorted[1][2]),
        lwrR = (xSorted[end][1], ySorted[1][2])
    )
end

function sga_union(sga1::SparseGeoArray{DT, IT}, sga2::SparseGeoArray{DT, IT}) :: SparseGeoArray{DT, IT} where {DT <: Real, IT <: Integer}

    union = clearData(deepcopy(sga1))
    unionExtent = getExtent([sga1, sga2])
    xOffset = sga -> (indices(sga, unionExtent.uppL)[1] - 1) * -1
    yOffset = sga -> (indices(sga, unionExtent.uppL)[2] - 1) * -1

    println(sga1.f.translation)
    println(sga2.f.translation)

    t = SVector(0.0,0.0)
    l = union.f.linear * SMatrix{2,2}([1 0; 0 1])
    # union.xsize = ...
    # union.ysize = ...
    union.f = AffineMap(l, t)

    mapCoordinates = (sga, x, y) -> (x + xOffset(sga), y + yOffset(sga))
    
    unionSize = (maximum([xOffset(sga) + size(sga)[1] for sga in [sga1, sga2]]),
    maximum([yOffset(sga) + size(sga)[2] for sga in [sga1, sga2]])) # not required but might be useful later

    function translateValues(sga, union)
        for ((x,y), value) in sga.data
            (unionX, unionY) = mapCoordinates(sga, x, y)
            union[unionX, unionY] = value
        end
        return(union)
    end

    union = translateValues(sga1, union)
    union = translateValues(sga2, union)

    return union
end

# as before, but instead of constructing a new sga store the result in place in sga1 and delete all values from sga2 after they have been processed (one by one)

function sga_union!()
    print("test")
end


function sga_intersect(sga1::SparseGeoArray{DT, IT}, sga2::SparseGeoArray{DT, IT}) :: SparseGeoArray{DT, IT} where {DT <: Real, IT <: Integer}
    
    upperLeft -> sga -> getExtent(sga).uppL
    lowerRight -> sga -> getExtent(sga).lwrR 

    left = sort((upperLeft(sga1), upperLeft(sga2)), by = first) 
    right = sort((lowerRight(sga1), lowerRight(sga2)), by = first)
    bottom = sort((lowerRight(sga1), lowerRight(sga2)), by = last)



    println("left: $left, right: $right")
end


#function sga_union!(sga1::SparseGeoArray{DT, IT}, sga2::SparseGeoArray{DT, IT}) where {DT <: Real, IT <: Integer}

#end
# if bored: intersect, diff, sym_diff in the same way
#end
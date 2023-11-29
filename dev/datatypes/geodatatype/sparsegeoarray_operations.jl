
# union : union of all values in sga1 and sga2 in a new sga
# result contains all data that is in sga1 OR sga2
# if a grid cell is present in both but with different values the value of sga1 should be used
# (thus union does not commute, we can have union(x,y)!=union(y,x)
# take into account different dimensions (coordinates, sizes adf transformation), we can reject sga's with different projections
function emptySGAfromSGA(orgSGA, extentNew)
    newSGA = clearData(deepcopy(orgSGA))
    t = SVector(extentNew.uppL[1], extentNew.uppL[2])
    l = newSGA.f.linear * SMatrix{2,2}([1 0; 0 1])
    newSGA.xsize = round(abs(extentNew.uppL[1] - extentNew.uppR[1]) / abs(pixelsizex(orgSGA)), digits = 0)
    newSGA.ysize = round(abs(extentNew.uppL[2] - extentNew.lwrL[2]) / abs(pixelsizey(orgSGA)), digits = 0) 
    newSGA.f = AffineMap(l, t)
    return(newSGA)
end

function getExtent(sga)
    if !(typeof(sga) <: AbstractArray)
        sga = [sga]
    end
    sgaIndexExt = sga -> [(1,1),(size(sga)[1],1), (size(sga)[1], size(sga)[2]), (1, size(sga)[2])]
    sgaCoordExt = sga -> [coords(sga, corner, UpperLeft()) for corner in sgaIndexExt(sga)]
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

function sga_union(sgaArray::Array{SparseGeoArray{DT, IT}}) :: SparseGeoArray{DT, IT} where {DT <: Real, IT <: Integer}
    
    unionExtent = getExtent(sgaArray)
    xOffset = sga -> ((indices(sga, unionExtent.uppL)[1]) *-1) + 1
    yOffset = sga -> ((indices(sga, unionExtent.uppL)[2]) *-1) + 1
    unionSize = (maximum([xOffset(sga) + size(sga)[1] + 1 for sga in sgaArray]),
    maximum([yOffset(sga) + size(sga)[2] + 1 for sga in sgaArray]))

    # Create Union Object
    union = clearData(deepcopy(sgaArray[1]))
    t = SVector(unionExtent.uppL[1], unionExtent.uppL[2])
    l = union.f.linear * SMatrix{2,2}([1 0; 0 1])
    union.xsize = unionSize[1]
    union.ysize = unionSize[2]
    union.f = AffineMap(l, t)

    mapCoordinates = (sga, x, y) -> (x + xOffset(sga) , y + yOffset(sga))
    
    function translateValues(sga, union)
        for ((x,y), value) in sga.data
            (unionX, unionY) = mapCoordinates(sga, x, y)
            union[unionX, unionY] = value
        end
        return(union)
    end

    for sga in reverse(sgaArray) # if duplicate values, values of first array are set
        union = translateValues(sga, union)
    end

    return union
end

# as before, but instead of constructing a new sga store the result in place in sga1 and delete all values from sga2 after they have been processed (one by one)
function sga_union!()
    print("not implememted yet.")
end


function getOverlapExtent(sgaArray)
    maximumby = (arr, index) -> maximum(a -> a[index], arr)
    minimumby = (arr, index) -> minimum(a -> a[index], arr)
    ul = [coords(sga, [1,1], UpperLeft()) for sga in sgaArray]
    lr = [coords(sga, size(sga), UpperLeft()) for sga in sgaArray]
    maximumby = (arr, index) -> maximum(a -> a[index], arr)
    minimumby = (arr, index) -> minimum(a -> a[index], arr)
    return(
        uppL = (maximumby(ul, 1), minimumby(ul,2)),
        uppR = (minimumby(lr, 1), minimumby(ul,2)),
        lwrL = (maximumby(ul, 1), maximumby(lr,2)),
        lwrR = (minimumby(lr, 1), maximumby(lr,2))
    )
end

function sga_intersect(sgaArray::Array{SparseGeoArray{DT, IT}}) :: Array{SparseGeoArray{DT, IT}} where {DT <: Real, IT <: Integer}
    
    intersectExtent = getOverlapExtent(sgaArray)
    xOffset = sga -> abs((indices(sga, intersectExtent.uppL)[1])) 
    yOffset = sga -> abs((indices(sga, intersectExtent.uppL)[2]))
    mapCoordinates =  (sga, x, y) -> (x +  xOffset(sga), y + yOffset(sga))

    function translateValues(sga)

        newSGA = emptySGAfromSGA(sga, intersectExtent)

        for x in 1:newSGA.xsize
            for y in 1:newSGA.ysize
                (sgaX, sgaY) = mapCoordinates(sga, x, y)
                newSGA[x,y] = sga[sgaX, sgaY]
            end
        end

        return newSGA
    end

    return [translateValues(sga) for sga in sgaArray]
end


function sga_diff(sgaArray::Array{SparseGeoArray{DT, IT}}):: SparseGeoArray{DT, IT} where {DT <: Real, IT <: Integer}

    #diff = overlap - intersect
    overlapExtent = getExtent(sgaArray)


end

#function sga_union!(sga1::SparseGeoArray{DT, IT}, sga2::SparseGeoArray{DT, IT}) where {DT <: Real, IT <: Integer}

#end
# if bored:diff, sym_diff in the same way
#end

# create a radial Kernel Mask with a defined radius
function getRadialKernel(radius, pixelsizeX, pixelsizeY)
    indexSpanX = convert(Int32, round(radius / pixelsizeX, RoundNearest))
    indexSpanY = convert(Int32, round(radius / pixelsizeY, RoundNearest))
    kernel = falses(indexSpanX + 1, indexSpanY + 1)
    for x in 0:indexSpanX
       for y in 0:indexSpanY
           distance = sqrt(((x * pixelsizeX)^2) + ((y * pixelsizeY)^2))
           if distance <= radius
               kernel[x + 1, y + 1] = true
           end
       end
   end
   kernel = hcat([reverse(kernel, dims = (1,2)); reverse(kernel, dims = 2)], [reverse(kernel, dims = 1) ; kernel])
   #display(kernel)
   return(kernel)
end


# create a radial Kernel Mask with a defined radius
function get_radial_kernel(sga :: SparseGeoArray{DT, IT}, radius :: Real, lon_min :: Real, lon_max :: Real, lat_max  :: Real, lat_min :: Real) where {DT <: Real, IT <: Integer}
    indexSpanX = convert(Int32, round(radius / pixelsizeX, RoundNearest))
    indexSpanY = convert(Int32, round(radius / pixelsizeY, RoundNearest))
    kernel = falses(indexSpanX + 1, indexSpanY + 1)
    for x in 0:indexSpanX
       for y in 0:indexSpanY
           distance = sqrt(((x * pixelsizeX)^2) + ((y * pixelsizeY)^2))
           if distance <= radius
               kernel[x + 1, y + 1] = true
           end
       end
   end
   kernel = hcat([reverse(kernel, dims = (1,2)); reverse(kernel, dims = 2)], [reverse(kernel, dims = 1) ; kernel])
   #display(kernel)
   return(kernel)
end


# a function to get data within a defined radius (given in KM)
function sga_summarize_within(sga :: SparseGeoArray{DT, IT}, p :: Tuple{Real, Real}, radius :: Real, sumryFunction :: Function, valueTransformation) where {DT <: Real, IT <: Integer}
        
    if (radius>=earth_circumference_km/2) return sumryFunction(collect(values(sga.data))) end

    p_east = go_direction(p, radius, East())
    p_west = go_direction(p, radius, West())
    p_north = go_direction(p, radius, North())
    p_south = go_direction(p, radius, South())

    bb = bounding_boxes(sga, p_east[1],p_west[1],p_south[2],p_north[2])

    vals = Array{DT}(undef,0)
    for b in bb
      for b_x = b[1]:b[3]
        for b_y = b[2]:b[4]
          if (distance(Tuple(coords(sga::SparseGeoArray, (b_x, b_y), Center())), p) <= radius)
            if sga[b_x,b_y]!=sga.nodatavalue push!(vals,valueTransformation(sga,b_x,b_y)) end
          end
        end
      end
    end
    sumryFunction(vals)
end

sga_summarize_within(sga :: SparseGeoArray{DT, IT}, p :: Tuple{Real, Real}, radius :: Real, sumryFunction :: Function) where {DT <: Real, IT <: Integer} = sga_summarize_within(sga, p, radius, sumryFunction, (s,x,y) -> s[x,y])






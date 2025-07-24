using Statistics

"""
        get_total_extent(ga::GeoArray{E,N,C}) where {E,N,C}

Get the extent of a GeoArray as coordinates of its corners.

# Arguments
- `ga::GeoArray{E,N,C}`: The GeoArray for which the extent is to be calculated.

# Returns
- A named tuple with keys `uppL`, `uppR`, `lwrL`, and `lwrR` representing the upper left, upper right, lower left, and lower right corners of the extent.

# Example
```julia
extent = get_extent(ga)
```
"""
function get_total_extent(gas::Array{GeoArray{E,N,C}}) where {E,N,C}
    gas_coords_ext = map(ga -> [GeoArrays.coords(ga, (1, 1), UpperLeft()), GeoArrays.coords(ga, (size(ga)[1], 1), UpperLeft()), GeoArrays.coords(ga, (size(ga)[1], size(ga)[2]), UpperLeft()), GeoArrays.coords(ga, (1, size(ga)[2]), UpperLeft())], gas)
    union_extent = reduce(vcat, gas_coords_ext)
    x_sorted = sort(union_extent, by=first)
    y_sorted = sort(union_extent, by=last)
    return (
        ul=(x_sorted[1][1], y_sorted[end][2]),
        ur=(x_sorted[end][1], y_sorted[end][2]),
        ll=(x_sorted[1][1], y_sorted[1][2]),
        lr=(x_sorted[end][1], y_sorted[1][2])
    )
end

get_total_extent(ga::GeoArray{E,N,C}) where {E,N,C} = get_total_extent([ga])

"""
        geoarray_union(::Array{GeoArray{E,N,C}})::GeoArray{E,N,C} where {E,N,C}
        geoarray_union(sga1::SparseGeoArray{DT,IT}, sga2::SparseGeoArray{DT,IT}) where {DT<:Real,IT<:Integer}

Get the union of multiple `SparseGeoArray`s. The union is a new `GeoArray` that contains all data from the input arrays and fills 
the union extent defined by the input arrays. If a grid cell is present with a data value in multiple arrays, the value from the 
first array is used.

# Arguments
- `ga::GeoArray{E,N,C}`: An array of `GeoArray`s to be unioned.  

# Returns 
- A new `GeoArray{E,N,C}` that contains the union of the input `GeoArray`'s.

# Example 
```julia
union = geoarray_union([ga1, ga2, ga3])
``
"""
function geoarray_union(gas::Array{GeoArray{E,N,C}})::GeoArray{E,N,C} where {E,N,C}
    #function geoarray_union(gas::Array{GeoArray})::GeoArray

    if isempty(gas)
        @error "geoarray_union(): empty input array provided."
    end

    union_extent = get_total_extent(gas)
    println("union_extent = ", union_extent)

    x_offset = ga -> ((indices(ga, union_extent.ul)[1]) * -1) + 1
    y_offset = ga -> ((indices(ga, union_extent.ul)[2]) * -1) + 1

    union_xsize = convert(Int, round(abs(union_extent.ul[1] - union_extent.ur[1]) / abs(pixelsize_x(gas[1])), digits=0) + 1)
    union_ysize = convert(Int, round(abs(union_extent.ul[2] - union_extent.ll[2]) / abs(pixelsize_y(gas[1])), digits=0) + 1)

    # Create Union Object
    union = empty_copy_from_geo_array(gas[1], union_xsize, union_ysize, union_extent.ul, no_data_value(gas[1]))
    map_coordinates = (ga, x, y) -> (x + x_offset(ga), y + y_offset(ga))

    for ga in reverse(gas) # if duplicate values, values of first array are set
        for (ind, v) in GeoArrayIndexValueIterator(ga)
            (union_x, union_y) = map_coordinates(ga, ind[1], ind[2])
            if v != no_data_value(ga)
                union[union_x, union_y] = v
            end
        end
    end

    return union
end

geoarray_union(ga1, ga2) = geoarray_union([ga1, ga2])

# TODO: implement sga_union! function (mutating version of sga_union)
# as before, but instead of constructing a new ga store the result in place in ga1
# and delete all values from ga2 after they have been processed (one by one)



function get_overlap_extent(gas::Array{GeoArray{E,N,C}}) where {E,N,C}
    ul = [GeoArrays.coords(ga, [1, 1], UpperLeft()) for ga in gas]
    lr = [GeoArrays.coords(ga, size(ga), UpperLeft()) for ga in gas]
    maximum_by = (arr, index) -> maximum(a -> a[index], arr)
    minimum_by = (arr, index) -> minimum(a -> a[index], arr)
    return (
        ul=(maximum_by(ul, 1), minimum_by(ul, 2)),
        ur=(minimum_by(lr, 1), minimum_by(ul, 2)),
        ll=(maximum_by(ul, 1), maximum_by(lr, 2)),
        lr=(minimum_by(lr, 1), maximum_by(lr, 2))
    )
end

"""
        geoarray_intersect(gas::Array{GeoArray{E,N,C}})::GeoArray{E,N,C} where {E,N,C}

Get the intersection of multiple `GeoArray`s. The intersection is a new `GeoArray` that contains only the data that is present as data value 
in all input arrays, and fills the intersection extent defined by the input arrays. If for a grid cell a data value is present in multiple 
arrays, the value from the first array is used.

# Arguments
- `gas::Array{GeoArray{E,N,C}}`: An array of `GeoArray`s to be intersected.

# Returns
- An array of `GeoArray{E,N,C}` that represents the intersection of the input `GeoArray`s.

# Example 
```julia
intersection = geoarray_intersect([ga1, ga2, ga3])
````
"""
function geoarray_intersect(gas::Array{GeoArray{E,N,C}})::GeoArray{E,N,C} where {E,N,C}

    intersect_extent = get_overlap_extent(gas)
    x_offset = ga -> abs(GeoArrays.indices(ga, intersect_extent.ul, UpperLeft())[1]-1)
    y_offset = ga -> abs(GeoArrays.indices(ga, intersect_extent.ul, UpperLeft())[2]-1)
    map_coordinates = (ga, x, y) -> (x + x_offset(ga), y + y_offset(ga))

    intersect_xsize = convert(Int, round(abs(intersect_extent.ul[1] - intersect_extent.ur[1]) / abs(pixelsize_x(gas[1])), digits=0) + 1)
    intersect_ysize = convert(Int, round(abs(intersect_extent.ul[2] - intersect_extent.ll[2]) / abs(pixelsize_y(gas[1])), digits=0) + 1)

    intersect = empty_copy_from_geo_array(gas[1], intersect_xsize, intersect_ysize, intersect_extent.ul, no_data_value(gas[1]))

    for ga in reverse(gas) # if duplicate values, values of first array are set
        for (ind, v) in GeoArrayIndexValueIterator(ga)
            (intersect_x, intersect_y) = map_coordinates(ga, ind[1], ind[2])
            if 1 <= intersect_x && intersect_x <= intersect_xsize && 1 <= intersect_y && intersect_y <= intersect_ysize
                if v != no_data_value(ga)
                    intersect[intersect_x, intersect_y] = v
                end
            end
        end
    end

    return intersect
end

intersect(ga1, ga2) = geoarray_intersect([ga1, ga2])


# TODO: implement sga_difference, sga_sym_difference

function private_get_radial_kernel(radius::Real, pixelsizeX::Real, pixelsizeY::Real)
    indexSpanX = convert(Int32, round(radius / pixelsizeX, RoundNearest))
    indexSpanY = convert(Int32, round(radius / pixelsizeY, RoundNearest))
    kernel = falses(indexSpanX + 1, indexSpanY + 1)
    for x in 0:indexSpanX
        for y in 0:indexSpanY
            distance = sqrt(((x * pixelsizeX)^2) + ((y * pixelsizeY)^2))
            if distance <= radius
                kernel[x+1, y+1] = true
            end
        end
    end
    kernel = hcat([reverse(kernel, dims=(1, 2)); reverse(kernel, dims=2)], [reverse(kernel, dims=1); kernel])
    #display(kernel)
    return (kernel)
end

#=
# create a radial Kernel Mask with a defined radius
function private_get_radial_kernel(sga::SparseGeoArray{DT,IT}, radius::Real, lon_min::Real, lon_max::Real, lat_max::Real, lat_min::Real) where {DT<:Real,IT<:Integer}
    indexSpanX = convert(Int32, round(radius / pixelsizeX, RoundNearest))
    indexSpanY = convert(Int32, round(radius / pixelsizeY, RoundNearest))
    kernel = falses(indexSpanX + 1, indexSpanY + 1)
    for x in 0:indexSpanX
        for y in 0:indexSpanY
            distance = sqrt(((x * pixelsizeX)^2) + ((y * pixelsizeY)^2))
            if distance <= radius
                kernel[x+1, y+1] = true
            end
        end
    end
    kernel = hcat([reverse(kernel, dims=(1, 2)); reverse(kernel, dims=2)], [reverse(kernel, dims=1); kernel])
    #display(kernel)
    return (kernel)
end


# summarize 
function sga_summarize(sga::SparseGeoArray{DT,IT}, sumryFunction::Function, valueTransformation) where {DT<:Real,IT<:Integer}
    sumryFunction(map(x -> valueTransformation(sgat, x[1], x[2]), collect(keys(sga.data))))
end

sga_summarize(sga::SparseGeoArray{DT,IT}, sumryFunction::Function) where {DT<:Real,IT<:Integer} = sga_summarize(sga, sumryFunction, (s, x, y) -> s[x, y])


"""
        sga_summarize_within(sga::SparseGeoArray{DT,IT}, p::Tuple{Real,Real}, radius::Real, sumryFunction::Function, valueTransformation) where {DT<:Real,IT<:Integer}

Summarize pixel values withing a defined radius around a point `p` in a `SparseGeoArray`. The function applies a summary function to the values within the radius, optionally transforming the values using a provided transformation function.

# Arguments 
- `sga::SparseGeoArray{DT,IT}`: The SparseGeoArray containing the data to be summarized.
- `p::Tuple{Real,Real}`: The point around which to summarize the data, given as a tuple of longitude and latitude.
- `radius::Real`: The radius in kilometers within which to summarize the data.
- `sumryFunction::Function`: The function to apply to the values within the radius. It should take an array of values and return a single summary value.
- `valueTransformation`: A function that transforms the values before applying the summary function. It should take the SparseGeoArray, and the x and y indices of the value to be transformed.

# Returns
- A single summary value calculated from the values within the specified radius around point `p`.
"""
function sga_summarize_within(sga::SparseGeoArray{DT,IT}, p::Tuple{Real,Real}, radius::Real, sumryFunction::Function, valueTransformation) where {DT<:Real,IT<:Integer}

    if (radius >= earth_circumference_km / 2)
        return sumryFunction(collect(values(sga.data)))
    end

    p_east = go_direction(p, radius, East())
    p_west = go_direction(p, radius, West())
    p_north = go_direction(p, radius, North())
    p_south = go_direction(p, radius, South())

    bb = bounding_boxes(sga, p_east[1], p_west[1], p_south[2], p_north[2])

    vals = Array{DT}(undef, 0)
    for b in bb
        sgat = sga[b[1]:b[3], b[2]:b[4]]
        for (indices, value) in sgat.data
            if (distance(Tuple(coords(sgat, indices, Center())), p) <= radius)
                if ((sgat[indices[1], indices[2]] != sgat.nodatavalue))
                    push!(vals, valueTransformation(sgat, indices[1], indices[2]))
                end
            end
        end
    end
    sumryFunction(vals)
end

sga_summarize_within(sga::SparseGeoArray{DT,IT}, p::Tuple{Real,Real}, radius::Real, sumryFunction::Function) where {DT<:Real,IT<:Integer} = sga_summarize_within(sga, p, radius, sumryFunction, (s, x, y) -> s[x, y])


function private_minumum_mean(sort_list, value_list)
    min_indices = findall(x -> x == minimum(sort_list), sort_list)
    values = value_list[min_indices]
    return (mean(values))
end

"""
        get_closest_value(sga::SparseGeoArray, p::Tuple{Real,Real})
Get the closest defined value in a `SparseGeoArray` to a given point `p`.
If the value at `p` is defined, it is returned directly. If not, the function searches in all 8 directions until it finds a defined value, returning the mean of the closest values if multiple are found.

# Arguments
- `sga::SparseGeoArray`: The SparseGeoArray from which to retrieve the closest value.
- `p::Tuple{Real,Real}`: The point (longitude, latitude) for which to find the closest defined value.

# Returns
- The closest defined value in the SparseGeoArray to the point `p`. If the value at `p` is defined, it is returned directly. If not, the function searches in all 8 directions until it finds a defined value, returning the mean of the closest values if multiple are found.
"""
function get_closest_value(sga::SparseGeoArray, p::Tuple{Real,Real})

    i_x, i_y = indices(sga, p)
    value = sga[i_x, i_y]

    if value != sga.nodatavalue
        return (value)

    else

        closest_values = []
        closest_distance = []
        directions = [(-1, -1), (-1, 0), (-1, 1), (0, -1), (0, 1), (1, -1), (1, 0), (1, 1)]
        i_distance = 1

        while closest_values == []
            # Go in all 8 directions
            for (dx, dy) in directions
                temp_x = i_x + (i_distance * dx)
                temp_y = i_y + (i_distance * dy)

                #stay within the bounds of sga
                if temp_x > size(sga)[1]
                    temp_x = 1
                elseif temp_x < 1
                    temp_x = size(sga)[1]
                end

                if temp_y > size(sga)[2]
                    temp_y = size(sga)[2]
                elseif temp_y < 1
                    temp_y = 1
                end

                # get value
                temp_value = sga[temp_x, temp_y]

                # check if value is defined
                if temp_value != sga.nodatavalue
                    val_dist = distance(Tuple(coords(sga::SparseGeoArray, (temp_x, temp_y), Center())), p)
                    push!(closest_values, temp_value)
                    push!(closest_distance, val_dist)
                end
            end
            i_distance += 1
        end

        if length(closest_distance) > 1
            return (minumum_mean(closest_distance, closest_values))
        else
            return (closest_values[1])
        end

    end
end

"""
        get_box_around(sga::SparseGeoArray{DT,IT}, p::Tuple{Real,Real}, radius::Real)::SparseGeoArray{DT,IT} where {DT<:Real,IT<:Integer}

Crop a `SparseGeoArray` to an extent defined by a radius around a point `p`. The function calculates the bounding box around the point `p` 
based on the specified radius and returns a new `SparseGeoArray` containing only the data within that bounding box.

# Arguments
- `sga::SparseGeoArray{DT,IT}`: The SparseGeoArray to be cropped.
- `p::Tuple{Real,Real}`: The point around which to crop the SparseGeoArray, given as a tuple of longitude and latitude.
- `radius::Real`: The radius around the point `p` that defines the extent of the cropping.

# Returns 
- A new `SparseGeoArray{DT,IT}` that contains only the data within the bounding box defined by the radius around point `p`.
"""
function get_box_around(sga::SparseGeoArray{DT,IT}, p::Tuple{Real,Real}, radius::Real)::SparseGeoArray{DT,IT} where {DT<:Real,IT<:Integer}
    p_east = go_direction(p, radius, East())
    p_west = go_direction(p, radius, West())
    p_north = go_direction(p, radius, North())
    p_south = go_direction(p, radius, South())
    bb = bounding_boxes(sga, p_east[1], p_west[1], p_south[2], p_north[2])
    return sga[bb[1][1]:bb[1][3],bb[1][2]:bb[1][4]]    
end
=#


# union : union of all values in sga1 and sga2 in a new sga
# result contains all data that is in sga1 OR sga2
# if a grid cell is present in both but with different values the value of sga1 should be used
# (thus union does not commute, we can have union(x,y)!=union(y,x)
# take into account different dimensions (coordinates, sizes adf transformation), we can reject sga's with different projections
function union(sga1::SparseGeoArray{DT, IT}, sga2::SparseGeoArray{DT, IT}) :: SparseGeoArray{DT, IT} where {DT <: Real, IT <: Integer}

end

# as before, but instead of constructing a new sga store the result in place in sga1 and delete all values from sga2 after they have been processed (one by one)
function union!(sga1::SparseGeoArray{DT, IT}, sga2::SparseGeoArray{DT, IT}) where {DT <: Real, IT <: Integer}

end


# if bored: intersect, diff, sym_diff in the same way

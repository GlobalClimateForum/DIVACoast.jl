"""
    join_geotiff_data_categorised!(sgrs :: Dict{CT, SparseGeoArray{DT, IT}}, sgrs_ret :: Dict{CT2, SparseGeoArray{DT, IT}}, mapping :: Dict{CT, CT2}) where {CT <: Integer, CT2 <: Integer, DT <: Real, IT <: Integer}

The function joins geotiff data from a dictionary of `SparseGeoArray` objects categorized by integer keys.
It takes a mapping dictionary that maps the original keys to new keys, and it updates the `sgrs_ret` dictionary with the union of the `SparseGeoArray` objects.

# Arguments
- `sgrs`: A dictionary where keys are integers and values are `SparseGeoArray`. 
- `sgrs_ret`: A dictionary where keys are new integers and values are `SparseGeoArray` to store the results.
- `mapping`: A dictionary that maps original integer keys to new integer keys.
# Returns
- The function modifies `sgrs_ret` in place, adding the union of `SparseGeoArray` objects from `sgrs` based on the mapping. 
"""
function join_geotiff_data_categorised!(sgrs :: Dict{CT, SparseGeoArray{DT, IT}}, sgrs_ret :: Dict{CT2, SparseGeoArray{DT, IT}}, mapping :: Dict{CT, CT2}) where {CT <: Integer, CT2 <: Integer, DT <: Real, IT <: Integer}
  for key in keys(sgrs)
    mk :: CT2 = mapping[key]
    if (haskey(mapping, key))
      if (haskey(sgrs_ret, mk))
        union!(sgrs_ret[mk],sgrs[key])
      else
        sgrs_ret[mk],sgrs[key]
      end
    end
  end
end

function joinGEOTiffDataCategorised!(sgrs :: Dict{CT, SparseGeoArray{DT, IT}}, sgrs_ret :: Dict{CT2, SparseGeoArray{DT, IT}}, mapping :: Dict{CT, CT2}) where {CT <: Integer, CT2 <: Integer, DT <: Real, IT <: Integer}
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

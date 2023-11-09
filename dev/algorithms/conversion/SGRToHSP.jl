
export toHypsometricProfileFlex

function toHypsometricProfileFlex(sga :: SparseGeoArray{DT, IT}, w::DT2, min_elevation::DT2, max_elevation::DT2, elevation_incr::DT2) :: HypsometricProfileFlex where {DT <: Real, IT <: Integer, DT2 <: Real} 
  s = floor(Int,((max_elevation - min_elevation) / elevation_incr))
  a :: Array{DT2} = zeros(s)
  e = Array{DT2}(undef, s)
  for i in 1:s
    e[i] = min_elevation + i * elevation_incr
  end

  for (indices, elevation) in sga.data
    if elevation<=e[1] 
      a[1] += area(sga, indices)
    else 
      i = floor(Int,(elevation - min_elevation) / elevation_incr) + 1
      if (i <= length(e)) a[i] += area(sga, indices) end
    end
  end

  i=1
  while (i <= (length(e)-1))
    if (a[i]==0 && a[i+1]==0) 
      deleteat!(e,i)
      deleteat!(a,i)
    else 
      i += 1
    end 
  end

  return HypsometricProfileFlex(w, pushfirst!(e,min_elevation), pushfirst!(a,0), a[:,:], a[:,:])
end


function toHypsometricProfileFlex(sga_elevation :: SparseGeoArray{DT, IT}, sgas_exp_st :: Array{SparseGeoArray{DT, IT}}, exp_st_names::Array{String}, sgas_exp_dyn :: Array{SparseGeoArray{DT, IT}}, exp_dyn_names::Array{String}, w::DT2, min_elevation::DT2, max_elevation::DT2, elevation_incr::DT2) :: HypsometricProfileFlex where {DT <: Real, IT <: Integer, DT2 <: Real} 
  # ToDo:: check if all dimensions match.

  s = floor(Int,((max_elevation - min_elevation) / elevation_incr))
  a :: Array{DT2} = zeros(s)
  e = Array{DT2}(undef, s)
  for i in 1:s
    e[i] = min_elevation + i * elevation_incr
  end

  st :: Array{DT2} = zeros(s,size(sgas_exp_st,1))
  dyn :: Array{DT2} = zeros(s,size(sgas_exp_dyn,1))

  for (indices, elevation) in sga_elevation.data
    if elevation<=e[1] 
      a[1] += area(sga_elevation, indices)
      for j in 1:size(sgas_exp_st,1)
#      if (haskey(sgas_exp_st[j],index))
        if (sgas_exp_st[j][indices[1],indices[2]]) != sgas_exp_st[j].nodatavalue
          st[1,j] += sgas_exp_st[j][indices[1],indices[2]]
        end
      end
      for j in 1:size(sgas_exp_dyn,1)
        if (sgas_exp_dyn[j][indices[1],indices[2]]) != sgas_exp_dyn[j].nodatavalue
          dyn[1,j] += sgas_exp_dyn[j][indices[1],indices[2]]
        end
      end
    else 
      i = floor(Int,(elevation - min_elevation) / elevation_incr) + 1
      if (i <= length(e)) 
        a[i] += area(sga_elevation, indices) 
        for j in 1:size(sgas_exp_st,1)
          if (sgas_exp_st[j][indices[1],indices[2]]) != sgas_exp_st[j].nodatavalue
            st[i,j] += sgas_exp_st[j][indices[1],indices[2]]
          end
        end
        for j in 1:size(sgas_exp_dyn,1)
          if (sgas_exp_dyn[j][indices[1],indices[2]]) != sgas_exp_dyn[j].nodatavalue
            dyn[i,j] += sgas_exp_dyn[j][indices[1],indices[2]]
          end
        end
      end
    end
  end

  i=1
  while (i <= (length(e)-1))
    if (a[i]==0 && a[i+1]==0) 
      deleteat!(e,i)
      deleteat!(a,i)
      # this might be memory inefficient.
      st = st[1:end .!= i, 1:end]
      dyn = dyn[1:end .!= i, 1:end]
    else 
      i += 1
    end 
  end

  z_st :: Array{DT2} = zeros(size(sgas_exp_st,1))
  z_dy :: Array{DT2} = zeros(size(sgas_exp_dyn,1))

  return HypsometricProfileFlex(w, pushfirst!(e,min_elevation), pushfirst!(a,0), [z_st';st], [z_dy';dyn])
end


function toHypsometricProfileFlex(sgas_elevation :: Dict{IT2, SparseGeoArray{DT, IT}}, sgas_exp_st :: Array{Dict{IT2, SparseGeoArray{DT, IT}}}, exp_st_names::Array{String}, sgas_exp_dyn :: Array{Dict{IT2, SparseGeoArray{DT, IT}}}, exp_dyn_names::Array{String}, w::DT2, min_elevation::DT2, max_elevation::DT2, elevation_incr::DT2) :: Dict{IT2, HypsometricProfileFlex} where {DT <: Real, IT <: Integer, DT2 <: Real, IT2 <: Integer} 
  ret :: Dict{IT2, HypsometricProfileFlex{DT2}} = Dict{IT2, HypsometricProfileFlex{DT2}}()
  st = Array{SparseGeoArray{DT, IT}}(undef,size(sgas_exp_st,1))
  dy = Array{SparseGeoArray{DT, IT}}(undef,size(sgas_exp_dyn,1))

  print("construction progress: 0 ")
  p = 0
  counter = 0

  length(sgas_elevation)

  # VERY memory inefficient
  for (index, elevation_data) in sgas_elevation
    counter = counter + 1
    if ((counter*100 ÷ length(sgas_elevation)) ÷ 10)>p
      p=(counter*100 ÷ length(sgas_elevation)) ÷ 10
      print("$(p*10) ")
    end

    for j in 1:size(sgas_exp_st,1)
      if (haskey(sgas_exp_st[j],index))
        st[j]=sgas_exp_st[j][index]
      else 
        st[j]=SparseGeoArray{DT, IT}()
        st[j].xsize = elevation_data.xsize
        st[j].ysize = elevation_data.ysize
      end
    end 
    for j in 1:size(sgas_exp_dyn,1)
      if (haskey(sgas_exp_dyn[j],index))
        dy[j]=sgas_exp_dyn[j][index]
      else 
        dy[j]=SparseGeoArray{DT, IT}()
        dy[j].xsize = elevation_data.xsize
        dy[j].ysize = elevation_data.ysize
      end
    end 
    ret[index] = toHypsometricProfileFlex(elevation_data, st, exp_st_names, dy, exp_dyn_names, convert(DT2,1), min_elevation, max_elevation, elevation_incr)
  end
  println()
  return ret
end


function toHypsometricProfileFlex(categories::String, elevationfile :: String, exposure_files :: Array{String}, exposure_names::Array{String}, w::Float32, min_elevation::Float32, max_elevation::Float32, elevation_incr::Float32) 
  # :: Dict??

  # steps: read line by line from all files in parallel
  # store per category: dict{elevation, Array{}}

  s = floor(Int,((max_elevation - min_elevation) / elevation_incr))
  a :: Array{Float32} = zeros(s)
  e = Array{Float32}(undef, s)
  for i in 1:s
    e[i] = min_elevation + i * elevation_incr
  end

#  for (indices, elevation) in sga.data
#    if elevation<=e[1] 
#      a[1] += area(sga, indices)
#    else 
#      i = floor(Int,(elevation - min_elevation) / elevation_incr) + 1
#      if (i <= length(e)) a[i] += area(sga, indices) end
#    end
#  end
#
#  i=1
#  while (i <= (length(e)-1))
#    if (a[i]==0 && a[i+1]==0) 
#      deleteat!(e,i)
#      deleteat!(a,i)
#    else 
#      i += 1
#    end 
#  end

#  HypsometricProfileFlex(w, pushfirst!(e,min_elevation), pushfirst!(a,0), a[:,:], a[:,:])
end


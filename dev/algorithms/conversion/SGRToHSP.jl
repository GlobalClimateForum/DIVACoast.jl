export to_hypsometric_profile, to_hypsometric_profiles

function to_hypsometric_profile(sga :: SparseGeoArray{DT, IT}, w::DT2, min_elevation::DT2, max_elevation::DT2, elevation_incr::DT2) :: HypsometricProfile where {DT <: Real, IT <: Integer, DT2 <: Real} 
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

  return HypsometricProfile(w, pushfirst!(e,min_elevation), pushfirst!(a,0), a[:,:], a[:,:])
end


function to_hypsometric_profile(sga_elevation :: SparseGeoArray{DT, IT}, 
  sgas_exp_st :: Array{SparseGeoArray{DT, IT}}, exp_st_names::Array{String}, exp_st_units::Array{String},
  sgas_exp_dyn :: Array{SparseGeoArray{DT, IT}}, exp_dyn_names::Array{String}, exp_dyn_units::Array{String},
  w::DT2, min_elevation::DT2, max_elevation::DT2, elevation_incr::DT2) 
  :: HypsometricProfile where {DT <: Real, IT <: Integer, DT2 <: Real} 
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

  return HypsometricProfile(w, pushfirst!(e,min_elevation), pushfirst!(a,0), [z_st';st], exp_st_names, exp_st_units, [z_dy';dyn], exp_dyn_names, exp_dyn_units)
end


function to_hypsometric_profile(sgas_elevation :: Dict{IT2, SparseGeoArray{DT, IT}}, 
  sgas_exp_st :: Array{Dict{IT2, SparseGeoArray{DT, IT}}}, exp_st_names::Array{String}, exp_st_units::Array{String},
  sgas_exp_dyn :: Array{Dict{IT2, SparseGeoArray{DT, IT}}}, exp_dyn_names::Array{String}, exp_dyn_units::Array{String},
  w::DT2, min_elevation::DT2, max_elevation::DT2, elevation_incr::DT2) 
  :: Dict{IT2, HypsometricProfile} where {DT <: Real, IT <: Integer, DT2 <: Real, IT2 <: Integer} 

  ret :: Dict{IT2, HypsometricProfile{DT2}} = Dict{IT2, HypsometricProfile{DT2}}()
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
    ret[index] = to_hypsometric_profile(elevation_data, st, exp_st_names, exp_st_units, dy, exp_dyn_names, exp_dyn_units convert(DT2,1), min_elevation, max_elevation, elevation_incr)
  end
  println()
  return ret
end

function to_hypsometric_profile(e :: Array{DT}, a :: Array{DT}, 
  static_exposure :: Array{DT,2}, static_exposure_names::Array{String}, static_exposure_units::Array{String}, 
  dynamic_exposure :: Array{DT,2}, dynamic_exposure_names::Array{String}, dynamic_exposure_units::Array{String}, 
  w::DT, min_elevation::DT, max_elevation::DT, elevation_incr::DT) :: HypsometricProfile where {DT <: Real} 
  i=1
  while (i <= (length(e)-1))
    if (a[i]==0 && a[i+1]==0) 
      deleteat!(e,i)
      deleteat!(a,i)
      static_exposure  = static_exposure[1:end .!= (i), :]
      dynamic_exposure  = dynamic_exposure[1:end .!= (i), :]
    else 
      i += 1
    end 
  end

  return HypsometricProfile(w, pushfirst!(e,min_elevation), pushfirst!(a,0), 
  vcat(zeros(DT,1,size(static_exposure,2)),static_exposure), static_exposure_names, static_exposure_units,
  vcat(zeros(DT,1,size(dynamic_exposure,2)),dynamic_exposure), dynamic_exposure_names, dynamic_exposure_units)
end

function to_hypsometric_profiles(
  category_file_name :: String, elevation_file_name :: String, 
  exposure_static_file_names :: Array{String}, exposure_static_names::Array{String}, exposure_static_units::Array{String}, 
  exposure_dynamic_file_names :: Array{String}, exposure_dynamic_names::Array{String}, exposure_dynamic_units::Array{String},
  w::Float32, min_elevation::Float32, max_elevation::Float32, elevation_incr::Real) 

  category_data = SparseGeoArray{Float32, Int32}()
  read_geotiff_header!(category_data, category_file_name)

  elevation_data = SparseGeoArray{Float32, Int32}()
  read_geotiff_header!(elevation_data, elevation_file_name)
  sga_dimension_match_log(category_data, elevation_data)

  sgas_exp_st  = Array{SparseGeoArray{Float32, Int32}}(undef,size(exposure_static_file_names,1))
  sgas_exp_dyn = Array{SparseGeoArray{Float32, Int32}}(undef,size(exposure_dynamic_file_names,1))

  s = floor(Int,((max_elevation - min_elevation) / elevation_incr))
  e = Array{Float32}(undef, s)
  for i in 1:s
    e[i] = min_elevation + i * elevation_incr
  end

  area_data :: Dict{Int32, Array{Float32}} = Dict()
  exp_st_data :: Dict{Int32,  Array{Float32,2}} = Dict()
  exp_dyn_data :: Dict{Int32, Array{Float32,2}} = Dict()

  for i in 1:size(sgas_exp_st,1)
    sgas_exp_st[i] = SparseGeoArray{Float32, Int32}()
    read_geotiff_header!(sgas_exp_st[i],exposure_static_file_names[i])
    sga_dimension_match_log(category_data, sgas_exp_st[i])
  end

  for i in 1:size(sgas_exp_dyn,1)
    sgas_exp_dyn[i] = SparseGeoArray{Float32, Int32}()
    read_geotiff_header!(sgas_exp_dyn[i],exposure_dynamic_file_names[i])
    sga_dimension_match_log(category_data, sgas_exp_dyn[i])
#    exp_dyn_data[i] = Dict()
  end

#  st = Array{SparseGeoArray{DT, IT}}(undef,size(sgas_exp_st,1))
#  dy = Array{SparseGeoArray{DT, IT}}(undef,size(sgas_exp_dyn,1))
  print("construction progress: 0 ")
  p = 0

  for y in 1:size(category_data, 2)
    if ((y*100 ÷ size(category_data, 2)) ÷ 10)>p
      p=(y*100 ÷ size(category_data, 2)) ÷ 10
      print("$(p*10) ")
    end
    clear_data!(category_data)
    read_geotiff_data_partial!(category_data, 1, size(category_data, 1), y, y) 
    clear_data!(elevation_data)
    read_geotiff_data_partial!(elevation_data, 1, size(elevation_data, 1), y, y) 
    for i in 1:size(sgas_exp_st,1)
      clear_data!(sgas_exp_st[i])
      read_geotiff_data_partial!(sgas_exp_st[i], 1, size(sgas_exp_st[i], 1), y, y)
    end
    for i in 1:size(sgas_exp_dyn,1)
      clear_data!(sgas_exp_dyn[i])
      read_geotiff_data_partial!(sgas_exp_dyn[i], 1, size(sgas_exp_dyn[i], 1), y, y)
    end
    for x in 1:size(category_data, 1)
      if (category_data[x,y]!=category_data.nodatavalue) 
        if (elevation_data[x,y]!=elevation_data.nodatavalue)
          if (!haskey(area_data,category_data[x,y])) area_data[category_data[x,y]] = zeros(s) end
          if (!haskey(exp_st_data,category_data[x,y])) exp_st_data[category_data[x,y]] = zeros(s,size(sgas_exp_st,1)) end
          if (!haskey(exp_dyn_data,category_data[x,y])) exp_dyn_data[category_data[x,y]] = zeros(s,size(sgas_exp_dyn,1)) end

          i = if elevation_data[x,y]<=e[1] 1 else floor(Int,(elevation_data[x,y] - min_elevation) / elevation_incr) + 1 end
          if (i > length(e)) i = length(e) end
          area_data[category_data[x,y]][i] += area(elevation_data, x, y)
          for j in 1:size(sgas_exp_st,1)
            if (!haskey(exp_st_data,category_data[x,y])) exp_st_data[category_data[x,y]] = zeros(s,size(sgas_exp_st,1)) end
            if (sgas_exp_st[j][x,y]!= sgas_exp_st[j].nodatavalue) exp_st_data[category_data[x,y]][i,j] += sgas_exp_st[j][x,y] end
          end
          for j in 1:size(sgas_exp_dyn,1)            
            if (sgas_exp_dyn[j][x,y]!= sgas_exp_dyn[j].nodatavalue) exp_dyn_data[category_data[x,y]][i,j] += sgas_exp_dyn[j][x,y] end
          end
        end
      end
    end  
  end
  println()

  #pushfirst!(e,min_elevation)
  ret :: Dict{Int32, HypsometricProfile{Float32}} = Dict{Int32, HypsometricProfile{Float32}}()
  for (index, areas) in area_data 
    ret[index] = to_hypsometric_profile(copy(e), areas, 
    exp_st_data[index], exposure_static_names, exposure_static_units, 
    exp_dyn_data[index], exposure_dynamic_names, exposure_dynamic_units, 
    w, min_elevation, max_elevation, elevation_incr)    
  end
  return ret
end

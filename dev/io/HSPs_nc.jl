export toHypsometricProfileFlex

function toHypsometricProfileFlex(hspfs, min_elevation::Float32, max_elevation::Float32, elevation_incr::Float32, filename :: String)



  s = floor(Int,((max_elevation - min_elevation) / elevation_incr))
  a :: Array{Float32} = zeros(s)
  e = Array{Float32}(undef, s)
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

  HypsometricProfileFlex(w, pushfirst!(e,min_elevation), pushfirst!(a,0), a[:,:], a[:,:])
end


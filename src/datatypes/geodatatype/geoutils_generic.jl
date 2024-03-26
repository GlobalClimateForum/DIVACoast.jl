function nh4_function_application(sga::SparseGeoArray{DT,IT}, x::Integer, y::Integer, f::Function) where {DT<:Real,IT<:Integer}
  stop :: Bool = false
  if ((x < 1) || (x > sga.xsize) || (y < 1) || (y > sga.ysize))
    return 
  end
  if (x > 1)
    stop = f(sga, x-1, y)
    if (stop) return end 
  else
    if (sga.circular)
      stop = f(sga, sga.xsize, y)
      if (stop) return end 
    end
  end
  if (x < sga.xsize)
    stop = f(sga, x+1, y)
    if (stop) return end 
  else
    if (sga.circular)
      stop = f(sga, 1, y)
      if (stop) return end 
    end
  end
  if (y > 1)
    stop = f(sga, x, y-1)
    if (stop) return end 
  end
  if (y < sga.ysize)
    stop = f(sga, x, y+1)
    if (stop) return end 
  end
  return ret
end


function nh8_function_application(sga::SparseGeoArray{DT,IT}, x::Integer, y::Integer, f::Function) where {DT<:Real,IT<:Integer}
  stop :: Bool = false
  if ((x < 1) || (x > sga.xsize) || (y < 1) || (y > sga.ysize))
    return 
  end
  if (x > 1)
    stop = f(sga, x-1, y)
    if (stop) return end 
    if (y > 1)
      stop = f(sga, x-1, y-1)
      if (stop) return end 
    end
    if (y < sga.ysize) 
      stop = f(sga, x-1, y+1)
      if (stop) return end 
    end
  else
    if (sga.circular)
      stop = f(sga, sga.xsize, y)
      if (stop) return end 
    end
    if (y > 1)
      stop = f(sga, x-1, y-1)
      if (stop) return end 
    end
    if (y < sga.ysize) 
      stop = f(sga, x-1, y+1)
      if (stop) return end 
    end
  end

  if (x < sga.xsize)
    stop = f(sga, x+1, y)
    if (stop) return end 
    if (y > 1)
      stop = f(sga, x+1, y-1)
      if (stop) return end 
    end
    if (y < sga.ysize) 
      stop = f(sga, x+1, y+1)
      if (stop) return end 
    end
  else
    if (sga.circular)
      stop = f(sga, 1, y)
      if (stop) return end 
      if (y > 1)
        stop = f(sga, 1, y-1)
        if (stop) return end 
      end
      if (y < sga.ysize) 
        stop = f(sga, 1, y+1)
        if (stop) return end 
      end
    end
  end
  if (y > 1)
    stop = f(sga, x, y-1)
    if (stop) return end 
  end
  if (y < sga.ysize)
    stop = f(sga, x, y+1)
    if (stop) return end 
  end
  return ret
end




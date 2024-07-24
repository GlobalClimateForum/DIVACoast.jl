function nh4_function_application(sga::SparseGeoArray{DT,IT}, x::Integer, y::Integer, f::Function) where {DT<:Real,IT<:Integer}
  stop :: Bool = false
  if ((x < 1) || (x > sga.xsize) || (y < 1) || (y > sga.ysize))
    return stop
  end
  if (x > 1)
    stop = f(sga, x-1, y)
    if (stop) return stop end 
  else
    if (sga.circular)
      stop = f(sga, sga.xsize, y)
      if (stop) return stop end 
    end
  end
  if (x < sga.xsize)
    stop = f(sga, x+1, y)
    if (stop) return stop end 
  else
    if (sga.circular)
      stop = f(sga, 1, y)
      if (stop) return stop end 
    end
  end
  if (y > 1)
    stop = f(sga, x, y-1)
    if (stop) return stop end 
  end
  if (y < sga.ysize)
    stop = f(sga, x, y+1)
    if (stop) return stop end 
  end
  return stop
end


function nh8_function_application(sga::SparseGeoArray{DT,IT}, x::Integer, y::Integer, f::Function) where {DT<:Real,IT<:Integer}
  stop :: Bool = false
  if ((x < 1) || (x > sga.xsize) || (y < 1) || (y > sga.ysize))
    return stop 
  end
  if (x > 1)
    stop = f(sga, x-1, y)
    if (stop) return stop end 
    if (y > 1)
      stop = f(sga, x-1, y-1)
      if (stop) return stop end 
    end
    if (y < sga.ysize) 
      stop = f(sga, x-1, y+1)
      if (stop) return stop end 
    end
  else
    if (sga.circular)
      stop = f(sga, sga.xsize, y)
      if (stop) return stop end 
    end
    if (y > 1)
      stop = f(sga, x-1, y-1)
      if (stop) return stop end 
    end
    if (y < sga.ysize) 
      stop = f(sga, x-1, y+1)
      if (stop) return stop end 
    end
  end

  if (x < sga.xsize)
    stop = f(sga, x+1, y)
    if (stop) return stop end 
    if (y > 1)
      stop = f(sga, x+1, y-1)
      if (stop) return stop end 
    end
    if (y < sga.ysize) 
      stop = f(sga, x+1, y+1)
      if (stop) return stop end 
    end
  else
    if (sga.circular)
      stop = f(sga, 1, y)
      if (stop) return stop end 
      if (y > 1)
        stop = f(sga, 1, y-1)
        if (stop) return stop end 
      end
      if (y < sga.ysize) 
        stop = f(sga, 1, y+1)
        if (stop) return stop end 
      end
    end
  end
  if (y > 1)
    stop = f(sga, x, y-1)
    if (stop) return stop end 
  end
  if (y < sga.ysize)
    stop = f(sga, x, y+1)
    if (stop) return stop end 
  end
  return stop
end




export integrate_simple

@inline 
function midRect(f,a,b)
  return f((a+b)/2)
end

@inline 
function trapezoid(f,a,b)
  return (f(a)+f(b))/2
end

function integrate_simple(f, lo, hi, steps=10000, method=midRect) 
  if (hi<lo) return 0 end
#  if (hi<lo) return f(lo) end
  d = (hi-lo)/steps
  ret = 0
  a = lo
  for i in 1:steps 
    ret += method(f,a,a+d)
    a += d
  end
  return d*ret
end

function integrate_simple_vectorized(f, lo, hi, steps=10000, method=midRect) 
  ret = f(lo)
  if (hi<lo) return map(x->0.0,ret) end
#  if (hi<lo) return f(lo) end
  d = (hi-lo)/steps
  a = lo
  for i in 1:steps 
    ret += method(f,a,a+d)
    a += d
  end
  return d*ret
end


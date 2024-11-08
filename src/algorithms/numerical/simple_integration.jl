export integrate_simple, integrate_simple_debug

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

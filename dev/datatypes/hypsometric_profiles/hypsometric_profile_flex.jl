using Main.ExtendedLogging
using Logging

#export exposure, sed, sed_above, sed_below, remove_below, add_above, add_between


mutable struct HypsometricProfileFlex
  width        :: Float32
  minElevation :: Float32
  maxElevation :: Float32

  exposure     :: Dict{Float32,(Float32,Float32,Float32)}
 
  elevation  :: Array{Float32}
  area       :: Array{Float32}
  population :: Array{Float32}
  assets     :: Array{Float32}
  logger     :: ExtendedLogging.ExtendedLogger

#=
  function HypsometricProfileFlex(w,m,x1,x2,x3,x4,logger)
    if (length(x1)!=length(x2)) Main.ExtendedLogging.log(logger,Logging.Error,@__FILE__,"\n length(x1) != length(x2) as length($x1) != length($x2) as $(length(x1)) != $(length(x2))") end
    if (length(x1)!=length(x3)) Main.ExtendedLogging.log(logger,Logging.Error,@__FILE__,"\n length(x1) != length(x3) as length($x1) != length($x3) as $(length(x1)) != $(length(x3))") end
    if (length(x1)!=length(x4)) Main.ExtendedLogging.log(logger,Logging.Error,@__FILE__,"\n length(x1) != length(x4) as length($x1) != length($x4) as $(length(x1)) != $(length(x4))") end#

    if (length(x1) < 1) Main.ExtendedLogging.log(logger,Logging.Error,@__FILE__,"\n length(x1) = length($x1) = $(length(x1)) < 2 which is not allowed") end
   if (x1[1] < m) Main.ExtendedLogging.log(logger,Logging.Error,@__FILE__,"\n x1[1] = $(x1[1]) < minimum elevation m = $m which is not allowed") end#

    delta = x1[1] - m
    for x in 2:(length(x1)) 
      if ((x1[x]-x1[x-1])!=delta) Main.ExtendedLogging.log(logger,Logging.Error,@__FILE__,"\n unequal delta: x1[$x]-x1[$(x-1)] = $(x1[x])-$(x1[x-1]) = $(x1[x]-x1[x-1]) != $delta") end
    end

    if (!issorted(x1)) Main.ExtendedLogging.log(logger,Logging.Error,@__FILE__,"\n x1 is not sorted: $x1") end
    new(w,m,x1[length(x1)],delta,pushfirst!(x1,m),pushfirst!(x2,0),pushfirst!(x3,0),pushfirst!(x4,0), cumsum(x2), cumsum(x3), cumsum(x4), logger)
  end
=#
end


#=
function exposure(hspf :: HypsometricProfileFlex, e) 
end

function sed(hspf, popfactor, assetfactor)
end 

function sed_above(hspf, above, popfactor, assetfactor)
end 

function sed_below(hspf, below, popfactor, assetfactor)
end 

function remove_below(hspf, below)
end

function add_above(hspf, above, pop, assets)
end

function add_between(hspf, above, below, pop, assets)
end
=#

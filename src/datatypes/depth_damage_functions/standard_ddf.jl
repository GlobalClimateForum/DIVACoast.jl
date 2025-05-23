export StandardDDF

# A bit of an ugly hack to enably multiple dispatch on the function type
struct StandardDDF <: Function
   hdd :: Real
end

(sddf::StandardDDF)(x::Real) = x / (x + sddf.hdd)
export StandardDDF

# A bit of an ugly hack to enably multiple dispatch on the function type
struct StandardDDF <: Function
   hdd :: Float64
end

(sddf::StandardDDF)(x) = x / (x + sddf.hdd)
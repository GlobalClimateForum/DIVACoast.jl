export CoastalModel

mutable struct CoastalModel{DT<:Real}
  surge_model         :: Distribution
  coastal_plain_model :: HypsometricProfile{DT}
end


export LocalCoastalModel

using Distributions

mutable struct LocalCoastalModel{DT<:Real}
  surge_model         :: Distribution
  coastal_plain_model :: HypsometricProfile{DT}
end


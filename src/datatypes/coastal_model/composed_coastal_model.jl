export ComposedImpactModel

mutable struct ComposedImpactModel{ID_TYPE1,ID_TYPE2,DATA,CIU} <: CoastalImpactUnit where {CIU <: CoastalImpactUnit}
  level::String
  id::ID_TYPE1
  data::DATA
  children::Dict{ID_TYPE2,CIU}
end
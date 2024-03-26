export ComposedCoastalModel, apply_accumulate
#  expected_damage_bathtub_standard_ddf, expected_damage_bathtub

using Distributions

mutable struct ComposedCoastalModel{IT1,IT2,DATA,CM}
  level    :: String
  id       :: IT1  
  data     :: DATA
  children :: Dict{IT2,CM}
end

function apply_accumulate(ccm :: ComposedCoastalModel{IT1,IT2,DATA,CM}, f :: Function, accumulate :: Function) where {IT1, IT2, DATA, CM}
  appacc(f,acc) = function(ccm); apply_accumulate(ccm,f,acc) end
  results = map(appacc(f,accumulate), values(ccm.children))
  return reduce(accumulate, results)
end


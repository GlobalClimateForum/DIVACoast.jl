export ComposedModel, 
  apply_accumulate, apply_accumulate_record
#  expected_damage_bathtub_standard_ddf, expected_damage_bathtub

using Distributions

mutable struct ComposedModel{IT1,IT2,DATA,CM}
  level    :: String
  id       :: IT1  
  data     :: DATA
  children :: Dict{IT2,CM}
end

function apply_accumulate(ccm :: ComposedModel{IT1,IT2,DATA,CM}, f :: Function, accumulate :: Function) where {IT1, IT2, DATA, CM}
  appacc(f,acc) = function(ccm); apply_accumulate(ccm,f,acc) end
  results = map(appacc(f,accumulate), values(ccm.children))
  return reduce(accumulate, results)
end

function apply_accumulate_record(ccm :: ComposedModel{IT1,IT2,DATA,LocalCoastalModel}, f :: Function, accumulate :: Function) where {IT1, IT2, DATA}
  ret = Dict() 
  for (id,child) in ccm.children
    ret[id] = apply_accumulate_record(child,f,accumulate)
  end
  return (reduce(accumulate, values(ret)),ret)
end

function apply_accumulate_record(ccm :: ComposedModel{IT1,IT2,DATA,CM}, f :: Function, accumulate :: Function) where {IT1, IT2, DATA, CM}
  ret = Dict() 
  for (id,child) in ccm.children
    ret[id] = apply_accumulate_record(child,f,accumulate)
  end

  return (reduce(accumulate, map(x->x[1],values(ret))),ret)
end


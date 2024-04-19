export apply_accumulate, apply_accumulate_record, apply, apply_break

function apply(ccm::ComposedImpactModel{IT1,IT2,DATA,CM}, f::Function) where {IT1,IT2,DATA,CM<:CoastalImpactUnit}
  foreach(x -> apply(x,f), values(ccm.children))
end

function apply_break(ccm::ComposedImpactModel{IT1,IT2,DATA,CM}, f::Function) where {IT1,IT2,DATA,CM<:CoastalImpactUnit}
  if (f(ccm))
    return
  else
    foreach(x -> apply_break(x,f), values(ccm.children))
  end
end

function apply_accumulate(ccm::ComposedImpactModel{IT1,IT2,DATA,CIU}, f::Function, accumulate::Function) where {IT1,IT2,DATA,CIU<:CoastalImpactUnit}
  appacc(f, acc) = function (ccm)
    apply_accumulate(ccm, f, acc)
  end
  results = map(appacc(f, accumulate), values(ccm.children))
  return reduce(accumulate, results)
end

function apply_accumulate_record(ccm::ComposedImpactModel{IT1,IT2,DATA,LocalCoastalImpactModel}, f::Function, accumulate::Function) where {IT1,IT2,DATA}
  #println(ccm)
  #ComposedImpactModel{Int32, Int32, Nothing, LocalCoastalImpactModel}("GADM1", 1354, nothing, Dict{Int32, LocalCoastalImpactModel}(2035 => LocalCoastalImpactModel{Float32}(GeneralizedExtremeValue{Float64}(μ=0.9496728026009327, σ=0.04918775864133863, ξ=0.0), 

  # better: ret = Dict{IT1,accumulate::Result_type} 
  ret = 
  if length(ccm.children)>0
    Dict(first(ccm.children)[1] => ("LOCAL", first(ccm.children)[1], apply_accumulate_record(first(ccm.children)[2], f, accumulate)))
  else
    Dict()
  end

  for (id, child) in ccm.children
    ret[id] = ("LOCAL", id, apply_accumulate_record(child, f, accumulate))
  end
  return (ccm.level, ccm.id, reduce(accumulate, map(x -> x[3], values(ret))),  ret)
end

function apply_accumulate_record(ccm::ComposedImpactModel{IT1,IT2,DATA,CM}, f::Function, accumulate::Function) where {IT1,IT2,DATA,CM<:CoastalImpactUnit}
  #println()
  #println("type_ccm = $(typeof(ccm))")
  #println("ccm.level = $(ccm.level)")
  #println("ccm.id =$(ccm.id)")
  #println("ccm.children = $(typeof(ccm.children))")
  #println("type=$(typeof(first(ccm.children)))")

  # better: ret = Dict{IT1,accumulate::Result_type} 
  ret = 
  if length(ccm.children)>0
    Dict(first(ccm.children)[1] => apply_accumulate_record(first(ccm.children)[2], f, accumulate))
  else
    Dict()
  end

  for (id, child) in ccm.children
    #println("$(typeof(apply_accumulate_record(child, f, accumulate)))")
    ret[id] = apply_accumulate_record(child, f, accumulate)
  end

  return (ccm.level, ccm.id, reduce(accumulate, map(x -> x[3], values(ret))), ret)
end


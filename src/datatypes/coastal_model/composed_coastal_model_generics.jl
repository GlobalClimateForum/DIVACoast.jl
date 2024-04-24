export apply_accumulate, apply_accumulate_record, apply, apply_break, apply_accumulate_store,
  find, collect_data

function apply(ccm::ComposedImpactModel{IT1,IT2,DATA,CM}, f::Function) where {IT1,IT2,DATA,CM<:CoastalImpactUnit}
  foreach(x -> apply(x, f), values(ccm.children))
end

function apply_break(ccm::ComposedImpactModel{IT1,IT2,DATA,CM}, f::Function) where {IT1,IT2,DATA,CM<:CoastalImpactUnit}
  if (f(ccm))
    return
  else
    foreach(x -> apply_break(x, f), values(ccm.children))
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

  # better: ret = Dict{IT1,accumulate::Result_type} 
  ret =
    if length(ccm.children) > 0
      Dict(first(ccm.children)[1] => ("LOCAL", first(ccm.children)[1], apply_accumulate_record(first(ccm.children)[2], f, accumulate)))
    else
      Dict()
    end

  for (id, child) in ccm.children
    ret[id] = ("LOCAL", id, apply_accumulate_record(child, f, accumulate))
  end
  return (ccm.level, ccm.id, reduce(accumulate, map(x -> x[3], values(ret))), ret)
end

function apply_accumulate_record(ccm::ComposedImpactModel{IT1,IT2,DATA,CM}, f::Function, accumulate::Function) where {IT1,IT2,DATA,CM<:CoastalImpactUnit}

  # better: ret = Dict{IT1,accumulate::Result_type} 
  ret =
    if length(ccm.children) > 0
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

function apply_accumulate_store(ccm::ComposedImpactModel{IT1,IT2,DATA,CM}, f::Function, accumulate::Function, store::Function) where {IT1,IT2,DATA,CM<:CoastalImpactUnit}
  ret =
    if length(ccm.children) > 0
      #println(first(ccm.children)[1])
      Dict(first(ccm.children)[1] => apply_accumulate_store(first(ccm.children)[2], f, accumulate, store))
    else
      Dict()
    end

  for (id, child) in ccm.children
    #println(id)
    ret[id] = apply_accumulate_store(child, f, accumulate, store)
  end
  res = reduce(accumulate, values(ret))
  store(res, ccm)
  return res
end

function find(ccm::ComposedImpactModel{IT1,IT2,DATA,CM}, level_to_find::String, id_to_find::IT3) where {IT1,IT2,DATA,CM<:CoastalImpactUnit,IT3}
  if (ccm.level == level_to_find) && (convert(IT3, ccm.id) == id_to_find)
    return (true, [(level_to_find, id_to_find)])
  else
    for (child_id, child) in ccm.children
      if (find(child, level_to_find, id_to_find)[1] == true)
        return (true, [(ccm.level, ccm.id); find(child, level_to_find, id_to_find)[2]])
      end
    end
    return (false, [])
  end
end

function collect_data(ccm::ComposedImpactModel{IT1,IT2,DATA,CM}, outputs, metadata, metadatanames::Array{String}) where {IT1,IT2,DATA,CM<:CoastalImpactUnit}
  if (ccm.level in keys(outputs))
    row = [ccm.id; metadata]
    for n in fieldnames(DATA)
      push!(row, getfield(ccm.data, n))
    end
    rownames = copy(metadatanames)
    for name in fieldnames(DATA)
      push!(rownames, String(name))
    end
    if (ncol(outputs[ccm.level]) == 0)
      outputs[ccm.level] = DataFrame(Dict(rownames .=> row))
    else
      outputs[ccm.level] = [outputs[ccm.level]; DataFrame(Dict(rownames .=> row))]
    end
  end
  for (child_id, child) in ccm.children
    collect_data(child, outputs, metadata, metadatanames)
  end
end

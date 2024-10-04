export apply_accumulate, apply_accumulate_record, apply, apply_break, apply_break_store,
  apply_accumulate_store, apply_accumulate_store_multithread, apply_store, apply_store_multithread,
  find, collect_data

using DataFrames
using ThreadPools

function apply(ccm::ComposedImpactModel{IT1,IT2,DATA,CM}, f::Function) where {IT1,IT2,DATA,CM<:CoastalImpactUnit}
  foreach(x -> apply(x, f), values(ccm.children))
end

function apply_break(ccm::ComposedImpactModel{IT1,IT2,DATA,CM}, f::Function) where {IT1,IT2,DATA,CM<:CoastalImpactUnit}
  if (!f(ccm))
    foreach(x -> apply_break(x, f), values(ccm.children))
  end
end

function apply_break_store(ccm::ComposedImpactModel{IT1,IT2,DATA,CM}, f::Function, store::Function) where {IT1,IT2,DATA,CM<:CoastalImpactUnit}
  if (!f(ccm))
    foreach(x -> apply_break_store(x, f, store), values(ccm.children))
  end
  store(ccm)
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
    if (!haskey(ccm.children, id))
      ret[id] = apply_accumulate_record(child, f, accumulate)
    end
  end

  return (ccm.level, ccm.id, reduce(accumulate, map(x -> x[3], values(ret))), ret)
end

function apply_accumulate_store(ccm::ComposedImpactModel{IT1,IT2,DATA,CM}, f::Function, accumulate::Function, store::Function) where {IT1,IT2,DATA,CM<:CoastalImpactUnit}
  child_res = map(child -> apply_accumulate_store(child, f, accumulate, store), values(ccm.children))
  res = reduce(accumulate, child_res)
  store(res, ccm)
  return res
end

function apply_accumulate_store_multithread(ccm::ComposedImpactModel{IT1,IT2,DATA,CM}, f::Function, accumulate::Function, store::Function, mtlevel::String) where {IT1,IT2,DATA,CM<:CoastalImpactUnit}
  child_res =
    if (ccm.level == mtlevel)
      tmap(child -> apply_accumulate_store_multithread(child, f, accumulate, store, mtlevel), values(ccm.children))
    else
      map(child -> apply_accumulate_store_multithread(child, f, accumulate, store, mtlevel), values(ccm.children))
    end
  res = reduce(accumulate, child_res)
  store(res, ccm)
  return res
end

function apply_store(ccm::ComposedImpactModel{IT1,IT2,DATA,CM}, f::Function, store::Function) where {IT1,IT2,DATA,CM<:CoastalImpactUnit}
  foreach(x -> apply_store(x, f, store), values(ccm.children))
  store(ccm)
end

function apply_store_multithread(ccm::ComposedImpactModel{IT1,IT2,DATA,CM}, f::Function, store::Function, mtlevel::String) where {IT1,IT2,DATA,CM<:CoastalImpactUnit}
  if (ccm.level == mtlevel)
    tforeach(child -> apply_store_multithread(child, f, store, mtlevel), values(ccm.children))
  else
    foreach(child -> apply_store_multithread(child, f, store, mtlevel), values(ccm.children))
  end
  store(ccm)
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


function collect_data(ccm::ComposedImpactModel{IT1,IT2,DATA,CM}, outputs::Dict{String,DataFrame},
  output_row_names::Dict{String,Array{String}}, output_rows::Dict{String,Array{Any}}, metadata,
  metadatanames::Array{String}) where {IT1,IT2,DATA,CM<:CoastalImpactUnit}
  if (ccm.level in keys(outputs))
    if !(ccm.level in keys(output_rows))
      row = [ccm.id; metadata]
      for n in fieldnames(DATA)
        push!(row, getfield(ccm.data, n))
      end
      output_rows[ccm.level] = row
    else
      output_rows[ccm.level][1] = ccm.id
      i = 2
      for m in metadata
        output_rows[ccm.level][i] = m
        i += 1
      end
      for n in fieldnames(DATA)
        output_rows[ccm.level][i] = getfield(ccm.data, n)
        i += 1
      end
    end
    if !(ccm.level in keys(output_row_names))
      rownames = copy(metadatanames)
      for name in fieldnames(DATA)
        push!(rownames, String(name))
      end
      output_row_names[ccm.level] = rownames
    end
    if (ncol(outputs[ccm.level]) == 0)
      outputs[ccm.level] = DataFrame(Dict(output_row_names[ccm.level] .=> output_rows[ccm.level]))
    else
      outputs[ccm.level] = [outputs[ccm.level]; DataFrame(Dict(output_row_names[ccm.level] .=> output_rows[ccm.level]))]
    end
  end
  for (child_id, child) in ccm.children
    collect_data(child, outputs, output_row_names, output_rows, metadata, metadatanames)
  end
end

function collect_data(ccm::ComposedImpactModel{IT1,IT2,DATA,CM}, outputs::Dict{String,DataFrame}, metadata, metadatanames::Array{String}) where {IT1,IT2,DATA,CM<:CoastalImpactUnit}
  output_row_names = Dict{String,Array{String}}()
  output_rows = Dict{String,Array{Any}}()
  collect_data(ccm, outputs, output_row_names, output_rows, metadata, metadatanames)
end

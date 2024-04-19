using NCDatasets
using DataStructures
using DataFrames


export ccm_indicators_dataframes!, standardize_output!

"""
    load_hsps_nc(::Type{IT}, ::Type{DT}, filename::String)::Dict{IT,HypsometricProfile{DT}} where {IT<:Integer,DT<:Real}

Load a netcdf file into hypsometric profiles. IT is the indextype (an integer type which is used to adress a specific profile), DT is
the datatype (a floating point type which is used to store the data internally). Hypsometric profiles are not compressed.

# Examples
```julia-repl
julia> test = load_hsps_nc(Int32, Float32, "test.nc")
Dict{Int32, HypsometricProfile{Float32}} with 2716 entries:
  2108 => HypsometricProfile{Float32}(1.0, Float32[-5.0, -4.9, -4.8, -4.7, -4.6, -4.5, -4.4, -4.3, -4.2, -4.1  …  19.1, 19.2, 19.3, 19.4, 19.5, 19.6, 19.7, 19.8, 19.9, 20.0], Float32[0.0, 0.0, 0.0, 0.0, …
```
"""

#julia> typeof(res[4]["IRL"][4][1354][4][2046])
#Tuple{String, Int32, Tuple{Float32, Vector{Float32}, Vector{Float32}}}
#
#julia> typeof(res[4]["IRL"][4][1354])
#Tuple{String, Int32, Tuple{Float32, Vector{Float32}, Vector{Float32}}, Dict{Int32, Tuple{String, Int32, Tuple{Float32, Vector{Float32}, Vector{Float32}}}}}

function create_missing_columns!(df::DataFrame, column_names)
  nr = nrow(df)
  for cn in column_names
    if (!hasproperty(df, cn))
      insertcols!(df, cn => Missing)
    end
  end
  if (nr == 0 && nrow(df) > 0)
    delete!(df, [1])
  end
end

function create_df!(df::DataFrame, location, time::Int, indicator_data, column_names)
  df_ret = DataFrame(locationid=location, time=time)
  for i in 1:length(indicator_data)
    insertcols!(df_ret, column_names[i] => indicator_data[i])
  end
  for n in names(df)
    if (!(n in names(df_ret)))
      insertcols!(df_ret, n => missing)
    end
  end
  return df_ret
end

function insert_in_df!(df::DataFrame, loc, time::Int, indicator_data, column_names)::Bool
  if !("locationid" in names(df)) || !("time" in names(df))
    return false
  end

  for row in eachrow(df)
    if (row.locationid == loc) && (row.time == time)
      for i in 1:length(indicator_data)
        if (column_names[i] in names(df))
          row[column_names[i]] = indicator_data[i]
        else
          insertcols!(df, column_names[i] => indicator_data[i])
        end
      end
      return true
    end
  end

  return false
end

function ccm_indicators_dataframes!(dfs::Dict{String,DataFrame}, indicators_data::Tuple{String,ID_TYPE,RES_TYPE}, extractor::Function, indicator_names::Vector{String}, time::Int) where {ID_TYPE,RES_TYPE}
  if (indicators_data[1] in keys(dfs))
    extracted_data = extractor(indicators_data)
    if (length(extracted_data) != length(indicator_names))
      error("dimension mismatch: length($(extracted_data))!=length($(indicator_names)) as $(length(extracted_data))!=$(length(indicator_names))")
    end
    if (nrow(dfs[indicators_data[1]]) == 0)
      dfs[indicators_data[1]] = create_df!(DataFrame(), indicators_data[2], time, extracted_data, indicator_names)
    else
      if !(insert_in_df!(dfs[indicators_data[1]], indicators_data[2], time, extracted_data, indicator_names))
        dfs[indicators_data[1]] = [dfs[indicators_data[1]]; create_df!(dfs[indicators_data[1]], indicators_data[2], time, extracted_data, indicator_names)]
      end
    end
  end
end

function ccm_indicators_dataframes!(dfs::Dict{String,DataFrame}, indicators_data::Tuple{String,ID_TYPE,RES_TYPE,CD_TYPE}, extractor::Function, indicator_names::Vector{String}, time::Int) where {ID_TYPE,RES_TYPE,CD_TYPE}
  for (child_id, child_data) in indicators_data[4]
    ccm_indicators_dataframes!(dfs, child_data, extractor, indicator_names, time)
  end
  ccm_indicators_dataframes!(dfs, (indicators_data[1], indicators_data[2], indicators_data[3]), extractor, indicator_names, time)
end

function standardize_output!(dfs_output::Dict{String,DataFrame}, initial_columns)
  for (level, outputdata) in dfs_output
    select!(outputdata, initial_columns, sort(names(outputdata)))
  end
end

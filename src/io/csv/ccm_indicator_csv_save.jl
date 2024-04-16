using NCDatasets
using DataStructures

export load_hsps_nc

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
function save_ccm_indicators_csv(data :: Tuple{String, Tuple{Float32, Vector{Float32}, Vector{Float32}}, Dict{Any, Any}}, filenames :: Dict{String, String}, header::Bool) 

end



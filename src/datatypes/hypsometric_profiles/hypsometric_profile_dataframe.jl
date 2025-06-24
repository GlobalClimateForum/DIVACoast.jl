
function Base.convert(::Type{DataFrame}, hp::HypsometricProfile)
    return private_to_DF(hp)
end

function Base.convert(::Type{DataFrame}, hspfs::Dict{Int32, Main.DIVACoast.HypsometricProfile{Float32}})
    dfs = [begin
        hspf = private_to_DF(value)
        hspf.ID = fill(key, size(hspf, 1))
        hspf
        select!(hspf, :ID, :)
        end for (key, value) in hspfs
            ]
    return vcat(dfs...)
end

function private_to_DF(hpc::HypsometricProfileCollection)
    dfs = [begin
        hspf = private_to_DF(hp)
        hspf.ID = fill(hpc.ids[idx], size(hspf, 1)) 
        hspf
        select!(hspf, :ID, :)
        end for (idx, hp) in enumerate(hpc.profiles)
            ]
    return vcat(dfs...)
end

function private_to_DF(hspf::HypsometricProfile{DT}) where {DT<:Real}

    # Init DataFrame
    df = DataFrame()

    # Add elevation and cummulativeArea columns
    df.elevation = hspf.elevation
    df.cummulativeArea =  hspf.cummulativeArea
    df.width = fill(hspf.width, size(df, 1))
    
    # Get cummulativeExposure values
    exposures = getfield(hspf, :cummulativeExposure)
   
    # Add cummulativeExposure columns to DataFrame
    symbols = hasproperty(hspf, :exposureNames) ? hspf.exposureNames : []
    
    for i in 1:size(exposures, 2)
        colname = string(symbols[i])
        df[!, colname] = exposures[:, i]
    end
    return df
end

# Implement Tables.jl interface for HypsometricProfile
Tables.istable(::Type{<:HypsometricProfile}) = true
Tables.rowaccess(::Type{<:HypsometricProfile}) = true
Tables.rows(hp::HypsometricProfile) = Tables.rows(private_to_DF(hp))
Tables.schema(hp::HypsometricProfile) = Tables.schema(private_to_DF(hp))

# Implement Tables.jl interface for HypsometricProfileCollection
Tables.istable(::Type{<:HypsometricProfileCollection}) = true
Tables.rowaccess(::Type{<:HypsometricProfileCollection}) = true
Tables.rows(hpc::HypsometricProfileCollection) = Tables.rows(private_to_DF(hpc))
Tables.schema(hpc::HypsometricProfileCollection) = Tables.schema(private_to_DF(hpc))



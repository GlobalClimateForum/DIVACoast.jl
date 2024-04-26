export SLRWrapper, get_slr_value, fill_missing_values!

using NCDatasets

# SLRReader?
mutable struct SLRWrapper
    dataset::Dataset
    lon::Array{Real}
    lat::Array{Real}
    time::Array{Real}
    quantiles::Array{Real}
    variable::String
    data::Array{Union{Missing,Real}}
end

function SLRWrapper(file_name::String, variable::String, lon_name::String, lat_name::String, time_name::String, quantile_name::String)
    ds = Dataset(file_name, "r")

    if !haskey(ds.dim, lon_name)
        error("$file_name has no dimension $(lon_name)")
    end
    if !haskey(ds.dim, lat_name)
        error("$file_name has no dimension $(lat_name)")
    end
    if !haskey(ds.dim, time_name)
        error("$file_name has no dimension $(time_name)")
    end
    if !haskey(ds.dim, quantile_name)
        error("$file_name has no dimension $(quantile_name)")
    end

    if (!issorted(ds[lon_name]))
        error("dimension variable $(lon_name) in $file_name should be sorted increasingly.")
    end
    if (!issorted(ds[lat_name], by=x -> -x))
        error("dimension variable $(lat_name) in $file_name should be sorted decreasingly.")
    end
    if (!issorted(ds[time_name]))
        error("dimension variable $(time_name) in $file_name should be sorted increasingly.")
    end
    if (!issorted(ds[quantile_name]))
        error("dimension variable $(quantile_name) in $file_name should be sorted increasingly.")
    end

    SLRWrapper(ds, ds[lon_name], ds[lat_name], ds[time_name], ds[quantile_name], variable, ds[variable][:, :, :, :])
end


function get_slr_value(slrw::SLRWrapper, lon::Real, lat::Real, quantile::Real, time)

    index_lon = searchsortedfirst(slrw.lon, lon) <= size(slrw.lon, 1) ? searchsortedfirst(slrw.lon, lon) : size(slrw.lon, 1)
    index_lat = searchsortedfirst(slrw.lat, lat, rev=true) <= size(slrw.lat, 1) ? searchsortedfirst(slrw.lat, lat, rev=true) : size(slrw.lat, 1)
    index_qtl = searchsortedfirst(slrw.quantiles, quantile) <= size(slrw.quantiles, 1) ? searchsortedfirst(slrw.quantiles, quantile) : size(slrw.quantiles, 1)

    if time in slrw.time
        index_time = searchsortedfirst(slrw.time, time) <= size(slrw.time, 1) ? searchsortedfirst(slrw.time, time) : size(slrw.time, 1)
        return slrw.data[index_lon, index_lat, index_time, index_qtl]
    else
        index_time_after = searchsortedfirst(slrw.time, time) <= size(slrw.time, 1) ? searchsortedfirst(slrw.time, time) : size(slrw.time, 1)
        if (index_time_after <= 1)
            return 0.0
        else
            Δ_time = slrw.time[index_time_after] - slrw.time[index_time_after-1]
            r = (time - slrw.time[index_time_after-1]) / Δ_time
            Δ_slr = slrw.data[index_lon, index_lat, index_time_after, index_qtl] - slrw.data[index_lon, index_lat, index_time_after-1, index_qtl]
            return slrw.data[index_lon, index_lat, index_time_after-1, index_qtl] + r * Δ_slr
        end
    end
end

function fill_missing_values!(slrw::SLRWrapper)
    # fill all missing values at all timesteps/percentiles

    # first: collect all values, divide in missing and data values
    # we can use the first timestep and the first quantile to obtain the data/no-data grid
    # maybe: check if there is at least one timestep/quantile
    grid = slrw.data[:, :, 1, 1]
    data_gridcells = Array{Tuple{Float32,Float32}}(undef, 0)
    nodata_gridcells = Array{Tuple{Float32,Float32}}(undef, 0)

    for lon_index in 1:size(slrw.lon, 1)
        for lat_index in 1:size(slrw.lat, 1)
            if grid[lon_index, lat_index] === missing
            else
                push!(data_gridcells, (slrw.lon[lon_index], slrw.lat[lat_index]))
            end
        end
    end

    # NN matching as we have done for surges ...
    # ...

    # and fill up missing data
    for lon_index in 1:size(slrw.lon, 1)
        for lat_index in 1:size(slrw.lat, 1)
            for time_index in 1:size(slrw.time, 1)
                for qtl_index in 1:size(slrw.quantiles, 1)
                    if slrw.data[lon_index, lat_index, time_index, qtl_index] === missing
                        # fill up the data
                        # check if missing data is in the set of matched grid cells?
                        # the missing values should be the same for each quantile/timestep combination, but we cannot be sure?
                    end
                end
            end
        end
    end

end
export SLRScenarioReader, get_slr_value, fill_missing_values!, get_slr_value_from_grid_cell,
       quantile_index, lon_index, lat_index

using NCDatasets

"""
Creates a SLR-Scenario reader around a dataset (NetCDF) using dataset specific variable names for variable (e.g., "SeaLevelRise"), latitude, longitude, time, and quantile
After the Wrapper structure was initialized dataset specific functions can be used (e.g, get_slr_value)
"""
mutable struct SLRScenarioReader
    dataset::Dataset
    lon::Array{Real}
    lat::Array{Real}
    time::Array{Real}
    quantiles::Array{Real}
    variable::String
    data::Array{Union{Missing,Real}}
end

"""
Creates a SLRScenarioReader reader around a dataset (NetCDF) using dataset specific variable names for variable (e.g., "SeaLevelRise"), latitude, longitude, time, and quantile
After the Wrapper structure was initialized dataset specific functions can be used (e.g, get_slr_value)
"""
function SLRScenarioReader(file_name::String, variable::String, lon_name::String, lat_name::String, time_name::String, quantile_name::String)
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

    SLRScenarioReader(ds, ds[lon_name], ds[lat_name], ds[time_name], ds[quantile_name], variable, ds[variable][:, :, :, :])
end

"""
Gets the Sea Level Rise value at a specific location (lon, lat) in a specific quantile at a specific time.
"""
function get_slr_value(slrw::SLRScenarioReader, lon::Real, lat::Real, quantile::Real, time)

    index_lon = searchsortedfirst(slrw.lon, lon) <= size(slrw.lon, 1) ? searchsortedfirst(slrw.lon, lon) : size(slrw.lon, 1)
    index_lat = searchsortedfirst(slrw.lat, lat, rev=true) <= size(slrw.lat, 1) ? searchsortedfirst(slrw.lat, lat, rev=true) : size(slrw.lat, 1)
    index_qtl = searchsortedfirst(slrw.quantiles, quantile) <= size(slrw.quantiles, 1) ? searchsortedfirst(slrw.quantiles, quantile) : size(slrw.quantiles, 1)

    if time in slrw.time
        index_time = searchsortedfirst(slrw.time, time) <= size(slrw.time, 1) ? searchsortedfirst(slrw.time, time) : size(slrw.time, 1)
        slr_result = slrw.data[index_lon, index_lat, index_time, index_qtl]
        if slr_result===missing slr_result=0.0 end
        return slr_result
    else
        index_time_after = searchsortedfirst(slrw.time, time) <= size(slrw.time, 1) ? searchsortedfirst(slrw.time, time) : size(slrw.time, 1)
        if (index_time_after <= 1)
            return 0.0
        else
            Δ_time = slrw.time[index_time_after] - slrw.time[index_time_after-1]
            r = (time - slrw.time[index_time_after-1]) / Δ_time
            Δ_slr = slrw.data[index_lon, index_lat, index_time_after, index_qtl] - slrw.data[index_lon, index_lat, index_time_after-1, index_qtl]
            slr_result = slrw.data[index_lon, index_lat, index_time_after-1, index_qtl] + r * Δ_slr
            if slr_result===missing slr_result=0.0 end
            return slr_result
        end
    end
end

"""
Gets the Sea Level Rise value at a specific cell (index_lon, index_lat) in a specific quantile (given by index_qtl) at a specific time.
Faster than the previous 
"""
function get_slr_value_from_grid_cell(slrw::SLRScenarioReader, index_lon::Int, index_lat::Int, index_qtl::Int, time)

#    index_lon = searchsortedfirst(slrw.lon, lon) <= size(slrw.lon, 1) ? searchsortedfirst(slrw.lon, lon) : size(slrw.lon, 1)
#    index_lat = searchsortedfirst(slrw.lat, lat, rev=true) <= size(slrw.lat, 1) ? searchsortedfirst(slrw.lat, lat, rev=true) : size(slrw.lat, 1)
#    index_qtl = searchsortedfirst(slrw.quantiles, quantile) <= size(slrw.quantiles, 1) ? searchsortedfirst(slrw.quantiles, quantile) : size(slrw.quantiles, 1)

    if time in slrw.time
        index_time = searchsortedfirst(slrw.time, time) <= size(slrw.time, 1) ? searchsortedfirst(slrw.time, time) : size(slrw.time, 1)
        slr_result = slrw.data[index_lon, index_lat, index_time, index_qtl]
        if slr_result===missing slr_result=0.0 end
        return slr_result
    else
        index_time_after = searchsortedfirst(slrw.time, time) <= size(slrw.time, 1) ? searchsortedfirst(slrw.time, time) : size(slrw.time, 1)
        if (index_time_after <= 1)
            return 0.0
        else
            Δ_time = slrw.time[index_time_after] - slrw.time[index_time_after-1]
            r = (time - slrw.time[index_time_after-1]) / Δ_time
            Δ_slr = slrw.data[index_lon, index_lat, index_time_after, index_qtl] - slrw.data[index_lon, index_lat, index_time_after-1, index_qtl]
            slr_result = slrw.data[index_lon, index_lat, index_time_after-1, index_qtl] + r * Δ_slr
            if slr_result===missing slr_result=0.0 end
            return slr_result
        end
    end
end

quantile_index(slrw::SLRScenarioReader, quantile::Real) = searchsortedfirst(slrw.quantiles, quantile) <= size(slrw.quantiles, 1) ? searchsortedfirst(slrw.quantiles, quantile) : size(slrw.quantiles, 1)
lon_index(slrw::SLRScenarioReader, lon::Real) = searchsortedfirst(slrw.lon, lon) <= size(slrw.lon, 1) ? searchsortedfirst(slrw.lon, lon) : size(slrw.lon, 1)
lat_index(slrw::SLRScenarioReader, lat::Real) = searchsortedfirst(slrw.lat, lat, rev=true) <= size(slrw.lat, 1) ? searchsortedfirst(slrw.lat, lat, rev=true) : size(slrw.lat, 1)

function cursor(index, width, b)

    function bound(v, bound, infinite)
        if v > bound || v <= 0
            if infinite
                v = v > bound ? (v - bound) : (bound + v)
            else 
                v = v > bound ? bound : 1
            end
            return v
        else
            return v
        end
    end

    xbound, ybound = b
    bounded = (x, y) -> (bound(x, xbound, true), bound(y, ybound, false))
    x, y = index
    # weights = []
    result = []
    for (kx, ky) in Iterators.product((width *-1):width, (width *-1):width)
        i_bounded = bounded((x + kx), (y + ky))
        if !(i_bounded in result)
            push!(result, i_bounded)
            # push!(weights, weight(kx, ky)) 
        end
    end
    return result #,weights
end

function fill_missing_values!(slrw::SLRScenarioReader)

    ilon, ilat, itime, iquant = size(slrw.data)
    # Iterate every dimension in slrw.data
    for lon in 1:ilon, lat in 1:ilat, time in 1:itime, quant in 1:iquant

        # If value is missing -> calculate value
        if ismissing(slrw.data[lon, lat, time, quant]) # add constraining coord list?
            
            calc_value = nothing
            cursor_width = 1
            
            while isnothing(calc_value) 
                
                cursor_ = cursor((lon, lat), cursor_width, (ilon, ilat)) #,weights
                values = []

                for (lon_, lat_) in cursor_
                    value = slrw.data[lon_, lat_, time, quant]
                    if !ismissing(value)
                        push!(values, value)
                    end
                end

                if isempty(values)
                    cursor_width += 1
                else
                    slrw.data[lon, lat, time, quant] =  mean(values)
                end            
            end

            println(slrw.data[lon, lat, time, quant])

        end

    end
  
    # NN matching  ...
    # ...

   
    # and fill up missing data
    # for lon_index in 1:size(slrw.lon, 1)
    #     for lat_index in 1:size(slrw.lat, 1)
    #         for time_index in 1:size(slrw.time, 1)
    #             for qtl_index in 1:size(slrw.quantiles, 1)
    #                 if slrw.data[lon_index, lat_index, time_index, qtl_index] === missing
    #                     # fill up the data
    #                     # check if missing data is in the set of matched grid cells?
    #                     # the missing values should be the same for each quantile/timestep combination, but we cannot be sure?
    #                 end
    #             end
    #         end
    #     end
    # end

end
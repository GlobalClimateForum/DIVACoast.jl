export SLRWrapper, get_slr_value

using NCDatasets


mutable struct SLRWrapper
    dataset::Dataset
    lon::Array{Real}
    lat::Array{Real}
    time::Array{Real}
    quantiles::Array{Real}
    data::Array{Real}
    variable_loaded::String
end

function SLRWrapper(file_name::String, lon_name::String, lat_name::String, time_name::String, quantile_name::String)
    ds = Dataset(file_name, "r")

    if !haskey(ds.dim, lon_name)
        error("$filename has no dimension $(lon_name)")
    end
    if !haskey(ds.dim, lat_name)
        error("$filename has no dimension $(lat_name)")
    end
    if !haskey(ds.dim, time_name)
        error("$filename has no dimension $(time_name)")
    end
    if !haskey(ds.dim, quantile_name)
        error("$filename has no dimension $(quantile_name)")
    end

    if (!issorted(ds[lon_name]))
        error("dimension variable $(lon_name) in $filename should be sorted increasingly.")
    end
    if (!issorted(ds[lat_name], by=x -> -x))
        error("dimension variable $(lat_name) in $filename should be sorted decreasingly.")
    end
    if (!issorted(ds[time_name]))
        error("dimension variable $(time_name) in $filename should be sorted increasingly.")
    end
    if (!issorted(ds[quantile_name]))
        error("dimension variable $(quantile_name) in $filename should be sorted increasingly.")
    end

    SLRWrapper(ds, ds[lon_name], ds[lat_name], ds[time_name], ds[quantile_name], Array{Float32}(undef, 0), "")
end


function get_slr_value(slrw::SLRWrapper, variable::String, lon::Real, lat::Real, quantile::Real, time)::Float32
    if (variable == "")
        return 0.0
    end

    if (slrw.variable_loaded != variable)
        slrw.variable_loaded = variable
        slrw.data = slrw.dataset[variable][:, :, :, :]
    end

    index_lon = searchsortedfirst(slrw.lon, lon) <= size(slrw.lon, 1) ? searchsortedfirst(slrw.lon, lon) : size(slrw.lon, 1)
    index_lat = searchsortedfirst(slrw.lat, lat, rev=true) <= size(slrw.lat, 1) ? searchsortedfirst(slrw.lat, lat, rev=true) : size(slrw.lat, 1)
    index_qtl = searchsortedfirst(slrw.quantiles, quantile) <= size(slrw.quantiles, 1) ? searchsortedfirst(slrw.quantiles, quantile) : size(slrw.quantiles, 1)

    if time in slrw.time
        index_time = searchsortedfirst(slrw.time, time) <= size(slrw.time, 1) ? searchsortedfirst(slrw.time, time) : size(slrw.time, 1)
        return slrw.data[index_lon, index_lat, index_time, index_qtl]
    else
        index_time_after = searchsortedfirst(slrw.time, time) <= size(slrw.time, 1) ? searchsortedfirst(slrw.time, time) : size(slrw.time, 1)
        if (index_time_after<=1)
            return 0.0
        else 
            Δ_time = slrw.time[index_time_after] - slrw.time[index_time_after-1]
            r = (time - slrw.time[index_time_after-1])/Δ_time
            Δ_slr = slrw.data[index_lon, index_lat, index_time_after, index_qtl] - slrw.data[index_lon, index_lat, index_time_after-1, index_qtl]
            return slrw.data[index_lon, index_lat, index_time_after-1, index_qtl] + r * Δ_slr 
        end
    end
end

"Get the WKT of an Integer EPSG code"
function epsg2wkt(epsgcode::Int)
    srs = GDAL.osrnewspatialreference(C_NULL)
    GDAL.osrimportfromepsg(srs, epsgcode)
    wkt_ptr = Ref(Cstring(C_NULL))
    GDAL.osrexporttowkt(srs, wkt_ptr)
    return unsafe_string(wkt_ptr[])
end

"Get the WKT of an Proj string"
function proj2wkt(projstring::AbstractString)
    srs = GDAL.osrnewspatialreference(C_NULL)
    GDAL.osrimportfromproj4(srs, projstring)
    wkt_ptr = Ref(Cstring(C_NULL))
    GDAL.osrexporttowkt(srs, wkt_ptr)
    return unsafe_string(wkt_ptr[])
end

function wkt2wkt(wktstring::AbstractString)
    srs = GDAL.osrnewspatialreference(C_NULL)
    GDAL.osrimportfromwkt(srs, [wktstring])
    wkt_ptr = Ref(Cstring(C_NULL))
    GDAL.osrexporttowkt(srs, wkt_ptr)
    return unsafe_string(wkt_ptr[])
end

"""Parse CRS string into WKT."""
function str2wkt(crs_string::AbstractString)
    if startswith(crs_string, "+proj=")
        return proj2wkt(crs_string)
    elseif startswith(crs_string, "EPSG:")
        epsg_code = parse(Int, crs_string[findlast("EPSG:", crs_string).stop+1:end])
        return epsg2wkt(epsg_code)
    else
        # Fallback method to validate string
        wkt = wkt2wkt(crs_string)
        return wkt
    end
end

"Set CRS on SparseGeoArray by epsgcode"
epsg!(sga::SparseGeoArray, epsgcode::Int) = crs!(sga, GFT.EPSG(epsgcode))
epsg!(sga::SparseGeoArray, epsgstring::AbstractString) = crs!(sga, GFT.EPSG(epsgstring))

function crs!(sga::SparseGeoArray, crs::GFT.CoordinateReferenceSystemFormat)
    sga.crs = convert(GFT.WellKnownText, GFT.CRS(), crs)
    sga
end

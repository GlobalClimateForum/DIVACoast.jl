"""
        epsg2wkt(epsgcode::Int)

Convert an EPSG code to WKT (WellKnownText) format.

# Arguments
- `epsgcode::Int`: The EPSG code to convert.

# Returns
- A string containing the WKT representation of the EPSG code.

# Example
```julia
wkt = epsg2wkt(4326)
println(wkt)
```
"""
function epsg2wkt(epsgcode::Int)
    srs = GDAL.osrnewspatialreference(C_NULL)
    GDAL.osrimportfromepsg(srs, epsgcode)
    wkt_ptr = Ref(Cstring(C_NULL))
    GDAL.osrexporttowkt(srs, wkt_ptr)
    return unsafe_string(wkt_ptr[])
end

"""
        proj2wkt(projstring::AbstractString)
Convert a PROJ string to WKT (WellKnownText) format.
# Arguments
- `projstring::AbstractString`: The PROJ string to convert.

# Returns
- A string containing the WKT representation of the PROJ string.

# Example
```julia
wkt = proj2wkt("+proj=longlat +datum=WGS84 +no_defs")
println(wkt)        
```
"""
function proj2wkt(projstring::AbstractString)
    srs = GDAL.osrnewspatialreference(C_NULL)
    GDAL.osrimportfromproj4(srs, projstring)
    wkt_ptr = Ref(Cstring(C_NULL))
    GDAL.osrexporttowkt(srs, wkt_ptr)
    return unsafe_string(wkt_ptr[])
end

"""
        wkt2wkt(wktstring::AbstractString)
Convert a WKT (WellKnownText) string to WKT format, ensuring it is well-formatted.
# Arguments
- `wktstring::AbstractString`: The WKT string to convert.
# Returns
- A string containing the well-formatted WKT representation of the input WKT string.

# Example
```julia
wkt = wkt2wkt("GEOGCS[\"WGS 84\", DATUM[\"WGS_1984\", SPHEROID[\"WGS 84\", 6378137, 298.257223563]], PRIMEM[\"Greenwich\", 0], UNIT[\"degree\", 0.0174532925199433]]")
println(wkt)
```
"""
function wkt2wkt(wktstring::AbstractString)
    srs = GDAL.osrnewspatialreference(C_NULL)
    GDAL.osrimportfromwkt(srs, [wktstring])
    wkt_ptr = Ref(Cstring(C_NULL))
    GDAL.osrexporttowkt(srs, wkt_ptr)
    return unsafe_string(wkt_ptr[])
end

"""
        str2wkt(crs_string::AbstractString)
Convert a CRS string (PROJ, EPSG, or WKT) to WKT format.
# Arguments
- `crs_string::AbstractString`: The CRS string to convert, which can be in PROJ, EPSG, or WKT format.
# Returns
- A string containing the WKT representation of the CRS string.
# Example
```julia
wkt = str2wkt("+proj=longlat +datum=WGS84 +no_defs")
println(wkt)
wkt = str2wkt("EPSG:4326")
println(wkt)
```
"""
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

"""
        epsg!(sga::SparseGeoArray, epsgcode::Int)
        epsg!(sga::SparseGeoArray, epsgstring::AbstractString)
Set the EPSG code for a SparseGeoArray.

# Arguments
- `sga::SparseGeoArray`: The SparseGeoArray to set the EPSG code for.
- `epsgcode::Int`: The EPSG code to set.
- `epsgstring::AbstractString`: The EPSG code as a string to set.

# Returns
- The updated SparseGeoArray with the new EPSG code set.

# Example
```julia
sga = SparseGeoArray(...)
epsg!(sga, 4326)  # Set EPSG code to 4326
epsg!(sga, "EPSG:4326")  # Set EPSG code using string
```
"""
epsg!(sga::SparseGeoArray, epsgcode::Int) = crs!(sga, GFT.EPSG(epsgcode))
epsg!(sga::SparseGeoArray, epsgstring::AbstractString) = crs!(sga, GFT.EPSG(epsgstring))

function crs!(sga::SparseGeoArray, crs::GFT.CoordinateReferenceSystemFormat)
    sga.crs = convert(GFT.WellKnownText, GFT.CRS(), crs)
    sga
end

```@meta
CollapsedDocStrings = true
Description = "DIVACoast.jl is a Julia library for coastal impact and adaptation modelling. The library provides data types and algorithms to quickly script assessments for different **coastal impact and adaptation** research questions. DIVACoast.jl is provided by the [Global Climate Forum](https://globalclimateforum.org/) via [GitHub](https://github.com/globalclimateforum/DIVACoast.jl)."
```
# GeoData utilities

## SparseGeoArray (SGA)
Within `DIVACoast.jl`, **Gridded geodata** is stored and processed using the `SparseGeoArray` data structure. This structure retains the necessary geospatial meta-information for accurate referencing and stores the data in a memory-efficient sparse array format. By storing only non-empty grid cells, it is well-suited for coastal datasets, where large areas—such as open ocean or inland regions—often contain no or non relevant data for the analysis.

```@docs
Main.DIVACoast.SparseGeoArray
```
### SparseGeoArrays - Construct 
`SparseGeoArrays` can be constructing by multiple ways:

**From GeoTIFF**
```julia
Main.DIVACoast.SparseGeoArray{Float32, Int32}("path/to/file.tif")
```

**Construct (empty)**\
**Note:** _If you init an empty `SparseGeoArray` you need to specify the geospatial-metadata yourself to perform geo-Operations._
```julia 
Main.DIVACoast.SparseGeoArray{Float32, Int32}()
sga[(x, y)] = value # Fill the SparseGeoArray
```
**Construct (empty)** with meta-information **from another** `SparseGeoArray`
```@docs
Main.DIVACoast.emptySGAfromSGA
```

**Manually** construct a `SparseGeoArray`\
If you have your data as a dictionary and know the georeferencing, you can construct it directly:
```julia
sga = Main.DIVACoast.SparseGeoArray(
    data,          # Dict{Tuple{Int,Int}, Float64}
    nodatavalue,   # e.g., -9999.0
    affine_map,    # CoordinateTransformations.AffineMap
    crs,           # GeoFormatTypes.WellKnownText
    metadata,      # Dict{String,Any}
    xsize, ysize,  # grid dimensions
    projref,       # projection string
    circular,      # Bool
    filename       # String
)
```

### SparseGeoArray - Operations
A set of core spatial operations is provided for `SparseGeoArray` objects, enabling manipulation and analysis of gridded exposure data. These functions allow you to combine, compare, and summarize spatial datasets efficiently:

```@docs
Main.DIVACoast.sga_union
Main.DIVACoast.sga_intersect
Main.DIVACoast.sga_diff
Main.DIVACoast.sga_summarize_within
```

There are multiple options to access the data based on an index or on a coordinate.

#### Indexing `SparseGeoArrays`
```@docs
Main.DIVACoast.getindex
Main.DIVACoast.coords
Main.DIVACoast.indices
```

#### Neighbourhood and Distance Functions
```@docs
Main.DIVACoast.nh4
Main.DIVACoast.nh8
Main.DIVACoast.distance
Main.DIVACoast.go_direction
```

#### Spatial Extent
```@docs
Main.DIVACoast.bounding_boxes
Main.DIVACoast.area
Main.DIVACoast.get_extent
```

#### Coordinate Reference System (CRS)
```@docs
Main.DIVACoast.epsg2wkt
Main.DIVACoast.proj2wkt
Main.DIVACoast.str2wkt
Main.DIVACoast.epsg!
Main.DIVACoast.is_rotated
Main.DIVACoast.bbox!
```

## GeoTIFF
As described above `SparseGeoArray` is the structure used by `DIVACoast.jl` to handle GeoData. In addition, `DIVACoast.jl` provides several functions
to read, modify and export files in the common GeoData Format `.geotiff`.

### Operations
The following operations process (multiple) GeoTIFF rasters using a user-defined function, enabling custom analysis or aggregation across several input files.

| Function            | Inputs              | Output   | Operation                                                              |
| ------------------- | ------------------- | -------- | ---------------------------------------------------------------------- |
| `geotiff_connect`   | 2 rasters, function | 1 raster | Combine two rasters pixel-wise using a function                        |
| `geotiff_transform` | 1 raster, function  | 1 raster | Transform one raster pixel-wise using a function                       |
| `geotiff_collect`   | mask, rasters, func | (custom) | Collect values from multiple rasters and mask, process with a function |

```@docs
Main.DIVACoast.geotiff_connect
Main.DIVACoast.geotiff_transform
Main.DIVACoast.geotiff_collect
```

## Point Data
GeoData is often provided by coordinates. In most cases you can transform the provided data into a `DataFrame` object with a coordinate or langitude and latitude column. `DIVACoast.jl` provides a structure called `Neighbour` to perform Nearest Neighbour searches on `DataFrames` in a convinient and efficient way.

```@docs
Main.DIVACoast.Neighbour
```
Nearest Neighbour search can be performed using:

```@docs
Main.DIVACoast.nearest
Main.DIVACoast.nearest_coord
```
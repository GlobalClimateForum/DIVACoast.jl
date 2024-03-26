# jdiva
>provided by: [Global Climate Forum](https://globalclimateforum.org)

jdiva is a julia library for economic modelling of coastal sea-level rise impacts and adaptation. It provides a complete tool chain from geodatatypes to datatypes that allow different approaches of coasplain modelling to
algorithms that compute flood impacts, erosion and wetland change. 

## Coastal profiles

## Hypsometric profiles
```@docs
Main.jdiva.exposure_below_bathtub
Main.jdiva.compress!
Main.jdiva.expected_damage_bathtub_standard_ddf
Main.jdiva.exposure_below_attenuated
Main.jdiva.expected_damage_bathtub
Main.jdiva.attenuate
```

## GeoUtils

## SparseGeoArray
*lightweight data structure to store geodata*

```@docs
Main.jdiva.SparseGeoArray
Base.getindex
Main.jdiva.coords
Main.jdiva.indices 
```

### Geospatial analysis
*tools to run geopspatial analysis*

```@docs
Main.jdiva.nh4
Main.jdiva.distance
Main.jdiva.go_direction
Main.jdiva.bounding_boxes
Main.jdiva.bbox!
Main.jdiva.is_rotated
```
### Geodata handling
*tools to handle geodata*

```@docs
Main.jdiva.epsg!
Main.jdiva.proj2wkt 
Main.jdiva.epsg2wkt 
Main.jdiva.str2wkt
```

## netCDF
*utitlities to work with netCDF-files*
```@docs
Main.jdiva.load_hsps_nc
```





# About

jdiva is a julia library for coastal impact and adaptation modelling. The library provides data types and algorithms to script assessment runs for different coastal impact and adaptation research questions.
The library is __currently under development__ and provided by the [Global Climate Forum](https://globalclimateforum.org/) via [GitLab](https://gitlab.com/globalclimateforum/diva_library).

# Download & Installation

Ensure you have Julia installed on your system. You can download Julia from the official [julia website](https://julialang.org). 

You can get the latest (unstable) version by cloning the library repository to your machine. Since there is not stable version at the moment you have to switch to the development branch afterwards.

```
git clone https://gitlab.com/globalclimateforum/diva_library.git
git checkout development
```

The DIVA library has several dependencies with multiple ways to install them:

1. __Install requirements to local environment__
    If you want to install all required packages to your local environment, easiest is to execute the `install_packages.jl` script within the parent directory of the repository.

2. __Instantiate diva_library project__
    If you want to use the diva_library project environment you can execute the `jdiva_env.jl` script in the './src' directory. The script will activate the project and install all (instantiate) dependencies automatically to a environment called diva_library.

3. __Setting environent variables__
    We recommend to setup environment variables for the DIVA library directory and your data directory.
    ```

You can include the diva library in your script by:
```
include(<path_to_diva>/diva_library/src/jdiva_env.jl)
include(<path_to_diva>/diva_library/src/jdiva_lib.jl); using .jdiva
```

# Data structures
## Impact Model
```@docs
Main.jdiva.ComposedImpactModel
Main.jdiva.LocalCoastalImpactModel
```

## Hypsometric Profile
```@docs
Main.jdiva.HypsometricProfile
Main.jdiva.load_hsps_nc
```

## Adapt
```@docs
Main.jdiva.add_static_exposure!
Main.jdiva.add_dynamic_exposure!
Main.jdiva.remove_static_exposure!
Main.jdiva.remove_dynamic_exposure!
Main.jdiva.sed!
Main.jdiva.sed_above!
Main.jdiva.sed_below!
Main.jdiva.remove_below!
Main.jdiva.add_above!
Main.jdiva.add_between!
Main.jdiva.compress!
```

### Analysis
### Calculate Damages
```@docs
Main.jdiva.expected_damage_bathtub_standard_ddf
Main.jdiva.expected_damage_bathtub
```

### Get Exposure
```@docs
Main.jdiva.exposure_below_bathtub
Main.jdiva.exposure_below_attenuated
Main.jdiva.attenuate
```

### Statistics
```@docs
Main.jdiva.estimate_gumbel_distribution
Main.jdiva.estimate_frechet_distribution
Main.jdiva.estimate_gev_distribution
Main.jdiva.estimate_weibull_distribution

Main.jdiva.estimate_gd_negative_distribution
Main.jdiva.estimate_gd_positive_distribution
Main.jdiva.estimate_gp_distribution
Main.jdiva.estimate_exponential_distribution
```

## Data
### SLRWrapper
```@docs
Main.jdiva.SLRWrapper
Main.jdiva.get_slr_value
Main.jdiva.get_slr_value_from_cell
```
### SSPWrapper
```@docs
Main.jdiva.SSPWrapper
```

## Spatial Operations

### SparseGeoArray (SGA)
```@docs
Main.jdiva.SparseGeoArray
Main.jdiva.getindex
Main.jdiva.coords
Main.jdiva.indices
Main.jdiva.nh4
Main.jdiva.nh8
Main.jdiva.distance
Main.jdiva.go_direction
Main.jdiva.bounding_boxes
Main.jdiva.area
Main.jdiva.emptySGAfromSGA
Main.jdiva.get_extent
Main.jdiva.sga_union
Main.jdiva.sga_intersect
Main.jdiva.sga_diff
Main.jdiva.sga_summarize_within
Main.jdiva.minumum_mean
Main.jdiva.get_closest_value
Main.jdiva.get_box_around
Main.jdiva.epsg2wkt
Main.jdiva.proj2wkt
Main.jdiva.str2wkt
Main.jdiva.epsg!
Main.jdiva.is_rotated
Main.jdiva.bbox!
```

### Spatial-Relationship
```@docs
Main.jdiva.Neighbour
Main.jdiva.nearest
Main.jdiva.nearest_coord
Main.jdiva.coords_to_wide
```
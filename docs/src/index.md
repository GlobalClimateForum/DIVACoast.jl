# About
DIVACoast.jl is a julia library for coastal impact and adaptation modelling. The library provides data types and algorithms to quickly script assessments for different coastal impact and adaptation research questions. DIVACoast.jl is provided by the [Global Climate Forum](https://globalclimateforum.org/) via [GitLab](https://gitlab.com/globalclimateforum/diva_library).

# Download & Installation
Ensure you have Julia installed on your system. You can download Julia from the official [julia website](https://julialang.org). 

You can get the latest (unstable) version by cloning the library repository to your machine. Since there is no stable version at the moment you have to switch to the development branch afterwards.

```
git clone https://gitlab.com/globalclimateforum/DIVACoast.jl.git
git checkout development
```

The DIVA library has several dependencies with multiple ways to install them:

1. __Install requirements to local environment__
    If you want to install all required packages to your local environment, easiest is to execute the `install_packages.jl` script within the parent directory of the repository.

2. __Instantiate diva_library project__
    If you want to use the diva_library project environment you can execute the `DIVACoast.jl` script in the './src' directory. The script will activate the project and install all (instantiate) dependencies automatically to a environment called diva_library.

3. __Setting environment variables__
    We recommend to setup environment variables for the DIVA library directory and your data directory.
    ```

You can include the diva library in your script by:
```
include(<path_to_diva>/diva_library/src/DIVACoast.jl); using .jdiva
```

# Core concepts

The key concept of `DIVACoast.jl` is the concept of risk, which, following the definition of the Intergovernmental Panel on Climate Change (IPCC), is constituted by the three components of hazard, exposure and vulnerability (Oppenheimer et al., 2019; Wong et al., 2014). While on the long run the package is meant to serve multiple coastal risks including the risk of flooding, erosion, salinity intrusion and wetland change, the current release concentrates on flood risk. 

## Flood risk

Coastal flood risk assessment involves at least the following five components: 

- **Sea-level hazard**, including mean sea-levels (MSL) and extreme sea-levels (ESL) from tides, surges, waves, river run-off and their interactions;
- **Hazard propagation**, which refers to the transformation of the **sea-level hazard** to the **flood hazard**. This includes the propagation of mean and extreme sea-level onto the shore and the floodplain, including their interaction with natural (e.g., dunes) and artificial (e.g., dikes) defences;
- **Flood hazard**, refers to the flood characteristics found at a specific flooded location. Currently `DIVACoast.jl` is limited to the characteristic of maximum water depth.
- **Flood exposure** in terms of area, people and coastal assets potentially threatened by these hazards; and
- **Flood vulnerability**, which refers to the  propensity of the exposure to be adversely affected by the flood hazard (IPCC, 2014b).

## External Drivers

- Sea-level rise: changes the hazard
- Socio-economic development: changes exposure and vulnerability

## Internal adaptation 

- protection: affects the hazard propagation
- retreat: reduces exposure
- accommodate: reduces vulnerability


# Coastal Flood Model

The main data structure of `DIVACoast.jl` is the one of a coastal model, which refers to a specific representation of the coast in terms of the three components of risk. As the current version of `DIVACoast.jl` focuses on flood risk, we limit ourselves to presenting the data structure of a `CoastalFloodModel`. Future versions of the library will alos include `CoastalErosionModel` and `CoastalWetlandsModel` etc. 

<!-- Change to CoastalFloodModel -->
```@docs
Main.DIVACoast.LocalCoastalImpactModel
Main.DIVACoast.ComposedImpactModel
```

A `CoastalFloodModel` is defined as <font color="red">This is only a proposition of how we could change the code to get more consistent with our terminology!</font>
```
mutable struct CoastalFloodModel{DT<:Real,IDT,DATA} <: CoastalModel
  id::IDT
  esl_hazard::Distribution
  exposure::HypsometricProfile{DT}
  propagation_model::FloodPropagationModel
  protection_level::Real
  vulnerability::Array{Function}
  data::DATA
end
```
# Exposure as Hypsometric Profile

A hypsometric profile represents a cross-section of a landscape. It helps to understand terrain structure and, therefore, flood exposure.
For DIVACoast, it serves as the underlying data structure for the physical model. The profile is derived from a Digital Elevation Model (DEM), incorporating hydrological connectivity, where each elevation increment corresponds to the cumulative area exposed as floodwaters rise.
Without adaptation measures or attenuative land cover, this follows the bathtub model, where water first inundates low-lying areas before reaching higher elevations. In conclusion, the profile **quantifies the extent of land or infrastructure affected** at each flood stage (elevation increment).

## Initializing Hypsometric Profiles
In DIVACoast Hypsometric Profiles can either be initialized manually or be generated from a NetCDF file.
```@docs
Main.DIVACoast.HypsometricProfile
Main.DIVACoast.load_hsps_nc
Main.DIVACoast.to_hypsometric_profile
Base.:+
```
## Querying Hypsometric Profiles
```@docs
Main.DIVACoast.exposure_below_bathtub
Main.DIVACoast.exposure_below_attenuated
Main.DIVACoast.attenuate
```
## Modifying HypsometricProfiles
When modeling flood events, we typically analyze **multiple scenarios**, which require modifications to the physical model.
For example, implementing a dike in the physical model alters the hypsometric profile, modifying coastal topography and changing the hydrological connectivity. As a result, floodwaters must reach a higher threshold before inundating certain areas. Similarly, we can also alter the exposure of certain entities. In DIVACoast, we differentiate between two types of exposure:

1. **Static Exposure**
- Represents entities that cannot be relocated and will be flooded once a certain water level is reached.
- Example: *Agricultural land, which remains fixed and will always be affected at a given flood depth*
2. **Dynamic Exposure**
- Represents entities that can be relocated or adapt over time.
- Example: *People who may move to higher elevations. GDP decreasing in an area when exposed to flooding.*

To express those process in DIVACoast, we provide the following functionalities.

```@docs
Main.DIVACoast.add_static_exposure!
Main.DIVACoast.add_dynamic_exposure!
Main.DIVACoast.remove_static_exposure!
Main.DIVACoast.remove_dynamic_exposure!
Main.DIVACoast.sed!
Main.DIVACoast.sed_above!
Main.DIVACoast.sed_below!
Main.DIVACoast.remove_below!
Main.DIVACoast.add_above!
Main.DIVACoast.add_between!
Main.DIVACoast.compress!
```

# Extreme sea-level hazards

Currently the library only supports extreme still water level distributions as ESL hazard. These distributions are represented as `Distributions` of the Julia Package `Distributions.jl`. As ESL are often provided as non-parametric (i.e. empirical) distributions, i.e. point-wise as a list of water levels and associated return periods, `DIVACoast.jl` provides a couple of functions that can be used to convert from a **discrete non-parametric distribution** (i.e. a distribution given point-wise) to a given **parametric extreme value distribution** by (method, e.g., least square fit).

```@docs
Main.DIVACoast.estimate_gumbel_distribution
Main.DIVACoast.estimate_frechet_distribution
Main.DIVACoast.estimate_gev_distribution
Main.DIVACoast.estimate_weibull_distribution

Main.DIVACoast.estimate_gpd_negative_distribution
Main.DIVACoast.estimate_gpd_positive_distribution
Main.DIVACoast.estimate_gp_distribution
Main.DIVACoast.estimate_exponential_distribution

Main.DIVACoast.plot_comparison_extreme_distributions
```


# External Drivers

For the external drivers of sea-level rise and socio-economic development, DIVA provides convenient data readers. These readers also provides values for any future point in time by **interpolating** piecewise linearly between time steps and **extrapolating** linearly from the last available time step.

## Deterministic Scenario Reader

**Socio-economic-scenarios** can be managed using the `ScenarioReader` function. This reader can be used to retrieve certain growth rates between two years and within a certain ssp scenario. Growth rates can be returned in three different types: AnnualGrowthPercentage, AnnualGrowth, GrowthFactor. 

```@docs
Main.DIVACoast.ScenarioReader
```
<font color="red">I propose to generalise this data structure and all associated functions to the following</font>

```
Main.DIVACoast.DeterministicScenarioReader

value(sw::DeterministicScenarioReader, time::Real)
growth_absolute(sw::DeterministicScenarioReader, time_from::Real, time_to::Real)
growth_relative(sw::DeterministicScenarioReader, time_from::Real, time_to::Real)
...

```

## Probabilistic Spatial Scenario Reader

```@docs
Main.DIVACoast.SLRScenarioReader
Main.DIVACoast.get_slr_value
Main.DIVACoast.get_slr_value_from_grid_cell
```

**Sea Level Rise** scenarios can be managed using the `SLRScenarioReader`. This reader can then be used with the `get_slr_value()` and `get_slr_value_from_cell()` functions to retrieve the relevant data. The reader takes a **NetCDF** file as input, which must include the following dimensions:

1. **Variable**  
   - The specific variable you want to access (e.g., Sea Level Rise in meters).
2. **Longitude and Latitude**  
   - Dimensions specifying the longitude and latitude for each grid cell in the NetCDF file.
3. **Time**  
   - A temporal dimension, e.g., 5-year increments.
4. **Quantiles**  
   - Quantiles associated with your variable, useful for capturing uncertainty or different scenarios.


# Flood Damage Assessment
To draw conclusions from our model, we aim to analyze exposed entities under different circumstances. DIVACoast not only allows the use of a bathtub model for exposure analysis but also supports attenuation.
Attenuation refers to the process by which floodwaters are reduced in depth as they propagate across the landscape, influenced by certain land cover types. This could include factors like vegetation, wetlands, or urban infrastructure that slow down or reduce the extent of flooding.

## Damage of a single events
```@docs
Main.damage_bathtub_standard_ddf(hspf::HypsometricProfile{DT}, wl::DT, hdd::DT, s::Symbol)::DT where {DT<:Real}


```

## Expected damages
```@docs
Main.DIVACoast.expected_damage_bathtub_standard_ddf
Main.DIVACoast.expected_damage_bathtub
```



# Spatial Operations
## SparseGeoArray (SGA)
```@docs
Main.DIVACoast.SparseGeoArray
Main.DIVACoast.getindex
Main.DIVACoast.coords
Main.DIVACoast.indices
Main.DIVACoast.nh4
Main.DIVACoast.nh8
Main.DIVACoast.distance
Main.DIVACoast.go_direction
Main.DIVACoast.bounding_boxes
Main.DIVACoast.area
Main.DIVACoast.emptySGAfromSGA
Main.DIVACoast.get_extent
Main.DIVACoast.sga_union
Main.DIVACoast.sga_intersect
Main.DIVACoast.sga_diff
Main.DIVACoast.sga_summarize_within
Main.DIVACoast.minumum_mean
Main.DIVACoast.get_closest_value
Main.DIVACoast.get_box_around
Main.DIVACoast.epsg2wkt
Main.DIVACoast.proj2wkt
Main.DIVACoast.str2wkt
Main.DIVACoast.epsg!
Main.DIVACoast.is_rotated
Main.DIVACoast.bbox!
Main.DIVACoast.geotiff_connect
```

## Spatial-Relationship
```@docs
Main.DIVACoast.Neighbour
Main.DIVACoast.nearest
Main.DIVACoast.nearest_coord
Main.DIVACoast.coords_to_wide
```
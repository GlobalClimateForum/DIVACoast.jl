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

The key concept of `DIVACoast.jl` is the concept of risk. Following the definition of the Intergovernmental Panel on Climate Change (IPCC), risk constituted by the three components of hazard, exposure and vulnerability (Oppenheimer et al., 2019; Wong et al., 2014). While on the long run the package is meant to serve multiple coastal risks including the risk of flooding, erosion, salinity intrusion and wetland change, the current release concentrates on flood risk. 

## Flood risk
Coastal flood risk assessment involves at least the following five components (Figure x): 

- **Sea-level hazard**, including mean sea-levels (MSL) and extreme sea-levels (ESL) from tides, surges, waves, river run-off and their interactions;
- **Hazard propagation**, which refers to the transformation of the **sea-level hazard** to the **flood hazard**. This includes the propagation of mean and extreme sea-level onto the shore and the floodplain, including their interaction with natural (e.g., dunes) and artificial (e.g., dikes) defences;
- **Flood hazard**, refers to the flood characteristics found at a specific flooded location. Currently `DIVACoast.jl` is limited to the characteristic of maximum water depth.
- **Flood exposure** in terms of area, people and coastal assets potentially threatened by these hazards; and
- **Flood vulnerability**, which refers to the  propensity of the exposure to be adversely affected by the flood hazard (IPCC, 2014b).

## Drivers
- Sea-level rise: changes the hazard
- Socio-economic development: changes exposure and vulnerability

## Adaptation 
- protection: affects the hazard propagation
- retreat: reduces exposure
- accommodate: reduces vulnerability


# Sea-level hazards

Currently the only way to represent sea-level hazards in `DIVACoast.jl` is through extreme still water level distributions. These distributions are represented as `Distributions` of the Julia Package `Distributions.jl`. As ESL are often provided as non-parametric (i.e. empirical) distributions, i.e. point-wise as a list of water levels and associated return periods, `DIVACoast.jl` provides a couple of functions that convert these **non-parametric distributions** to a chosen **parametric extreme value distribution**. 

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


# Exposure 
Currently the main way to represent exposure in `DIVACoast.jl` is as `HypsometricProfile`. This is a special kind of coastal profile that allows for a very efficient computation of flood damages, which is beneficial for running large number of damage assessments as, e.g., required for many economic questions that involve optimization. In addition, `DIVACoast.jl` supports representing exposure via two dimensional grids, in which each grid cell is mapped to its elevation (or hydrological connectivity), as well as a set of exposure variables such as area, people or assets. `DIVACoast.jl` represents such gridded exposure as `SparseGeoArrays`. Functions are also provided to convert gridded exposure data to hypsometric profiles.


## Hypsometric Profiles
A hypsometric profile represents a cross-section of the coastal zone as a function that maps elevation to  the cumulative exposure below this elevation. Hyposmetric profiles are derived from a Digital Elevation Model (DEM) considering hydrological connectivity.
<!-- add the math -->

A `HyposmetricProfile` holds two different types of exposure:
1. **Static Exposure**, which is exposure that cannot be relocated. An example is land (area). 
2. **Dynamic Exposure**, which is exposure that can be relocated or adapted over time. Examples are people, who may move to higher elevations, or assets depreciating as mean and extreme sea-levels come closer over time.


### Constructing Hypsometric Profiles
Currently, Hypsometric Profiles can constructed directly through a constructor, or indirectly from a NetCDF file.

<!--- rename "load" to "read" -->
```@docs
Main.DIVACoast.HypsometricProfile
Main.DIVACoast.load_hsps_nc
Main.DIVACoast.to_hypsometric_profile
Base.:+
```

### Querying Hypsometric Profiles
```@docs
Main.DIVACoast.exposure_below_bathtub
Main.DIVACoast.exposure_below_attenuated
Main.DIVACoast.attenuate
```
### Modifying Hypsometric Profiles
Socio-economic development and adaptation changes exposure. For example, socio-economic growth increases the number of people and their assets in the coastal zone, while retreat reduces assets and people in the costal zone. To represent those process in DIVACoast, we provide the following functions.

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

<font color="red">Remark JH: 
Can we change the _sed functions above to:

`Main.DIVACoast.multiply_above!`

`Main.DIVACoast.multiply_below!`
</font>


## Two-dimensional gridded exposure
Currently, `DIVACoast.jl` only provides limited support for representing coastal exposure on a two-dimensional (2D) grid, but this will be added in future releases. In the current release, the main purpose of representing two-dimensional exposure data is to convert these to hypsometric profiles. 


### SparseGeoArray (SGA)
In `DIVACoast.jl` 2D gridded exposure is represented as `SparseGeoArray` (SGA).

```@docs
Main.DIVACoast.SparseGeoArray
```

### Spatial Operations on SparseGeoArray
A number of standard functions are provided for handling gridded exposure data.

<!-- Can we group the documentation of these functions into meaningful subheading -->

```@docs
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

## Spatial relationship
```@docs
Main.DIVACoast.Neighbour
Main.DIVACoast.nearest
Main.DIVACoast.nearest_coord
Main.DIVACoast.coords_to_wide
```

# Flood damage assessment

## Flood propagation model

Currently `DIVACoast.jl` only support the **bathtub model** and the **attenuated bathtub model**. Attenuation refers to the reduction of water levels while floods propagate inland across the landscape. The magnitude of attenuation is a function of land cover such as vegetation, buildings and infrastructure which slow down and hence reduce the extent of flooding.

## Damage of a single event
```@docs
Main.DIVACoast.damage_bathtub
Main.DIVACoast.damage_bathtub_standard_ddf
```

## Expected damages
```@docs
Main.DIVACoast.expected_damage_bathtub
Main.DIVACoast.expected_damage_bathtub_standard_ddf
```

<font color="red">Remark JH: Do we or will we also have the following functions:</font>

```@docs
Main.DIVACoast.damage_attenuated
Main.DIVACoast.damage_attenuated_standard_ddf
Main.DIVACoast.expected_damage_attenuated
Main.DIVACoast.expected_damage_attenuated_standard_ddf

```


<font color="red">Remark JH: I could also imagine that we provide additional methods for these functions in a way the structure of our library becomes clearer. 

For example we could define different types of flood propagation models:

```
abstract type FloodPropagationModel end

struct Bathtub <: FloodPropagationModel end

struct Attenuated <: FloodPropagationModel
   attenuation_rates:: Union{Float,Array{Float}}
end

struct HydroDynamicModel <: FloodPropagationModel
   path_to_executable="bla/lisflood"
   ...
end
```

And then have generic methods operating on them
```
damage(hspf::HypsometricProfile{DT}, wl::DT, model::FloodPropagationModel)

```

Then we could calculate damages in the following way
```
damage(hspf, wl, Bathtub())
damage(hspf, wl, Attenuated(.5))
damage(hspf, wl, Attenuated([.1,.2,.4,.6,.5]))
damage(hspf, wl, HydroDynamicModel())
```
Thoughts?
</font>


# Coastal models

`DIVACoast.jl` also provides the higher-level data structures of Coastal Models, which provide a range of higher-level convenience functions to handle large ensembles of coastal risk assessment. The data structure of `CoastalModel` thereby combines hazard, exposure, vulnerabilty information for a given type of hazard. Several Coastal Models can further be combined into a `CompositeCoastalModel`. Currently, the only type of Coastal Model available is the `CoastalFloodModel`, which is further described below. Future versions of the library will also contain other types of Coastal Models such as, e.g., `CoastalErosionModel` and `CoastalWetlandsModel`.


## Coastal Flood Model
A `CoastalFloodModel` combines all information necessary for computing flood exposure and damage including sea-level hazard, attenuation model, exposure and vulnerability. 


<!-- Change to CoastalFloodModel -->
```@docs
Main.DIVACoast.LocalCoastalImpactModel
Main.DIVACoast.ComposedImpactModel
```
 <font color="red">Remark JH: Can we change the above to:</font>
```
Main.DIVACoast.CoastalFloodModel
Main.DIVACoast.ComposedCoastalFloodModel
```


A `CoastalFloodModel` is defined as
```
mutable struct CoastalFloodModel{DT<:Real,IDT,DATA} <: CoastalImpactUnit
  id::IDT
  surge_model::Distribution
  coastal_plain_model::HypsometricProfile{DT}
  protection_level::Real
  data::DATA
end
```

 <font color="red">Remark JH: According to the definition of risk above, it would make sense to also include vulnerability in a coastal model, because then we have all three components included in a CoastalFloodModel. Plus we could then write convenience functions such as:</font>

```
function damage(cfm::CoastalFloodModel, x::Real)
function expected_damage(cfm::CoastalFloodModel)
```

# Drivers
DIVA provides convenient data readers for external drivers such as sea-level rise and socio-economic development. These readers provide values for any future point in time by **interpolating** piecewise linearly between time steps and **extrapolating** linearly from the last available time step. All readers also provide growth rates between two points in time. Growth rates can be returned in three different ways as AnnualGrowthPercentage, AnnualGrowth, GrowthFactor. 

## 1D deterministic scenarios
**Socio-economic-scenarios** often come as deterministic scenarios and can be handled using the `DeterministicScenarioReader`.


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

## 2D probabilistic scenarios

```@docs
Main.DIVACoast.SLRScenarioReader
Main.DIVACoast.get_slr_value
Main.DIVACoast.get_slr_value_from_grid_cell
```

**Sea Level Rise** scenarios often come as 2D probabilistic scenarios, which are handled using the `2DProbScenarioReader`. This reader can then be used with the `get_value()` and `get_value_from_cell()` functions to retrieve the relevant data. The reader takes a **NetCDF** file as input, which must include the following dimensions:

1. **Variable**: The specific variable you want to access (e.g., Sea Level Rise in meters).
2. **Longitude and Latitude**: Dimensions specifying the longitude and latitude for each grid cell in the NetCDF file.
3. **Time**: Time dimension, e.g., 5-year increments.
4. **Quantiles**: Quantiles associated with the variable.
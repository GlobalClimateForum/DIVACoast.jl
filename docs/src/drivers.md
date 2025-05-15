```@meta
CollapsedDocStrings = true
Description = "DIVACoast.jl is a Julia library for coastal impact and adaptation modelling. The library provides data types and algorithms to quickly script assessments for different **coastal impact and adaptation** research questions. DIVACoast.jl is provided by the [Global Climate Forum](https://globalclimateforum.org/) via [GitHub](https://github.com/globalclimateforum/DIVACoast.jl)."
```
# Drivers
`DIVACoast.jl` provides convenient data readers for external drivers such as sea-level rise and socio-economic development. These readers provide values for any future point in time by **interpolating** piecewise linearly between time steps and **extrapolating** linearly from the last available time step. All readers also provide growth rates between two points in time. Growth rates can be returned in three different ways as AnnualGrowthPercentage, AnnualGrowth, GrowthFactor. The readers can be used with the `get_value()` and `get_value_from_cell()` functions to retrieve the relevant data. The reader takes a **NetCDF** file as input, which must include the following dimensions:

1. **Variable**: The specific variable you want to access (e.g., Sea Level Rise in meters).
2. **Longitude and Latitude**: Dimensions specifying the longitude and latitude for each grid cell in the NetCDF file.
3. **Time**: Time dimension, e.g., 5-year increments.
4. **Quantiles**: Quantiles associated with the variable.

```@docs
Main.DIVACoast.SSPScenarioReader
Main.DIVACoast.SLRScenarioReader
Main.DIVACoast.get_slr_value
Main.DIVACoast.get_slr_value_from_grid_cell
```
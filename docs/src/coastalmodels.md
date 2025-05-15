```@meta
CollapsedDocStrings = true
Description = "DIVACoast.jl is a Julia library for coastal impact and adaptation modelling. The library provides data types and algorithms to quickly script assessments for different **coastal impact and adaptation** research questions. DIVACoast.jl is provided by the [Global Climate Forum](https://globalclimateforum.org/) via [GitHub](https://github.com/globalclimateforum/DIVACoast.jl)."
```
# Coastal models
`DIVACoast.jl` also provides the higher-level data structures of Coastal Models, which provide a range of higher-level convenience functions to handle large ensembles of coastal risk assessment. The data structure of `CoastalModel` thereby combines hazard, exposure, vulnerabilty information for a given type of hazard. Several Coastal Models can further be combined into a `CompositeCoastalModel`. Currently, the only type of Coastal Model available is the `CoastalFloodModel`, which is further described below. Future versions of the library will also contain other types of Coastal Models such as, e.g., `CoastalErosionModel` and `CoastalWetlandsModel`.

## Coastal Flood model
A `CoastalFloodModel` combines all information necessary for computing flood exposure and damage including sea-level hazard, attenuation model, exposure and vulnerability. 

```@docs
Main.DIVACoast.LocalCoastalImpactModel
Main.DIVACoast.ComposedImpactModel
```

A `CoastalFloodModel` is defined as

```julia
mutable struct CoastalFloodModel{DT<:Real,IDT,DATA} <: CoastalImpactUnit
  id::IDT
  surge_model::Distribution
  coastal_plain_model::HypsometricProfile{DT}
  protection_level::Real
  data::DATA
end
```
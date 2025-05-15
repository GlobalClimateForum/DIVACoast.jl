```@meta
CollapsedDocStrings = true
Description = "DIVACoast.jl is a Julia library for coastal impact and adaptation modelling. The library provides data types and algorithms to quickly script assessments for different **coastal impact and adaptation** research questions. DIVACoast.jl is provided by the [Global Climate Forum](https://globalclimateforum.org/) via [GitHub](https://github.com/globalclimateforum/DIVACoast.jl)."
```
# Flood damage assessment

## Flood propagation model
Currently `DIVACoast.jl` supports the **bathtub model** and the **attenuated bathtub model**. Attenuation refers to the reduction of water levels while floods propagate inland across the landscape. The magnitude of attenuation is a function of land cover such as vegetation, buildings and infrastructure which slow down and hence reduce the extent of flooding.

```@docs
Main.DIVACoast.expected_damage_bathtub_standard_ddf
Main.DIVACoast.expected_damage_bathtub
Main.DIVACoast.damage_bathtub_standard_ddf
Main.DIVACoast.damage_bathtub
```
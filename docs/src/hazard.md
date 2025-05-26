```@meta
CollapsedDocStrings = true
Description = "DIVACoast.jl is a Julia library for coastal impact and adaptation modelling. The library provides data types and algorithms to quickly script assessments for different **coastal impact and adaptation** research questions. DIVACoast.jl is provided by the [Global Climate Forum](https://globalclimateforum.org/) via [GitHub](https://github.com/globalclimateforum/DIVACoast.jl)."
```
# Sea-Level hazard

Currently sea-level hazards in `DIVACoast.jl` are represented trough extreme still water level distributions. These distributions are implemented as `Distributions` of the Julia Package `Distributions.jl`. As ESL are often provided as non-parametric (i.e. empirical) distributions, i.e. point-wise as a list of water levels and associated return periods, `DIVACoast.jl` provides a couple of functions that convert these **non-parametric distributions** to a chosen **parametric extreme value distribution**. 

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

An **InundationModel** defines how the flood extent of an extreme still water level is determined. 

```@docs
Main.DIVACoast.InundationModel
```

To get the flood extent under an extreme still water level on a hypsometric profile for a specific InundationModel, one can use the following function.
```@docs
Main.DIVACoast.inundate
```
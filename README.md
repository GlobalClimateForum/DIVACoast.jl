# DIVACoast.jl

## About DIVACoast.jl

DIVACoast.jl is a julia library for coastal impact and adaptation modelling. The library provides data types and algorithms to script assessment runs for different coastal impact and adaptation research questions.
The library is  provided by the [Global Climate Forum](https://globalclimateforum.org/) via this repository. Here you can find the [Documentation](https://globalclimateforum.github.io/DIVACoast.jl/)).

## Download & Installation

You can install DIVACoast library by: 
```@julia
using Pkg
Pkg.add(url = "https://github.com/GlobalClimateForum/DIVACoast.jl")
```
Or by manually cloning it to your local machine:  `git clone https://github.com/GlobalClimateForum/DIVACoast.jl`
and including it in your script:

```@julia
include("path_to_DIVACoast/src/DIVACoast.jl")
using .DIVACoast
```

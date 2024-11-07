# About

jdiva is a julia library for coastal impact and adaptation modelling. The library provides data types and algorithms to script assessment runs for different coastal impact and adaptation research questions.
The library is __currently under development__ and provided by the [Global Climate Forum](https://globalclimateforum.org/) via [GitLab](https://gitlab.com/globalclimateforum/diva_library).

# Get
The jdiva library is __currently under development__. You can get the latest (__unstable__) version by cloning the library repository to your machine. Since there is not stable version at the moment you have to switch to the development branch afterwards.

```
git clone https://gitlab.com/globalclimateforum/diva_library.git
 git checkout development
```

# Setting up Julia
Ensure you have Julia installed on your system. You can download it from the official [julia website](https://julialang.org). The jdiva library has several dependencies. To install all required libraries you can run the `install_packages.jl` script from the diva_library repository or activate the jdiva julia environment `Pkg.instantiate(); Pkg.activate()`.

# Include jdiva in your project
You can add jdiva to your own project by adding the following to your script.
```
include(<path_to_diva>/diva_library/src/jdiva_lib.jl); using .jdiva
```

# Set Data Directory
Setting the DIVA_DATA environment variable is crucial for the proper functioning of the jdiva library. This variable defines the specific directory where the library looks for its required data files. By setting DIVA_DATA, you ensure that jdiva can consistently locate and access the data it needs, avoiding errors related to missing or misplaced files.

1. Linux & MacOS\
    `export DIVA_DATA="<path_to_folder>/diva_data"` (current session)\
    `export DIVA_DATA="<path_to_folder>/diva_data"` `source ~/.bashrc` (add permanent to bash profile)

2. Windows\
    `setx DIVA_DATA "<path_to_folder>/diva_data"` (permanent)\
    `set DIVA_DATA "<path_to_folder>/diva_data"` (current session)






.
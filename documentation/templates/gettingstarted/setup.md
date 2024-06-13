## Setting up your jdiva julia environment
>To start using the jdiva library in your Julia projects, follow these steps to set up your environment and install the necessary dependencies.

### 1. Install Julia
>Ensure you have Julia installed on your system. You can download it from the official [julia website](https://julialang.org).

### 2. Clone the jdiva library
>The jdiva library is __currently under development__. You can get the latest (unstable) version by clone the diva_library/development branch to your local machine. 

>`git clone https://gitlab.com/globalclimateforum/diva_library.git`

### 3. Activate the Project Environment
>Open Julia in the jdiva directory and activate the project environment.

>`julia> import Pkg`

>`julia> Pkg.activate(".")`

### 4. Install dependencies
>To install all the necessary dependencies for jdiva, use the `Pkg.instantiate()` function. This command will read the Project.toml and Manifest.toml files located in the jdiva directory and install all the required packages.

### 5. Include jdiva in your project
>Once the environment is set up, you can use jdiva in your own Julia projects. To do this add the following to your script:

> `include(<path_to_jdvia_lib.jl>)`

> `using .jdiva`

### 6. Set Data Directory as Enviroment Variable

> Setting the DIVA_DATA environment variable is crucial for the proper functioning of the jdiva library. This variable defines the specific directory where the library looks for its required data files. By setting DIVA_DATA, you ensure that jdiva can consistently locate and access the data it needs, avoiding errors related to missing or misplaced files.

> #### 1. Linux & MacOS
> `export DIVA_DATA="<path_to_folder>/diva_data"` (current session)

> `export DIVA_DATA="<path_to_folder>/diva_data"` `source ~/.bashrc` (add permanent to bash profile)

> #### 2. Windows
> `setx DIVA_DATA "<path_to_folder>/diva_data"` (permanent)

> `set DIVA_DATA "<path_to_folder>/diva_data"` (current session)
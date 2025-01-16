# Activates the DIVA project environment (dependencies)
# Include this script in your Julia code to activate the DIVA environment
# Must be included before including the jdiva module !
using Pkg
Pkg.activate("../.")
Pkg.instantiate()  
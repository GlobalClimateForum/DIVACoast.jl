DRAW_HEADER = true

# Activates the DIVA project environment (dependencies)
# Include this script in your Julia code to activate the DIVA environment
# Must be included before including the jdiva module !
using Pkg
Pkg.activate("$(ENV["DIVA_LIB"])")
Pkg.instantiate()  

export data

if DRAW_HEADER
    println("┌                             ┐")
    println("│~~~~▗▖▗▄▄▄~~▗▄▄▄▖▗▖~~▗▖~▗▄▖~~│")
    println("│~~~~▗▖▐▌~~█~~~█~~▐▌~~▐▌▐▌~▐▌~│")
    println("│~▄~~▐▌▐▌~~█~~~█~~▐▌~~▐▌▐▛▀▜▌~│")
    println("│~▀▄▄▞▘▐▙▄▄▀~▗▄█▄▖~▝▚▞▘~▐▌~▐▌~│")
    println("│~...©GLOBAL CLIMATE FORUM...~│")
    println("└                             ┘")
end

"""
Returns the full path to the data directory.
"""
diva_data = (subdir) -> "$(ENV["DIVA_DATA"])/$(subdir)"

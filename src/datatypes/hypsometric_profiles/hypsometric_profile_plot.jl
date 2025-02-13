
using Plots

function RecipesBase.plot(hp::HypsometricProfile)
    plot(hp.cummulativeArea/hp.width,hp.elevation,xlabel="Distance from coastline (km)",ylabel="Elevation (m)")
end

using Plots

function RecipesBase.plot(hp::HypsometricProfile)
    plot(hp.cummulativeArea/hp.width,hp.elevation,xlabel="distance from coastline (km)",ylabel="elevation (m)")
end
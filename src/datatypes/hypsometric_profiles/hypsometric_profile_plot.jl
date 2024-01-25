
using Plots

function RecipesBase.plot(hp::HypsometricProfile)
    plot(h.cummulativeArea/h.width,h.elevation,xlabel="distance from coatline (km)",ylabel="elevation (m)")
end
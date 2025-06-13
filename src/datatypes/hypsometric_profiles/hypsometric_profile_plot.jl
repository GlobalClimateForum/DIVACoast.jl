using Plots
using UnicodePlots


function RecipesBase.plot(hp::HypsometricProfile)
    plot(hp.cummulativeArea/hp.width,hp.elevation,xlabel="Distance from coastline (km)",ylabel="Elevation (m)")
end

# function Base.show(hp::HypsometricProfile)

#     exp_ = ""
    
#     for expName in hp.exposureNames
#         exp_ *= "EXPOSURE - $expName\n"
#         exp_ *= "$(hp.cummulativeExposure[:, Symbol(expName)])\n"
#         exp_ *= "$(hp.exposureUnits[expName])\n"
#     end
#     println(exp_)
# end

#   width::DT
#   width_unit::String
#   elevation::Array{DT}
#   elevation_unit::String
#   cummulativeArea::Array{DT}
#   area_unit::String
#   cummulativeExposure::Array{DT,2}
#   exposureNames::Array{String}
#   exposureUnits::Array{String}
#   doLog::Bool

function Base.display(hp::HypsometricProfile)

    xlabel = "Distance from coastline (km)"
    ylabel = "Elevation (m)"
    x = hp.cummulativeArea / hp.width
    y = hp.elevation

    if isdefined(Main, :IJulia) && Main.IJulia.inited
        display(plot(x, y, xlabel=xlabel, ylabel=ylabel))
    elseif isdefined(Main, :Pluto)
        plot(x, y, xlabel=xlabel, ylabel=ylabel)
    elseif haskey(ENV, "JULIA_VSCODE_EXTENSION")
        display(plot(x, y, xlabel=xlabel, ylabel=ylabel))
    elseif isinteractive()
        try
            display(plot(x, y, xlabel=xlabel, ylabel=ylabel))
        catch
            println(lineplot(x, y, xlabel=xlabel, ylabel=ylabel))
        end
    else
        println(lineplot(x, y, xlabel=xlabel, ylabel=ylabel))
    end
end

function Base.println(hp::HypsometricProfile)
    display(to_DF(hp))
end

function Base.print(hp::HypsometricProfile)
    display(to_DF(hp))
end
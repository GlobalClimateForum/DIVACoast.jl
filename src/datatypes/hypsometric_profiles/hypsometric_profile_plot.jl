using Plots
using UnicodePlots

function RecipesBase.plot(hp::HypsometricProfile)
    plot(hp.cumulativeArea/hp.width,hp.elevation,xlabel="Distance from coastline (km)",ylabel="Elevation (m)")
end

function Base.show(io::IO, hp::HypsometricProfile)
    basestr = ""
    basestr *= "┌ HypsometricProfile\n"
    basestr *= "├ Width: $(hp.width) $(hp.width_unit)\n"
    basestr *= "├ Elevation: $(minimum(hp.elevation)) up to $(maximum(hp.elevation))$(hp.elevation_unit) at $(length(hp.elevation)) increments\n"
    basestr *= "├ Cum. area (maximum): $(maximum(hp.cumulativeArea))$(hp.area_unit)\n"
    basestr *= "└ Exposures:\n"
    
    for (index, name) in enumerate(hp.exposureNames)
        e_ = hp.cumulativeExposure[:, index]
        basestr *= "  ├ $name: $(size(e_, 1)) values from $(minimum(e_)) to $(maximum(e_))$(hp.exposureUnits[index])\n"
    end
    print(io, basestr)
end

Base.print(io::IO, hp::HypsometricProfile) = show(io, hp)

function Base.display(hp::HypsometricProfile)

    xlabel = "Distance from coastline (km)"
    ylabel = "Elevation (m)"
    x = hp.cumulativeArea / hp.width
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
            println("- HypsometricProfile")
            println("    " * ylabel)
            println(lineplot(x, y, xlabel=xlabel, ylabel=""))
        end
    else
        println("- HypsometricProfile")
        println("    " * ylabel)
        println(lineplot(x, y, xlabel=xlabel, ylabel=""))
    end

end
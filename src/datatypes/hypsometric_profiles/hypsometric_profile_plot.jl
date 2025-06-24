using Plots
using UnicodePlots

function RecipesBase.plot(hp::HypsometricProfile)
    currentEnv_ = private_detectENV()
    
    x = hp.cumulativeArea / hp.width
    y = hp.elevation
    lecz = x[findfirst( e -> e == 10, y)]
    plotargs = (
        title = "Hypsometric Profile",
        xlabel = "Distance from coastline [$(hp.width_unit)]",
        ylabel = "Elevation [$(hp.elevation_unit)]",
        label = "Hypsometric Profile", 
        fillrange = minimum(hp.elevation), 
        fillcolor = :darkgreen, 
        fillalpha = 0.4, 
        color = :darkgreen,
        linewidth = 2
    )
    
    if currentEnv_ ∈ [:jupyter, :pluto] || isinteractive()
        p = plot(x, y; plotargs...)
        Plots.hline!([0], color=:black, linewidth=1, linestyle=:dash, label="0 $(hp.elevation_unit)")
        Plots.vline!([lecz], color=:red, linewidth=2, label="LECZ")
    else
        p = lineplot(hp.cumulativeArea / hp.width, hp.elevation, xlabel="Distance from coastline [$(hp.width_unit)]", ylabel="Elevation [$(hp.elevation_unit)]")
    end

    return p
end

function HypsometricPlot(hp::HypsometricProfile)
    display(plot(hp))
end

function Base.show(io::IO, ::MIME"text/html", hp::HypsometricProfile)
    htmlstr = ""
    htmlstr *= "<style>table { border-collapse: collapse; border: 1px solid black; } td, th { border: 1px solid black; padding: 8px; }</style>"
    htmlstr *= "<table>"
    htmlstr *= "<caption>Hypsometric Profile Summary</caption>"
    htmlstr *= "<tr><th>Property</th><th>Value(s)</th><th>Range</th><th>Unit</th></tr>"
    htmlstr *= "<tr><td>Width</td><td>$(hp.width)</td><td>-</td><td>$(hp.width_unit)</td></tr>"
    htmlstr *= "<tr><td>Elevation</td><td>$(length(hp.elevation)) values</td><td>$(minimum(hp.elevation)) to $(maximum(hp.elevation))</td><td>$(hp.elevation_unit)</td></tr>"
    htmlstr *= "<tr><td>Cumulative Area</td><td>$(length(hp.cumulativeArea)) values</td><td>0 to $(maximum(hp.cumulativeArea))</td><td>$(hp.area_unit)</td></tr>"
    htmlstr *= "<tr style='text-align: left'><td colspan=4>Exposures</td></tr>"
    for (index, name) in enumerate(hp.exposureNames)
        e_ = hp.cumulativeExposure[:, index]
        htmlstr *= "<tr><td>$name</td><td>$(size(e_, 1)) values</td><td>$(minimum(e_)) to $(maximum(e_))</td><td>$(hp.exposureUnits[index])</td></tr>"
    end
    htmlstr *= "</table>"
    print(io, htmlstr)
end

function Base.show(io::IO, hp::HypsometricProfile)
    basestr = "\n"   
    if get(io, :compact, false)
        basestr *= "HypsometricProfile[$(minimum(hp.elevation))-$(maximum(hp.elevation))$(hp.elevation_unit)]"
    else
        basestr *= "┌ HypsometricProfile\n"
        basestr *= "├ Width: $(hp.width) $(hp.width_unit)\n"
        basestr *= "├ Elevation: $(minimum(hp.elevation)) up to $(maximum(hp.elevation))$(hp.elevation_unit) at $(length(hp.elevation)) increments\n"
        basestr *= "├ Cum. area (maximum): $(maximum(hp.cumulativeArea))$(hp.area_unit)\n"
        basestr *= "└ Exposures:\n"
        
        for (index, name) in enumerate(hp.exposureNames)
            e_ = hp.cumulativeExposure[:, index]
            basestr *= "  ├ $name: $(size(e_, 1)) values from $(minimum(e_)) to $(maximum(e_))$(hp.exposureUnits[index])\n"
        end
    end
    print(io, basestr)
end

# Function to detect the environment the script is running in
# required for diplaying plots depending on the environment
function private_detectENV()
    # Jupyter Notebook
    if any([
        isdefined(Base, :__IJULIA),
        isdefined(Main, :IJulia),
        get(ENV, "JUPYTER", "") != "",
        get(ENV, "VSCODE_PID", "") != ""  # likely VSCode kernel
    ])
        return :jupyter    
    # Pluto Notebook
    elseif !isnothing(match(r"^In\[[0-9]*\]$", @__FILE__))
        return :pluto
    else
        return :repl
    end

    return :unknown
end
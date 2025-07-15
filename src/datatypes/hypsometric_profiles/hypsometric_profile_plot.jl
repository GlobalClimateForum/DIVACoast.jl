using Plots
using UnicodePlots

function RecipesBase.plot(hp::HypsometricProfile; exposure::Union{Symbol, String, Nothing} = nothing)

    currentEnv_ = private_detectENV()
    
    exposure = !isnothing(exposure) ? String(exposure) : nothing
    index = !isnothing(exposure) ? findfirst(==(exposure), hp.exposureNames) : nothing

    distance_to_coast = hp.cumulativeArea / hp.width

    if !isnothing(exposure) && isnothing(index)
        error("Exposure: '$exposure' not found in HypsometricProfile.")
    elseif !isnothing(exposure) && !isnothing(index) 
        y = hp.cumulativeExposure[:, index]
        plotargs = (
            xlabel = "Distance from coastline",
            ylabel = exposure * (hp.exposureUnits[index] ∉ [" ", "", nothing] ? "[$(hp.exposureUnits[index])]" : ""),
            label = "$(exposure)", 
            fillrange = minimum(hp.elevation), 
            fillcolor = :darkblue, 
            fillalpha = 0.4, 
            color = :darkblue,
            linewidth = 2
            )
    else
        y = hp.elevation
        plotargs = (
            xlabel = "Distance from coastline",
            ylabel = "Elevation [$(hp.elevation_unit)]",
            label = "Elevation", 
            fillrange = minimum(hp.elevation), 
            fillcolor = :darkgreen, 
            fillalpha = 0.4, 
            color = :darkgreen,
            linewidth = 2
            )
    end

    lecz_idx = findfirst(e -> e >= 10.0, hp.elevation)

    p = plot(distance_to_coast, y; plotargs...)
    Plots.hline!(p, [0.0], linestyle = :dash, label = "0$(hp.elevation_unit) elevation",   color = :black)
    Plots.vline!(p, [distance_to_coast[lecz_idx]], color = :red, label = "LECZ", linewidth = 1)
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
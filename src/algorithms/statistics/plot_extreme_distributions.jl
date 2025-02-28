export plot_extremes

using Distributions
using Plots
using ColorSchemes

function plot_extremes(x_data::Array{T}, y_data::Array{T}) where {T<:Real}
    # Define different GEV and GPD distributions
    gev_gumbel = estimate_gumbel_distribution(x_data, y_data)
    gev_frechet = estimate_frechet_distribution(x_data, y_data)
    gev_weibull = estimate_weibull_distribution(x_data, y_data)
    gpd_exponential = estimate_exponential_distribution(x_data, y_data)
    gpd_positive = estimate_gpd_positive_distribution(x_data, y_data)
    gpd_negative = estimate_gpd_negative_distribution(x_data, y_data)

    #choose best fit based on minimising error
    gev_best = estimate_gev_distribution(x_data, y_data)
    gpd_best = estimate_gp_distribution(x_data, y_data)
    if gev_best[2] < gpd_best[2]
        best_fit=gev_best[1]
        best_fit_error=round(gev_best[2],digits=2)
    elseif gpd_best[2] <= gev_best[2]
        best_fit=gpd_best[1]
        best_fit_error=round(gpd_best[2],digits=2)
    end

    # Extract the best fitted parameters
    μ = round(best_fit.μ,digits=2)  # Location parameter
    σ = round(best_fit.σ,digits=2)  # Scale parameter
    ξ = round(best_fit.ξ,digits=2)  # Shape parameter

    # Define x-values for plotting (covering the range of x data)
    y_range = range(minimum(y_data), stop=maximum(y_data), length=200)
    y_range_rp = map(x -> 1/(1-x), y_range)
    y_data_rp = round.(map(x -> 1/(1-x), y_data),digits=1)

    # Compute the corresponding y-values (quantiles) from each distribution
    y_gev_gumbel = quantile.(gev_gumbel, y_range)
    y_gev_frechet = quantile.(gev_frechet, y_range)
    y_gev_weibull = quantile.(gev_weibull, y_range)
    y_gpd_exponential = quantile.(gpd_exponential, y_range)
    y_gpd_positive = quantile.(gpd_positive, y_range)
    y_gpd_negative = quantile.(gpd_negative, y_range)

    y_best_fit = quantile.(best_fit, y_range)

    # Plot the three GEV quantile functions
    fig = plot(y_range_rp, y_best_fit, label="Best fit (μ = $μ, σ = $σ, ξ = $ξ). Error=$best_fit_error", lw=6, color=:red, xscale=:log10)

    plot!(y_range_rp, y_gev_gumbel, label="GEV Gumbel", lw=3, color=ColorSchemes.viridis.colors[1])
    plot!(y_range_rp, y_gev_frechet, label="GEV Frechet", lw=3, color=ColorSchemes.viridis.colors[50])
    plot!(y_range_rp, y_gev_weibull, label="GEV Weibull", lw=3, color=ColorSchemes.viridis.colors[100])
    plot!(y_range_rp, y_gpd_exponential, label="GPD Exponential", lw=3, color=ColorSchemes.viridis.colors[150])
    plot!(y_range_rp, y_gpd_positive, label="GPD Positive", lw=3, color=ColorSchemes.viridis.colors[200])
    plot!(y_range_rp, y_gpd_negative, label="GPD Negative", lw=3, color=ColorSchemes.viridis.colors[250])



    # Overlay the actual data points
    scatter!(y_data_rp, x_data, markersize=6, label="Extreme Data Points", color=:black)

    # Customize the plot

    xticks!(y_data_rp, string.(y_data_rp))
    xlabel!("Return period")
    ylabel!("Water level")
    title!("Extreme Distributions and Data Points")

    return fig
end
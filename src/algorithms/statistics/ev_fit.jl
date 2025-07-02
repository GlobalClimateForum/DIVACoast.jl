export estimate_ev_distribution

function estimate_ev_distribution(x_data::Array{T}, y_data::Array{T}) where {T<:Real}
    gev_gumbel = estimate_gumbel_distribution(x_data, y_data)
    gev_frechet = estimate_frechet_distribution(x_data, y_data)
    gev_weibull = estimate_weibull_distribution(x_data, y_data)
    gpd_exponential = estimate_exponential_distribution(x_data, y_data) # ξ = 0
    gpd_pareto = estimate_pareto_distribution(x_data, y_data)
    gpd_beta = estimate_beta_distribution(x_data, y_data)

    my_gumbel_error = gumbel_error_x(x_data, y_data)([gev_gumbel.μ, gev_gumbel.σ, gev_gumbel.ξ])
    my_frechet_error = frechet_error_x(x_data, y_data)([gev_frechet.μ, gev_frechet.σ, gev_frechet.ξ])
    my_weibull_error = weibull_error_x(x_data, y_data)([gev_weibull.μ, gev_weibull.σ, gev_weibull.ξ])
    my_exponential_error = exponential_error_x(x_data, y_data)([gpd_exponential.μ, gpd_exponential.σ, gpd_exponential.ξ])
    my_pareto_error = pareto_error_x(x_data, y_data)([gpd_pareto.μ, gpd_pareto.σ, gpd_pareto.ξ])
    my_beta_error = beta_error_x(x_data, y_data)([gpd_beta.μ, gpd_beta.σ, gpd_beta.ξ])

    min_error = min(my_gumbel_error, my_frechet_error, my_weibull_error, my_exponential_error, my_pareto_error, my_beta_error)

    if (min_error == my_gumbel_error)
        return (gev_gumbel, my_gumbel_error)
    elseif (min_error == my_exponential_error)
        return (gpd_exponential, my_exponential_error)
    elseif (min_error == my_frechet_error)
        return (gev_frechet, my_frechet_error)
    elseif (min_error == my_pareto_error)
        return (gpd_pareto, my_pareto_error)
    elseif (min_error == my_weibull_error)
        return (gev_weibull, my_weibullerror)
    else
        return (gpd_beta, my_beta_error)
    end
end

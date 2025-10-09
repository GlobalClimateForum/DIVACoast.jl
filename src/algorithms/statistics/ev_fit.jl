export estimate_ev_distribution


"""
    function estimate_ev_distribution(x_data::Array{T}, y_data::Array{T}) :: (Distribution,Float64)  where {T<:Real}

estimates an extreme value distribution from given cdf-quantiles
# Arguments
- `x_data::Array{T}`: The values for the given quantiles (usually interpreted as water levels). 
- `y_data::Array{T}`: The quantiles (cummulative probabilities).

# Returns
- a pair (Distribution,Float64) where the first element is a distribution, either of type GeneralizedExtremeValue or of type GeneralizedPareto, 
  the second element is the squared mean error this distribution produces on the input data

# Example
```julia
x_data = [2.48099994659424, 2.57800006866455, 2.69799995422363, 2.78099989891052, 2.8840000629425, 2.95300006866455, 3.01500010490417, 3.09200000762939, 3.13199996948242, 3.18600010871887]
y_data = [0.0, 0.5, 0.8, 0.9, 0.96, 0.98, 0.99, 0.996, 0.998, 0.999]

estimate_ev_distribution(x_data,y_data)
(GeneralizedPareto{Float64}(μ=2.5250140954661506, σ=0.10146756169413544, ξ=0.0), 0.027488131754383784)
```
"""
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
        return (gev_weibull, my_weibull_error)
    else
        return (gpd_beta, my_beta_error)
    end
end

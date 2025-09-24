export estimate_exponential_distribution, estimate_pareto_distribution
export estimate_beta_distribution, estimate_gp_distribution, exponential_error, pareto_error, beta_error, exponential_error_x, pareto_error_x, beta_error_x

using LsqFit
using Distributions
using LinearAlgebra
using Dates

exponential_model(x, p) = map(x -> (x >= p[1]) ? 1 - exp(-(x - p[1]) / p[2]) : 0, x)
pareto_model(x, p) = map(x -> (x >= p[1]) ? 1 - (1 + p[3] * ((x - p[1]) / p[2]))^(-1 / p[3]) : 0, x)
beta_model(x, p) = map(x -> ((x >= p[1]) && (x <= p[1] - p[2] / p[3])) ? 1 - (1 + p[3] * ((x - p[1]) / p[2]))^(-1 / p[3]) : (x >= p[1]) ? 1 : 0, x)


# explicit error functions
exponential_error(x_data, y_data) = function (p)
    res = 0.0
    for i in 1:size(x_data, 1)
        if (p[1] <= x_data[i])
            res += (y_data[i] - (1 - exp(-(x_data[i] - p[1]) / p[2])))^2
        else
            # penalty
            res += (1 - exp(-(x_data[i] - p[1]) / p[2]))^2
        end
    end
    sqrt(res)
end

exponential_error_x(x_data,y_data) = function (p)
    sqrt(1/length(x_data)*sum((x_data .- quantile.(GeneralizedPareto(p[1],p[2],p[3]),y_data)) .^ 2))
end

pareto_error(x_data, y_data) = function (p)
    res = 0.0
    for i in 1:size(x_data, 1)
        if (p[1] <= x_data[i])
            res += (y_data[i] - (1 - (1 + p[3] * ((x_data[i] - p[1]) / p[2]))^(-1 / p[3])))^2
        else
            res += x_data[i]^2
        end
    end
    sqrt(res)
end

pareto_error_x(x_data,y_data) = function (p)
    sqrt(1/length(x_data)*sum((x_data .- quantile.(GeneralizedPareto(p[1],p[2],p[3]),y_data)) .^ 2))
end

beta_error(x_data, y_data) = function (p)
    res = 0.0
    for i in 1:size(x_data, 1)
        if (p[1] <= x_data[i] && x_data[i] <= p[1] - p[2] / p[3])
            res += (y_data[i] - (1 - (1 + p[3] * ((x_data[i] - p[1]) / p[2]))^(-1 / p[3])))^2
        else
            res += x_data[i]^2
        end
    end
    sqrt(res)
end

beta_error_x(x_data,y_data) = function (p)
    sqrt(1/length(x_data)*sum((x_data .- quantile.(GeneralizedPareto(p[1],p[2],p[3]),y_data)) .^ 2))
end


"""
    function estimate_exponential_distribution(x_data::Array{T}, y_data::Array{T}) :: Distribution  where {T<:Real}

estimates a generalized pareto distribution with ξ=0 from given cdf-quantiles
# Arguments
- `x_data::Array{T}`: The values for the given quantiles (usually interpreted as water levels). 
- `y_data::Array{T}`: The quantiles (cummulative probabilities).

# Returns
- a Distribution of type GeneralizedPareto with ξ=0. If the cdf fit fails for any reason, a standard exponential distribution (μ=mean(x_data), σ=var(x_data), ξ=0) is returned

# Example
```julia
x_data = [2.48099994659424, 2.57800006866455, 2.69799995422363, 2.78099989891052, 2.8840000629425, 2.95300006866455, 3.01500010490417, 3.09200000762939, 3.13199996948242, 3.18600010871887]
y_data = [0.0, 0.5, 0.8, 0.9, 0.96, 0.98, 0.99, 0.996, 0.998, 0.999]

estimate_exponential_distribution(x_data,y_data)
GeneralizedPareto{Float64}(μ=2.5250140954661506, σ=0.10146756169413544, ξ=0.0)
```
"""
function estimate_exponential_distribution(wl_data::Array{T}, cdf_data::Array{T}) where {T<:Real}
  
    wl_mean = sum((1 .- cdf_data) .* wl_data) / sum(1 .- cdf_data)
    wl_min = minimum(wl_data) - 0.0001
    wl_var = max(sqrt(sum((wl_data .- wl_mean) .^ 2) / size(wl_data, 1)), 0.0001)

    log_1_minus_x = map(p -> log(1-p), cdf_data)
    y_mean = mean(wl_data)
    log_1_minus_x_mean = mean(log_1_minus_x)
  
    slope = sum(dot((wl_data .- y_mean),(log_1_minus_x .- log_1_minus_x_mean)))/sum(dot((log_1_minus_x .- log_1_minus_x_mean),(log_1_minus_x .- log_1_minus_x_mean)))
    intercept = y_mean - slope * log_1_minus_x_mean

    if (slope < 0)
        return GeneralizedPareto(intercept, -slope, 0)
    else
        return GeneralizedPareto(wl_min, wl_var, 0)
    end
end

"""
    function estimate_pareto_distribution(x_data::Array{T}, y_data::Array{T}) :: Distribution  where {T<:Real}

estimates a generalized pareto distribution with ξ<0 from given cdf-quantiles
# Arguments
- `x_data::Array{T}`: The values for the given quantiles (usually interpreted as water levels). 
- `y_data::Array{T}`: The quantiles (cummulative probabilities).

# Returns
- a Distribution of type GeneralizedPareto with ξ>0. If the cdf fit fails for any reason, a standard Pareto distribution (μ=mean(x_data), σ=var(x_data), ξ=0.5) is returned

# Example
```julia
x_data = [2.48099994659424, 2.57800006866455, 2.69799995422363, 2.78099989891052, 2.8840000629425, 2.95300006866455, 3.01500010490417, 3.09200000762939, 3.13199996948242, 3.18600010871887]
y_data = [0.0, 0.5, 0.8, 0.9, 0.96, 0.98, 0.99, 0.996, 0.998, 0.999]

estimate_pareto_distribution(x_data,y_data)
GeneralizedPareto{Float64}(μ=2.4968211086568735, σ=0.11605522717254095, ξ=0.05)
```
"""
function estimate_pareto_distribution(x_data::Array{T}, y_data::Array{T}) where {T<:Real}
    x_mean = sum((1 .- y_data) .* x_data) / sum(1 .- y_data)
    x_var = max(sqrt(sum((x_data .- x_mean).^ 2) / size(x_data,1)),0.00001)
    x_skewness = sum((((x_data .- x_mean)) ./ x_var) .^ 3) / sum(1 .- y_data)
    if (x_skewness<0) x_skewness = x_skewness * -1 end
    x_mean = minimum(x_data)

    lower_bound = [-Inf, 0.00001, 0.05]
    upper_bound = [Inf, Inf, Inf]
    x_initial = [x_mean, x_var, x_skewness]

    if x_var <= 0
        x_var = 0.001
    end

    gpd_pareto_curve_fit =
        try
            curve_fit(pareto_model, x_data, y_data, x_initial, lower=lower_bound)
        catch
            missing
        end


    gpd_pareto_optim_fit =
        try
            Optim.optimize(x -> gpd_pareto_error_x(x_data, y_data)(x), lower_bound, upper_bound, x_initial, Fminbox(), Optim.Options(outer_iterations=10, iterations=100, show_trace=false, show_every=50))
        catch
            missing
        end

    if (gpd_pareto_curve_fit === missing && gpd_pareto_optim_fit === missing)
        return GeneralizedPareto(x_mean, x_var, 0.5)
    elseif (gpd_pareto_curve_fit === missing && gpd_pareto_optim_fit !== missing)
        return GeneralizedPareto(gpd_pareto_optim_fit.minimizer[1], gpd_pareto_optim_fit.minimizer[2], gpd_pareto_optim_fit.minimizer[3])
    elseif (gpd_pareto_curve_fit !== missing && gpd_pareto_optim_fit === missing)
        return GeneralizedPareto(gpd_pareto_curve_fit.param[1], gpd_pareto_curve_fit.param[2], gpd_pareto_curve_fit.param[3])
    else
        error_gpd_pareto_curve_fit = sqrt((1/length(gpd_pareto_curve_fit.resid))*sum(gpd_pareto_curve_fit.resid .^ 2))
        error_gpd_pareto_optim_fit = gpd_pareto_optim_fit.minimum
        if error_gpd_pareto_curve_fit < error_gpd_pareto_optim_fit
            return GeneralizedPareto(gpd_pareto_curve_fit.param[1], gpd_pareto_curve_fit.param[2], gpd_pareto_curve_fit.param[3])
        else
            return GeneralizedPareto(gpd_pareto_optim_fit.minimizer[1], gpd_pareto_optim_fit.minimizer[2], gpd_pareto_optim_fit.minimizer[3])
        end
    end
end

"""
    function estimate_beta_distribution(x_data::Array{T}, y_data::Array{T}) :: Distribution  where {T<:Real}

estimates a generalized pareto distribution from given cdf-quantiles
# Arguments
- `x_data::Array{T}`: The values for the given quantiles (usually interpreted as water levels). 
- `y_data::Array{T}`: The quantiles (cummulative probabilities).

# Returns
- a Distribution of type GeneralizedPareto with ξ<0. If the cdf fit fails for any reason, a standard Beta distribution (μ=mean(x_data), σ=var(x_data), ξ=-0.5) is returned

# Example
```julia
x_data = [2.48099994659424, 2.57800006866455, 2.69799995422363, 2.78099989891052, 2.8840000629425, 2.95300006866455, 3.01500010490417, 3.09200000762939, 3.13199996948242, 3.18600010871887]
y_data = [0.0, 0.5, 0.8, 0.9, 0.96, 0.98, 0.99, 0.996, 0.998, 0.999]

estimate_beta_distribution(x_data,y_data)
GeneralizedPareto{Float64}(μ=2.4809617409293696, σ=0.3821696157626704, ξ=-6.909862679190581)
```
"""
function estimate_beta_distribution(x_data::Array{T}, y_data::Array{T}) where {T<:Real}
    x_mean = sum((1 .- y_data) .* x_data) / sum(1 .- y_data)
    x_var = max(sqrt(sum((x_data .- x_mean).^ 2) / size(x_data,1)),0.00001)
    x_skewness = sum((((x_data .- x_mean)) ./ x_var) .^ 3) / sum(1 .- y_data)
    if (x_skewness>0) x_skewness = x_skewness * -1 end
    x_mean = minimum(x_data)


    lower_bound = [-Inf, 0.00001, -Inf]
    upper_bound = [Inf, Inf, -0.05]
    x_initial = [x_mean, x_var, x_skewness]

    if x_var <= 0
        x_var = 0.001
    end

    gpd_beta_curve_fit =
        try
            curve_fit(beta_model, x_data, y_data, x_initial, lower=lower_bound, upper=upper_bound)
        catch
            missing
        end

    gpd_beta_optim_fit =
        try
            optimize(x -> gpd_beta_error_x(x_data, y_data)(x), lower_bound, upper_bound, x_initial, Optim.Options(outer_iterations=1500, iterations=1000))
        catch
            missing
        end

    if (gpd_beta_curve_fit === missing && gpd_beta_optim_fit === missing)
        return GeneralizedPareto(x_mean, x_var, -0.5)
    elseif (gpd_beta_curve_fit === missing && gpd_beta_optim_fit !== missing)
        println(gpd_beta_optim_fit.minimizer)
        return GeneralizedPareto(gpd_beta_optim_fit.minimizer[1], gpd_beta_optim_fit.minimizer[2], gpd_beta_optim_fit.minimizer[3])
    elseif (gpd_beta_curve_fit !== missing && gpd_beta_optim_fit === missing)
        return GeneralizedPareto(gpd_beta_curve_fit.param[1], gpd_beta_curve_fit.param[2], gpd_beta_curve_fit.param[3])
    else
        error_gpd_beta_curve_fit = sqrt((1/length(gpd_beta_curve_fit.resid))*sum(gpd_beta_curve_fit.resid .^ 2))
        error_gpd_beta_optim_fit = gpd_beta_optim_fit.minimum
        if error_gpd_beta_curve_fit < error_gpd_beta_optim_fit
            return GeneralizedPareto(gpd_beta_curve_fit.param[1], gpd_beta_curve_fit.param[2], gpd_beta_curve_fit.param[3])
        else
            return GeneralizedPareto(gpd_beta_optim_fit.minimizer[1], gpd_beta_optim_fit.minimizer[2], gpd_beta_optim_fit.minimizer[3])
        end
    end
end


"""
    function estimate_gp_distribution(x_data::Array{T}, y_data::Array{T}) :: (Distribution,Float64)  where {T<:Real}

estimates a generalized pareto distribution from given cdf-quantiles
# Arguments
- `x_data::Array{T}`: The values for the given quantiles (usually interpreted as water levels). 
- `y_data::Array{T}`: The quantiles (cummulative probabilities).

# Returns
- a pair (Ditribution,Float64) where the first element is a distribution of type GeneralizedPareto, 
  the second element is the squared mean error this distribution produces on the input data

# Example
```julia
x_data = [2.48099994659424, 2.57800006866455, 2.69799995422363, 2.78099989891052, 2.8840000629425, 2.95300006866455, 3.01500010490417, 3.09200000762939, 3.13199996948242, 3.18600010871887]
y_data = [0.0, 0.5, 0.8, 0.9, 0.96, 0.98, 0.99, 0.996, 0.998, 0.999]

estimate_gp_distribution(x_data,y_data)
(GeneralizedPareto{Float64}(μ=2.5250140954661506, σ=0.10146756169413544, ξ=0.0), 0.027488131754383784)
```
"""
function estimate_gp_distribution(x_data::Array{T}, y_data::Array{T}) where {T<:Real}
    gpd_exponential = estimate_exponential_distribution(x_data, y_data) # ξ = 0
    gpd_pareto = estimate_pareto_distribution(x_data, y_data)
    gpd_beta = estimate_beta_distribution(x_data, y_data)

    my_exponential_error = exponential_error_x(x_data, y_data)([gpd_exponential.μ, gpd_exponential.σ, gpd_exponential.ξ])
    my_gpd_pareto_error = pareto_error_x(x_data, y_data)([gpd_pareto.μ, gpd_pareto.σ, gpd_pareto.ξ])
    my_gpd_beta_error = beta_error_x(x_data, y_data)([gpd_beta.μ, gpd_beta.σ, gpd_beta.ξ])

    if my_exponential_error <= my_gpd_pareto_error && my_exponential_error <= my_gpd_beta_error
        return (gpd_exponential,my_exponential_error)
    elseif my_gpd_pareto_error <= my_gpd_beta_error
        return (gpd_pareto,my_gpd_pareto_error)
    else
        return (gpd_beta,my_gpd_beta_error)
    end
end
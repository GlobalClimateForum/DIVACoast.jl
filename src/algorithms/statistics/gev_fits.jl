export estimate_gumbel_distribution,  estimate_frechet_distribution
export estimate_weibull_distribution, estimate_gev_distribution

using LsqFit
using Distributions

#@. gumbel_model(x::T, p::Array{T}) where {T<:Real} = exp(-exp(-(x - p[1]) / p[2]))
#@. frechet_model(x, p) = if (any(((x .- p[1]) / p[2]) .<= -1/p[3])) map(x -> 0, x) else exp(-(1 + p[3] * ((x - p[1]) / p[2]))^(-1 / p[3])) end
#@. weibull_model(x, p) = if (any(((x .- p[1]) / p[2]) .>= 1/abs(p[3]))) map(x -> 1, x) else exp(-(1 + p[3] * ((x - p[1]) / p[2]))^(-1 / p[3])) end

# the cdf of the three cases. Note: in frechet and weibull case domain restriction has to be taken into account
gumbel_model(x, p) = @. exp(-exp(-(x - p[1]) / p[2]))
frechet_model(x, p) = if (any(((x .- p[1]) / p[2]) .<= -1/p[3])) map(x -> 0, x) else @. exp(-(1 + p[3] * ((x - p[1]) / p[2]))^(-1 / p[3])) end
weibull_model(x, p) = if (any(((x .- p[1]) / p[2]) .>= 1/abs(p[3]))) map(x -> 1, x) else @. exp(-(1 + p[3] * ((x - p[1]) / p[2]))^(-1 / p[3])) end

"""
This function tries to fit a gumbel distribution to given data. 
    x is the actual data (e.g. water level).
    y are the cdf values for the data in x (i.e. values between 0 and 1 - to be interpreted as quantiles). 
The funtion returns a GeneralizedExtremeValue (GEV) with the third (shape, ξ) parameter being zero. If the cdf fit fails for any reason, 
the standard gumbel distribution (μ=0.0, σ=1.0, ξ=0.0) is returned
"""
function estimate_gumbel_distribution(x_data::Array{T}, y_data::Array{T}) where {T<:Real}
    try
        fit = curve_fit(gumbel_model, x_data, y_data, [0.0, 1.0], lower=[-Inf, 0.001])
        return GeneralizedExtremeValue(fit.param[1], fit.param[2], 0)
    catch
        return GeneralizedExtremeValue(0.0, 1.0, 0)
    end
end

"""
This function fits a Frechet Distribution to the inserted data. y should be the return 
period and x the corresponding water level height. The funtion returns a GeneralizedExtremeValue (GEV).

This function tries to fit a Frechet distribution to given data. 
    x is the actual data (e.g. water level).
    y are the cdf values for the data in x (i.e. values between 0 and 1 - to be interpreted as quantiles). 
The funtion returns a GeneralizedExtremeValue (GEV) with the third (shape, ξ) parameter being bigger than zero. If the cdf fit fails for any reason, 
a standard Frechet distribution (μ=0.0, σ=1.0, ξ=1.0) is returned
"""
function estimate_frechet_distribution(x_data::Array{T}, y_data::Array{T}) where {T<:Real}
    try
        fit = curve_fit(frechet_model, x_data, y_data, [0.0, 1.0, 1.0], lower=[-Inf, 0.001, 0.001])
        return GeneralizedExtremeValue(fit.param[1], fit.param[2], fit.param[3])
    catch
        return GeneralizedExtremeValue(0.0, 1.0, 1.0)
    end
end

"""
This function fits a Weibull Distribution to the inserted data. y should be the return 
    period and x the corresponding water level height. The funtion returns a GeneralizedExtremeValue (GEV).
    
    This function tries to fit a Weibull distribution to given data. 
        x is the actual data (e.g. water level).
        y are the cdf values for the data in x (i.e. values between 0 and 1 - to be interpreted as quantiles). 
    The funtion returns a GeneralizedExtremeValue (GEV) with the third (shape, ξ) parameter being smaller than zero. If the cdf fit fails for any reason, 
    a standard Weibull distribution (μ=0.0, σ=1.0, ξ=-1.0) is returned
"""
function estimate_weibull_distribution(x_data::Array{T}, y_data::Array{T}) where {T<:Real}
    try
        fit = curve_fit(weibull_model, x_data, y_data, [0.0, 1.0, -1.0], lower=[-Inf, 0.001, -Inf], upper = [Inf,Inf,-0.001])
        return GeneralizedExtremeValue(fit.param[1], fit.param[2], fit.param[3])
    catch
        return GeneralizedExtremeValue(0.0, 1.0, -1.0)
    end
end

"""
This function fits an extreme value distribution to the inserted data. y should be the return 
period and x the corresponding water level height. The funtion returns a GeneralizedExtremeValue (GEV) and uses the best fit 
out of the Gumbel, Frechet and Weibull model based on the summed squared residuals.
"""
function estimate_gev_distribution(x_data::Array{T}, y_data::Array{T}) where {T<:Real}
    fit_gumbel  = 
    try
        curve_fit(gumbel_model, x_data, y_data, [0.0, 1.0], lower=[-Inf, 0.001])
    catch
        missing
    end
    
    fit_frechet = 
    try
        curve_fit(frechet_model, x_data, y_data, [0.0, 1.0, 1.0], lower=[-Inf, 0.001, 0.001])
    catch
        missing
    end
    
    fit_weibull = 
    try
        curve_fit(weibull_model, x_data, y_data, [0.0, 1.0, -1.0], lower=[-Inf, 0.001, -Inf], upper = [Inf,Inf,-0.001])
    catch
        missing
    end

    if fit_gumbel === missing && fit_frechet === missing && fit_weibull === missing
        return GeneralizedExtremeValue(0.0, 1.0, 0)
    end
    
    if (fit_gumbel  === missing && fit_frechet !== missing) fit_gumbel = fit_frechet end
    if (fit_frechet === missing && fit_gumbel !== missing)  fit_frechet = fit_gumbel end
    if (fit_weibull === missing && fit_gumbel !== missing)  fit_weibull = fit_gumbel end
    if (fit_gumbel  === missing && fit_frechet === missing && fit_weibull !== missing) fit_gumbel = fit_weibull end
    if (fit_frechet === missing && fit_gumbel  === missing && fit_weibull !== missing) fit_frechet = fit_weibull end
    if (fit_weibull === missing && fit_gumbel  === missing && fit_frechet !== missing) fit_weibull = fit_frechet end

    sqrt_sum_sq_res_gumbel  = sqrt(sum(fit_gumbel.resid.^2))
    sqrt_sum_sq_res_frechet = sqrt(sum(fit_frechet.resid.^2))
    sqrt_sum_sq_res_weibull = sqrt(sum(fit_weibull.resid.^2))

    if (sqrt_sum_sq_res_frechet <= sqrt_sum_sq_res_weibull) && (sqrt_sum_sq_res_frechet < sqrt_sum_sq_res_gumbel)
        return GeneralizedExtremeValue(fit_frechet.param[1], fit_frechet.param[2], fit_frechet.param[3])
    end

    if (sqrt_sum_sq_res_weibull <= sqrt_sum_sq_res_frechet) && (sqrt_sum_sq_res_weibull < sqrt_sum_sq_res_gumbel)
        return GeneralizedExtremeValue(fit_weibull.param[1], fit_weibull.param[2], fit_weibull.param[3])
    end

    return GeneralizedExtremeValue(fit_gumbel.param[1], fit_gumbel.param[2], 0)
end
export estimate_exponential_distribution,  estimate_gd_positive_distribution
export estimate_gd_positive_distribution, estimate_gp_distribution

using LsqFit
using Distributions

exponential_model(x, p) = map(x -> (x >= p[1]) ? 1-exp(-(x - p[1]) / p[2]) : 0, x)
gdp_positive_model(x, p) = map(x -> (x >= p[1]) ? 1-(1 + p[3] * ((x - p[1]) / p[2]))^(-1 / p[3]) : 0, x)
gdp_negative_model(x, p) = map(x -> ((x >= p[1]) &&  (x <= p[1] - p[2]/p[3])) ? 1-(1 + p[3] * ((x - p[1]) / p[2]))^(-1 / p[3]) : (x >= p[1]) ? 1 : 0, x)

"""
This function tries to fit an exponential distribution to given data. 
    x is the actual data (i.e. water level).
    y are the cdf values for the data in x (i.e. values between 0 and 1). 
The funtion returns a GeneralizedPareto (GPD) with the third shape parameter being zero. If the cdf fit fails for any reason, the standard 
exponential distribution (μ=0) is returned
"""
function estimate_exponential_distribution(x_data::Array{T}, y_data::Array{T}) where {T<:Real}
    try
        fit = curve_fit(exponential_model, x_data, y_data, [0.0, 1.0], lower=[-Inf, 0.001])
        return GeneralizedPareto(fit.param[1], fit.param[2], 0)
    catch
        return GeneralizedPareto(0.0, 1.0, 0)
    end
end

"""
This function fits a Frechet Distribution to the inserted data. y should be the return 
period and x the corresponding water level height. The funtion returns a GeneralizedExtremeValue (GEV).
"""
function estimate_gd_positive_distribution(x_data::Array{T}, y_data::Array{T}) where {T<:Real}
    try
        fit = curve_fit(gdp_positive_model, x_data, y_data, [0.0, 1.0, 0.5], lower=[-Inf, 0.001, 0.001])
        return GeneralizedPareto(fit.param[1], fit.param[2], fit.param[3])
    catch
        return GeneralizedPareto(0.0, 1.0, 0.5)
    end
end

"""
This function fits a Weibull Distribution to the inserted data. y should be the return 
period and x the corresponding water level height. The funtion returns a GeneralizedExtremeValue (GEV).
"""
function estimate_gd_negative_distribution(x_data::Array{T}, y_data::Array{T}) where {T<:Real}
    try
        fit = curve_fit(gdp_negative_model, x_data, y_data, [0.0, 1.0, -0.5], lower=[-Inf, 0.001, -Inf], upper = [Inf,Inf,-0.001])
        return GeneralizedPareto(fit.param[1], fit.param[2], fit.param[3])
    catch
        return GeneralizedPareto(0.0, 1.0, -0.5)
    end
end

"""
This function fits an extreme value distribution to the inserted data. y should be the return 
period and x the corresponding water level height. The funtion returns a GeneralizedExtremeValue (GEV) and uses the best fit 
out of the Gumbel, Frechet and Weibull model based on the summed squared residuals.
"""
function estimate_gp_distribution(x_data::Array{T}, y_data::Array{T}) where {T<:Real}
    fit_exponential  = 
    try
        curve_fit(exponential_model, x_data, y_data, [0.0, 1.0], lower=[-Inf, 0.001])
    catch
        missing
    end
    
    fit_gdp_positive = 
    try
        curve_fit(gdp_positive_model, x_data, y_data, [0.0, 1.0, 0.5], lower=[-Inf, 0.001, 0.05])
    catch
        missing
    end
    
    fit_gdp_negative = 
    try
        curve_fit(gdp_negative_model, x_data, y_data, [0.0, 1.0, -0.5], lower=[-Inf, 0.001, -Inf], upper = [Inf,Inf,-0.05])
    catch
        missing
    end

    if fit_exponential === missing && fit_gdp_positive === missing && fit_gdp_negative === missing
        return GeneralizedPareto(0.0, 1.0, 0)
    end
    
    if (fit_exponential  === missing && fit_gdp_positive !== missing) fit_exponential = fit_gdp_positive end
    if (fit_gdp_positive === missing && fit_exponential !== missing)  fit_gdp_positive = fit_exponential end
    if (fit_gdp_negative === missing && fit_exponential !== missing)  fit_gdp_negative = fit_exponential end
    if (fit_exponential  === missing && fit_gdp_positive === missing && fit_gdp_negative !== missing) fit_exponential = fit_gdp_negative end
    if (fit_gdp_positive === missing && fit_exponential  === missing && fit_gdp_negative !== missing) fit_gdp_positive = fit_gdp_negative end
    if (fit_gdp_negative === missing && fit_exponential  === missing && fit_gdp_positive !== missing) fit_gdp_negative = fit_gdp_positive end

    sqrt_sum_sq_res_exponential  = sqrt(sum(fit_exponential.resid.^2))
    sqrt_sum_sq_res_gdp_positive = sqrt(sum(fit_gdp_positive.resid.^2))
    sqrt_sum_sq_res_gdp_negative = sqrt(sum(fit_gdp_negative.resid.^2))

    if (sqrt_sum_sq_res_gdp_positive  <= sqrt_sum_sq_res_gdp_negative) && (sqrt_sum_sq_res_gdp_positive  < sqrt_sum_sq_res_exponential)
        return GeneralizedPareto(fit_gdp_positive.param[1], fit_gdp_positive.param[2], fit_gdp_positive.param[3])
    end

    if (sqrt_sum_sq_res_gdp_negative <= sqrt_sum_sq_res_gdp_positive ) && (sqrt_sum_sq_res_gdp_negative < sqrt_sum_sq_res_exponential)
        return GeneralizedPareto(fit_gdp_negative.param[1], fit_gdp_negative.param[2], fit_gdp_negative.param[3])
    end

    return GeneralizedPareto(fit_exponential.param[1], fit_exponential.param[2], 0)
end
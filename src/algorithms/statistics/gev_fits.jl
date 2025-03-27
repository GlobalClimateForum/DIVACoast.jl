export estimate_gumbel_distribution, estimate_frechet_distribution
export estimate_weibull_distribution, estimate_gev_distribution
export estimate_gumbel_distribution_old, gumbel_error, frechet_error, weibull_error, gumbel_error_x

using LsqFit
using Distributions
using Optim
#test Vanessa
# the cdf of the three cases. Note: in frechet and weibull case domain restriction has to be taken into account
gumbel_model(x, p) = @. exp(-exp(-(x - p[1]) / p[2]))
frechet_model(x, p) = map(x -> (p[1] - p[2] / p[3] <= x) ? exp(-((1 + p[3] * ((x - p[1]) / p[2]))^(-1 / p[3]))) : 0, x)
weibull_model(x, p) = map(x -> (x <= p[1] - p[2] / p[3]) ? exp(-((1 + p[3] * ((x - p[1]) / p[2]))^(-1 / p[3]))) : 1, x)

# explicit error functions
gumbel_error(x_data, y_data) = function (p)
    sqrt(sum((y_data .- @. exp(-exp(-(x_data - p[1]) / p[2]))) .^ 2))
end

gumbel_error_x(x_data,y_data) = function (p)
    sqrt(1/length(x_data)*sum((x_data .- quantile.(GeneralizedExtremeValue(p[1],p[2],p[3]),y_data)) .^ 2))
end

frechet_error(x_data, y_data) = function (p)
    res = 0.0
    for i in 1:size(x_data, 1)
        if (p[1] - p[2] / p[3] <= x_data[i])
            res += (y_data[i] - exp(-(1 + p[3] * ((x_data[i] - p[1]) / p[2]))^(-1 / p[3])))^2
        else
            res += size(x_data, 1)
        end
    end
    sqrt(res)
end

frechet_error_x(x_data,y_data) = function (p)
    sqrt(1/length(x_data)*sum((x_data .- quantile.(GeneralizedExtremeValue(p[1],p[2],p[3]),y_data)) .^ 2))
end

weibull_error(x_data, y_data) = function (p)
    res = 0.0
    for i in 1:size(x_data, 1)
        # here I do not put the condition x_data[i] <= p[1] - p[2] / p[3]
        # as this one is equivalent but numerically more stable
        if (p[3] * (x_data[i] - p[1]) / p[2] >= -1)
            res += (y_data[i] - exp(-((1 + p[3] * ((x_data[i] - p[1]) / p[2]))^(-1 / p[3]))))^2
        else
            res += size(x_data, 1)
        end
    end
    sqrt(res)
end

weibull_error_x(x_data,y_data) = function (p)
    sqrt(1/length(x_data)*sum((x_data .- quantile.(GeneralizedExtremeValue(p[1],p[2],p[3]),y_data)) .^ 2))
end

"""
This function tries to fit a gumbel distribution to given data. 
    x is the actual data (e.g. water level).
    y are the empirical cdf values for the data in x (i.e. values between 0 and 1 - to be interpreted as quantiles). 
The funtion returns a GeneralizedExtremeValue (GEV) with the third (shape, ξ) parameter being zero. If the cdf fit fails for any reason, 
the standard gumbel distribution (μ=mean(data), σ=var(data), ξ=0.0) is returned
"""
function estimate_gumbel_distribution(x_data::Array{T}, y_data::Array{T}) where {T<:Real}
    x_mean = sum((1 .- y_data) .* x_data) / sum(1 .- y_data)
    x_var = max(sqrt(sum((x_data .- x_mean).^ 2) / size(x_data,1)),0.0001)
    lower_bound = [-Inf, 0.0000001]
    upper_bound = [Inf, Inf]
    x_initial = [x_mean, x_var]

    gumbel_curve_fit =
        try
            curve_fit(gumbel_model, x_data, y_data, x_initial, lower=lower_bound)
        catch
            missing
        end

    gumbel_optim_fit =
        try
            optimize(x -> gumbel_error_x(x_data, y_data)(x), lower_bound, upper_bound, x_initial)
        catch
            missing
        end

    if (gumbel_curve_fit === missing && gumbel_optim_fit === missing)
        return GeneralizedExtremeValue(x_mean, x_var, 0)
    elseif (gumbel_curve_fit === missing && gumbel_optim_fit !== missing)
        return GeneralizedExtremeValue(gumbel_optim_fit.minimizer[1], gumbel_optim_fit.minimizer[2], 0)
    elseif (gumbel_curve_fit !== missing && gumbel_optim_fit === missing)
        return GeneralizedExtremeValue(gumbel_curve_fit.param[1], gumbel_curve_fit.param[2], 0)
    else
        error_gumbel_curve_fit = sqrt((1/length(gumbel_curve_fit.resid))*sum(gumbel_curve_fit.resid .^ 2))
        #divide by n here as well
        error_gumbel_optim_fit = gumbel_optim_fit.minimum
        if error_gumbel_curve_fit < error_gumbel_optim_fit
            return GeneralizedExtremeValue(gumbel_curve_fit.param[1], gumbel_curve_fit.param[2], 0)
        else
            return GeneralizedExtremeValue(gumbel_optim_fit.minimizer[1], gumbel_optim_fit.minimizer[2], 0)
        end
    end
end


"""
This function fits a Frechet Distribution to the inserted data. y should be the return 
period and x the corresponding water level height. The funtion returns a GeneralizedExtremeValue (GEV).

This function tries to fit a Frechet distribution to given data. 
    x is the actual data (e.g. water level).
    y are the empirical cdf values for the data in x (i.e. values between 0 and 1 - to be interpreted as quantiles). 
The funtion returns a GeneralizedExtremeValue (GEV) with the third (shape, ξ) parameter being bigger than zero. If the cdf fit fails for any reason, 
a standard Frechet distribution (μ=mean(data), σ=var(data), ξ=0.5) is returned
"""
function estimate_frechet_distribution(x_data::Array{T}, y_data::Array{T}) where {T<:Real}
    x_mean = sum((1 .- y_data) .* x_data) / sum(1 .- y_data)
    x_var = max(sqrt(sum((x_data .- x_mean).^ 2) / size(x_data,1)),0.0001)
    x_skewness = sum((((x_data .- x_mean)) ./ x_var) .^ 3) / sum(1 .- y_data)
    if (x_skewness<0) x_skewness = x_skewness * -1 end
    lower_bound = [-Inf, 0.0000001, 0.05]
    upper_bound = [Inf, Inf, Inf]
    x_initial = [x_mean, x_var, x_skewness]

    #println("my initial values: ", x_initial)

    frechet_curve_fit =
        try
            curve_fit(frechet_model, x_data, y_data, x_initial, lower=lower_bound)
        catch
            missing
        end

    frechet_optim_fit =
        try
            optimize(x -> frechet_error_x(x_data, y_data)(x), lower_bound, upper_bound, x_initial)
        catch
            missing
        end

    if (frechet_curve_fit === missing && frechet_optim_fit === missing)
        #println("both missing")
        return GeneralizedExtremeValue(x_mean, x_var, 0.5)
    elseif (frechet_curve_fit === missing && frechet_optim_fit !== missing)
        #println("curve missing")
        return GeneralizedExtremeValue(frechet_optim_fit.minimizer[1], frechet_optim_fit.minimizer[2], frechet_optim_fit.minimizer[3])
    elseif (frechet_curve_fit !== missing && frechet_optim_fit === missing)
        #println("optim missing")
        return GeneralizedExtremeValue(frechet_curve_fit.param[1], frechet_curve_fit.param[2], frechet_curve_fit.param[3])
    else
        #println("both there")
        error_frechet_curve_fit = sqrt((1/length(frechet_curve_fit.resid))*sum(frechet_curve_fit.resid .^ 2))
        error_frechet_optim_fit = frechet_optim_fit.minimum

        if error_frechet_curve_fit < error_frechet_optim_fit
            return GeneralizedExtremeValue(frechet_curve_fit.param[1], frechet_curve_fit.param[2], frechet_curve_fit.param[3])
        else
            return GeneralizedExtremeValue(frechet_optim_fit.minimizer[1], frechet_optim_fit.minimizer[2], frechet_optim_fit.minimizer[3])
        end
    end
end


"""
This function fits a Weibull Distribution to the inserted data. y should be the return 
    period and x the corresponding water level height. The funtion returns a GeneralizedExtremeValue (GEV).
    
    This function tries to fit a Weibull distribution to given data. 
        x is the actual data (e.g. water level).
        y are the cempirical df values for the data in x (i.e. values between 0 and 1 - to be interpreted as quantiles). 
    The funtion returns a GeneralizedExtremeValue (GEV) with the third (shape, ξ) parameter being smaller than zero. If the cdf fit fails for any reason, 
    a standard Weibull distribution (μ=mean(data), σ=var(data), ξ=-0.5) is returned
"""
function estimate_weibull_distribution(x_data::Array{T}, y_data::Array{T}) where {T<:Real}
    x_mean = sum((1 .- y_data) .* x_data) / sum(1 .- y_data)
    x_var = max(sqrt(sum((x_data .- x_mean).^ 2) / size(x_data,1)),0.0001)
    x_skewness = sum((((x_data .- x_mean)) ./ x_var) .^ 3) / sum(1 .- y_data)
    if (x_skewness>0) x_skewness = x_skewness * -1 end
    lower_bound = [-Inf, 0.0000001, -Inf]
    upper_bound = [Inf, Inf, -0.05]
    x_initial = [x_mean, x_var, x_skewness]

    weibull_curve_fit =
        try
            curve_fit(weibull_model, x_data, y_data, x_initial, lower=lower_bound, upper=upper_bound)
        catch
            missing
        end

    weibull_optim_fit =
        try
            optimize(x -> weibull_error_x(x_data, y_data)(x), lower_bound, upper_bound, x_initial)
        catch
            missing
        end

    if (weibull_curve_fit === missing && weibull_optim_fit === missing)
        return GeneralizedExtremeValue(x_mean, x_var, -0.5)
    elseif (weibull_curve_fit === missing && weibull_optim_fit !== missing)
        return GeneralizedExtremeValue(weibull_optim_fit.minimizer[1], weibull_optim_fit.minimizer[2], weibull_optim_fit.minimizer[3])
    elseif (weibull_curve_fit !== missing && weibull_optim_fit === missing)
        return GeneralizedExtremeValue(weibull_curve_fit.param[1], weibull_curve_fit.param[2], weibull_curve_fit.param[3])
    else
        error_weibull_curve_fit = sqrt((1/length(weibull_curve_fit.resid))*sum(weibull_curve_fit.resid .^ 2))
        error_weibull_optim_fit = weibull_optim_fit.minimum
        if error_weibull_curve_fit < error_weibull_optim_fit
            return GeneralizedExtremeValue(weibull_curve_fit.param[1], weibull_curve_fit.param[2], weibull_curve_fit.param[3])
        else
            return GeneralizedExtremeValue(weibull_optim_fit.minimizer[1], weibull_optim_fit.minimizer[2], weibull_optim_fit.minimizer[3])
        end
    end
end



"""
This function fits an extreme value distribution to the inserted data. y should be the return 
period and x the corresponding water level height. The funtion returns a GeneralizedExtremeValue (GEV) and uses the best fit 
out of the Gumbel, Frechet and Weibull model based on the summed squared residuals.
"""
function estimate_gev_distribution(x_data::Array{T}, y_data::Array{T}) where {T<:Real}
    gev_gumbel = estimate_gumbel_distribution(x_data, y_data)
    gev_frechet = estimate_frechet_distribution(x_data, y_data)
    gev_weibull = estimate_weibull_distribution(x_data, y_data)

    my_gumbel_error = gumbel_error_x(x_data, y_data)([gev_gumbel.μ, gev_gumbel.σ, gev_gumbel.ξ])
    my_frechet_error = frechet_error_x(x_data, y_data)([gev_frechet.μ, gev_frechet.σ, gev_frechet.ξ])
    my_weibull_error = weibull_error_x(x_data, y_data)([gev_weibull.μ, gev_weibull.σ, gev_weibull.ξ])

    #println("GUMBEL: ", gev_gumbel, " - ", my_gumbel_error)
    #println("FRECHET: ", gev_frechet, " - ", my_frechet_error)
    #println("WEIBULL: ", gev_weibull, " - ", my_weibull_error)

    if my_gumbel_error <= my_frechet_error && my_gumbel_error <= my_weibull_error
        return (gev_gumbel,my_gumbel_error)
    elseif my_frechet_error <= my_weibull_error
        return (gev_frechet,my_frechet_error)
    else
        return (gev_weibull, my_weibull_error)
    end
end


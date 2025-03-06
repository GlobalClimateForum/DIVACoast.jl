export estimate_exponential_distribution, estimate_gpd_positive_distribution
export estimate_gpd_positive_distribution, estimate_gp_distribution

using LsqFit
using Distributions

using Dates

exponential_model(x, p) = map(x -> (x >= p[1]) ? 1 - exp(-(x - p[1]) / p[2]) : 0, x)
gpd_positive_model(x, p) = map(x -> (x >= p[1]) ? 1 - (1 + p[3] * ((x - p[1]) / p[2]))^(-1 / p[3]) : 0, x)
gpd_negative_model(x, p) = map(x -> ((x >= p[1]) && (x <= p[1] - p[2] / p[3])) ? 1 - (1 + p[3] * ((x - p[1]) / p[2]))^(-1 / p[3]) : (x >= p[1]) ? 1 : 0, x)


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

gpd_positive_error(x_data, y_data) = function (p)
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

gpd_negative_error(x_data, y_data) = function (p)
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



"""
This function tries to fit an exponential distribution to given data. 
    x is the actual data (i.e. water level).
    y are the cdf values for the data in x (i.e. values between 0 and 1). 
The funtion returns a GeneralizedPareto (GPD) with the third shape parameter being zero. If the cdf fit fails for any reason, the standard 
exponential distribution (μ=0) is returned
"""
function estimate_exponential_distribution(x_data::Array{T}, y_data::Array{T}) where {T<:Real}
    x_mean = sum((1 .- y_data) .* x_data) / sum(1 .- y_data)
    x_var = max(sqrt(sum((x_data .- x_mean).^ 2) / size(x_data,1)),0.0001)
    x_mean = minimum(x_data)

    lower_bound = [-Inf, 0.0000001]
    upper_bound = [Inf, Inf]
    x_initial = [x_mean, x_var]

    if x_var <= 0
        x_var = 0.001
    end

    exponential_curve_fit =
        try
            curve_fit(exponential_model, x_data, y_data, x_initial, lower=lower_bound)
        catch
            missing
        end

    exponential_optim_fit =
        try
            optimize(x -> exponential_error(x_data, y_data)(x), lower_bound, upper_bound, x_initial, Optim.Options(outer_iterations=1500, iterations=1000))
        catch
            missing
        end

    if (exponential_curve_fit === missing && exponential_optim_fit === missing)
        return GeneralizedPareto(x_mean, x_var, 0)
    elseif (exponential_curve_fit === missing && exponential_optim_fit !== missing)
        return GeneralizedPareto(exponential_optim_fit.minimizer[1], exponential_optim_fit.minimizer[2], 0)
    elseif (exponential_curve_fit !== missing && exponential_optim_fit === missing)
        return GeneralizedPareto(exponential_curve_fit.param[1], exponential_curve_fit.param[2], 0)
    else
        error_exponential_curve_fit = sqrt(sum(exponential_curve_fit.resid .^ 2))
        error_exponential_optim_fit = exponential_optim_fit.minimum
        if error_exponential_curve_fit < error_exponential_optim_fit
            return GeneralizedPareto(exponential_curve_fit.param[1], exponential_curve_fit.param[2], 0)
        else
            return GeneralizedPareto(exponential_optim_fit.minimizer[1], exponential_optim_fit.minimizer[2], 0)
        end
    end
end

"""
This function fits a gpd_positive Distribution to the inserted data. y should be the return 
period and x the corresponding water level height. The funtion returns a GeneralizedExtremeValue (GEV).
"""
function estimate_gpd_positive_distribution(x_data::Array{T}, y_data::Array{T}) where {T<:Real}
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

    gpd_positive_curve_fit =
        try
            curve_fit(gpd_positive_model, x_data, y_data, x_initial, lower=lower_bound)
        catch
            missing
        end


    gpd_positive_optim_fit =
        try
            Optim.optimize(x -> gpd_positive_error(x_data, y_data)(x), lower_bound, upper_bound, x_initial, Fminbox(), Optim.Options(outer_iterations=10, iterations=100, show_trace=false, show_every=50))
        catch
            missing
        end

    if (gpd_positive_curve_fit === missing && gpd_positive_optim_fit === missing)
        return GeneralizedPareto(x_mean, x_var, 0.5)
    elseif (gpd_positive_curve_fit === missing && gpd_positive_optim_fit !== missing)
        return GeneralizedPareto(gpd_positive_optim_fit.minimizer[1], gpd_positive_optim_fit.minimizer[2], gpd_positive_optim_fit.minimizer[3])
    elseif (gpd_positive_curve_fit !== missing && gpd_positive_optim_fit === missing)
        return GeneralizedPareto(gpd_positive_curve_fit.param[1], gpd_positive_curve_fit.param[2], gpd_positive_curve_fit.param[3])
    else
        error_gpd_positive_curve_fit = sqrt(sum(gpd_positive_curve_fit.resid .^ 2))
        error_gpd_positive_optim_fit = gpd_positive_optim_fit.minimum
        if error_gpd_positive_curve_fit < error_gpd_positive_optim_fit
            return GeneralizedPareto(gpd_positive_curve_fit.param[1], gpd_positive_curve_fit.param[2], gpd_positive_curve_fit.param[3])
        else
            return GeneralizedPareto(gpd_positive_optim_fit.minimizer[1], gpd_positive_optim_fit.minimizer[2], gpd_positive_optim_fit.minimizer[3])
        end
    end
end

"""
This function fits a Generalized Pareto Distribution with negative shape to the inserted data. y should be the return 
period and x the corresponding water level height. The funtion returns a GeneralizedPareto (GPD).
"""
function estimate_gpd_negative_distribution(x_data::Array{T}, y_data::Array{T}) where {T<:Real}
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

    gpd_negative_curve_fit =
        try
            curve_fit(gpd_negative_model, x_data, y_data, x_initial, lower=lower_bound, upper=upper_bound)
        catch
            missing
        end

    gpd_negative_optim_fit =
        try
            optimize(x -> gpd_negative_error(x_data, y_data)(x), lower_bound, upper_bound, x_initial, Optim.Options(outer_iterations=1500, iterations=1000))
        catch
            missing
        end

    if (gpd_negative_curve_fit === missing && gpd_negative_optim_fit === missing)
        return GeneralizedPareto(x_mean, x_var, -0.5)
    elseif (gpd_negative_curve_fit === missing && gpd_negative_optim_fit !== missing)
        println(gpd_negative_optim_fit.minimizer)
        return GeneralizedPareto(gpd_negative_optim_fit.minimizer[1], gpd_negative_optim_fit.minimizer[2], gpd_negative_optim_fit.minimizer[3])
    elseif (gpd_negative_curve_fit !== missing && gpd_negative_optim_fit === missing)
        return GeneralizedPareto(gpd_negative_curve_fit.param[1], gpd_negative_curve_fit.param[2], gpd_negative_curve_fit.param[3])
    else
        error_gpd_negative_curve_fit = sqrt(sum(gpd_negative_curve_fit.resid .^ 2))
        error_gpd_negative_optim_fit = gpd_negative_optim_fit.minimum
        if error_gpd_negative_curve_fit < error_gpd_negative_optim_fit
            return GeneralizedPareto(gpd_negative_curve_fit.param[1], gpd_negative_curve_fit.param[2], gpd_negative_curve_fit.param[3])
        else
            return GeneralizedPareto(gpd_negative_optim_fit.minimizer[1], gpd_negative_optim_fit.minimizer[2], gpd_negative_optim_fit.minimizer[3])
        end
    end
end

"""
This function fits an extreme value distribution to the inserted data. y should be the return 
period and x the corresponding water level height. The funtion returns a GeneralizedPareto (GPD) and uses the best fit 
out of the exponential, positive GPD and negative GPD model based on the summed squared residuals.
"""
function estimate_gp_distribution(x_data::Array{T}, y_data::Array{T}) where {T<:Real}
    #println()
    #print("fit exponential ... ")
    gpd_exponential = estimate_exponential_distribution(x_data, y_data) # ξ = 0
    #println(" done. ", now())
    #print("fit gpd positive ... ")
    gpd_positive = estimate_gpd_positive_distribution(x_data, y_data)
    #println(" done. ", now())
    #print("fit gpd negative ... ")
    gpd_negative = estimate_gpd_negative_distribution(x_data, y_data)
    #println(" done. ", now())

    my_exponential_error = exponential_error(x_data, y_data)([gpd_exponential.μ, gpd_exponential.σ, gpd_exponential.ξ])
    my_gpd_positive_error = gpd_positive_error(x_data, y_data)([gpd_positive.μ, gpd_positive.σ, gpd_positive.ξ])
    my_gpd_negative_error = gpd_negative_error(x_data, y_data)([gpd_negative.μ, gpd_negative.σ, gpd_negative.ξ])

    #println("EXPONENTIAL:  ", gpd_exponential, " - ", my_exponential_error)
    #println("GPD positive: ", gpd_positive, " - ", my_gpd_positive_error)
    #println("GPD negative: ", gpd_negative, " - ", my_gpd_negative_error)

    if my_exponential_error <= my_gpd_positive_error && my_exponential_error <= my_gpd_negative_error
        return gpd_exponential
    elseif my_gpd_positive_error <= my_gpd_negative_error
        return gpd_positive
    else
        return gpd_negative
    end
end
export estimate_gumbel_distribution,  estimate_frechet_distribution
export estimate_weibull_distribution, estimate_gev_distribution

using LsqFit
using Distributions

#@. gumbel_model(x::T, p::Array{T}) where {T<:Real} = exp(-exp(-(x - p[1]) / p[2]))
#@. frechet_model(x, p) = if (any(((x .- p[1]) / p[2]) .<= -1/p[3])) map(x -> 0, x) else exp(-(1 + p[3] * ((x - p[1]) / p[2]))^(-1 / p[3])) end
#@. weibull_model(x, p) = if (any(((x .- p[1]) / p[2]) .>= 1/abs(p[3]))) map(x -> 1, x) else exp(-(1 + p[3] * ((x - p[1]) / p[2]))^(-1 / p[3])) end

@. gumbel_model(x, p) = exp(-exp(-(x - p[1]) / p[2]))
frechet_model(x, p) = if (any(((x .- p[1]) / p[2]) .<= -1/p[3])) map(x -> 0, x) else @. exp(-(1 + p[3] * ((x - p[1]) / p[2]))^(-1 / p[3])) end
weibull_model(x, p) = if (any(((x .- p[1]) / p[2]) .>= 1/abs(p[3]))) map(x -> 1, x) else @. exp(-(1 + p[3] * ((x - p[1]) / p[2]))^(-1 / p[3])) end

function estimate_gumbel_distribution(x_data::Array{T}, y_data::Array{T}) where {T<:Real}
    fit = curve_fit(gumbel_model, x_data, y_data, [0.0, 1.0], lower=[-Inf, 0.001])
    return GeneralizedExtremeValue(fit.param[1], fit.param[2], 0)
end

function estimate_frechet_distribution(x_data::Array{T}, y_data::Array{T}) where {T<:Real}
    fit = curve_fit(frechet_model, x_data, y_data, [0.0, 1.0, 1.0], lower=[-Inf, 0.001, 0.001])
    return GeneralizedExtremeValue(fit.param[1], fit.param[2], fit.param[3])
end

function estimate_weibull_distribution(x_data::Array{T}, y_data::Array{T}) where {T<:Real}
    fit = curve_fit(weibull_model, x_data, y_data, [0.0, 1.0, -1.0], lower=[-Inf, 0.001, -Inf], upper = [Inf,Inf,-0.001])
    return GeneralizedExtremeValue(fit.param[1], fit.param[2], fit.param[3])
end

function estimate_gev_distribution(x_data::Array{T}, y_data::Array{T}) where {T<:Real}
    fit_gumbel  = curve_fit(gumbel_model, x_data, y_data, [0.0, 1.0], lower=[-Inf, 0.001])
    fit_frechet = curve_fit(frechet_model, x_data, y_data, [0.0, 1.0, 1.0], lower=[-Inf, 0.001, 0.001])
    fit_weibull = curve_fit(weibull_model, x_data, y_data, [0.0, 1.0, -1.0], lower=[-Inf, 0.001, -Inf], upper = [Inf,Inf,-0.001])
    
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
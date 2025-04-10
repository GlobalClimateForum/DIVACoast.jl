using Distributions
using StatsPlots

export LinInt, linear_interp, support, probs, cdf, pdf, quantile, manual_integration

"""
    LinInt(xs, ps)

A *Linear Interpolation* creates a linear interpolation between data points and uses a flat extrapolation beyond the range of input data points, i.e. stays constant at the last value.

```julia
d = LinInt(xs, ps)

support(d) # Get a sorted AbstractVector describing the support (xs) of the distribution
probs(d)   # Get a Vector of the probabilities (ps) associated with the support
```
"""
struct LinInt{T<:Real,P<:Real,Ts<:AbstractVector{T},Ps<:AbstractVector{P}} <: ContinuousUnivariateDistribution
    support::Ts
    p::Ps
    function LinInt(xs::Ts, ps::Ps) where {T<:Real,P<:Real,Ts<:AbstractVector{T},Ps<:AbstractVector{P}}
        if length(xs) !=  length(ps) 
            error("length of support and probability vector must be equal")
        elseif !all(x-> (0 <= x <= 1), ps)
            error("all values of the probability vector must be >=0 and <=1")
        elseif !issorted(xs)
            error("the support vector must be sorted")
        elseif !issorted(ps)
            error("the probability vector must be sorted")
        end
        new{T,P,Ts,Ps}(xs,ps)
    end
end

#linear interpolation function
function linear_interp(x_vals, y_vals, x_query)
    idx = findlast(x -> x <= x_query, x_vals)

    # Flat extrapolation with constant value
    if idx === nothing || idx == length(x_vals)
        return y_vals[end]
    end

    x0, y0 = x_vals[idx], y_vals[idx]
    x1, y1 = x_vals[idx + 1], y_vals[idx + 1]

    return y0 + ((y1 - y0) / (x1 - x0)) * (x_query - x0)
end

# Accessors
"""
    support(d::LinInt)

Get a sorted AbstractVector defining the support of `d`.
"""
Distributions.support(d::LinInt) = d.support

"""
    probs(d::LinInt)

Get the vector of probabilities associated with the support of `d`.
"""
Distributions.probs(d::LinInt)  = d.p
"""
    Distributions.cdf(d::LinInt, x::Real)

Cummulative distribution function.
"""
function Distributions.cdf(d::LinInt, x::Real)
    return linear_interp(d.support, d.p, x)
end
""""
    Distributions.quantile(d::LinInt, x::Real)
Evaluate the (generalized) inverse cumulative distribution function at q, also called quantile function.

"""
function Distributions.quantile(d::LinInt, p::Real)
    return linear_interp(d.p, d.support, p)
end
"""
    Base.rand(d::LinInt)

Generate a random number.
"""
function Base.rand(d::LinInt)
    quantile.(d,rand())
end

"""
    Base.rand(d::LinInt,n::Int64)

Generate a vextor of n random numbers
"""
function Base.rand(d::LinInt,n::Int64)
    quantile.(d,rand(n))
end


"""
    StatsPlots.plot(d::ContNonparamDist)

Plot the distribution
"""
function StatsPlots.plot(d::LinInt)
    scatter(support(d),probs(d), label="Data points")
    plot!([support(d);2*support(d)[end]],cdf.(d,[support(d);2*support(d)[end]]), label="Linear Interpolation")

end

"""
    Naive PDF via approximate differentiation of CDF.
"""

function Distributions.pdf(d::LinInt, t::Real)
    h = 1e-10
    return (cdf(d, t + h) - cdf(d, t)) / h
end

"""
    Helper function for manual integration calculating a single trapezoidal approximation under function f and x-axis points a and b.
"""
function trapezoidal_approximation(f, a::Real, b::Real)
    return (b - a) / 2 * (f(a) + f(b))
end

"""
    Manual integration using single trapezoidal approximation for function f() using LinInt as separators for trapezoids and lower integral boundary a and higher boundary b.
"""
function manual_integration(f, d, a::Real, b::Real)
    #find lower and higher trapezoidal boundaries based on LinInt d
    idx = findfirst(x -> x > a, support(d))
    if isnothing(idx)  # If all elements are ≤ new_elem, keep only new_elem and maximum
        integration_boundaries = [a;b]
    else
        integration_boundaries = [a; support(d)[idx:end];b]  # Construct the new array
    end
    integration_boundaries = [(integration_boundaries[i], integration_boundaries[i+1]-0.01) for i in 1:length(integration_boundaries)-1]

    integral=0
    for (x1,x2) in integration_boundaries
        integral = integral + trapezoidal_approximation(f, x1, x2)
    end
    return integral
end

#############
# test code #
#############

#xs = [0.0,1.0,2.0,3.0,4.0]
#ps = [0,.1,.5,.9,1.0]   
#d = LinInt(xs,ps)
#println(d)
#println(cdf(d,3.0))
#println(pdf(d,3.0))
#println(rand(d))
#display(plot(d))

using DataInterpolations
using Distributions
using StatsPlots

"""
    ContNonparamDist(xs, ps)

A *Continuous nonparametric distribution* explicitly defines an arbitrary cummulative probability distribution function in terms of a list of real support values and their
corresponding probabilities

```julia
d = ContNonparamDist(xs, ps)

support(d) # Get a sorted AbstractVector describing the support (xs) of the distribution
probs(d)   # Get a Vector of the probabilities (ps) associated with the support
```
"""
struct ContNonparamDist{T<:Real,P<:Real,Ts<:AbstractVector{T},Ps<:AbstractVector{P}} <: ContinuousUnivariateDistribution
    support::Ts
    p::Ps
    interpol
    function ContNonparamDist(xs::Ts, ps::Ps, interpol::Any) where {T<:Real,P<:Real,Ts<:AbstractVector{T},Ps<:AbstractVector{P}}
        if length(xs) !=  length(ps) 
            error("length of support and probability vector must be equal")
        elseif !all(x-> (0 <= x <= 1), ps)
            error("all values of the probability vector must be >=0 and <=1")
        elseif !issorted(xs)
            error("the support vector must be sorted")
        elseif !issorted(ps)
            error("the probability vector must be sorted")
        end
        new{T,P,Ts,Ps}(xs,ps,interpol)
    end
end

# ContNonparamDist{T,P,Ts,Ps}(xs::Ts, ps::Ps) where {T<:Real,P<:Real,Ts<:AbstractVector{T},Ps<:AbstractVector{P}} = ContNonparamDist{T,P,Ts,Ps}(xs, ps, LagrangeInterpolation(xs,ps))
# ContNonparamDist(xs, ps) = ContNonparamDist(xs, ps, LagrangeInterpolation(xs,ps))
ContNonparamDist(xs, ps) = ContNonparamDist(xs, ps, LinearInterpolation(xs,ps))
# ContNonparamDist(xs, ps) = ContNonparamDist(xs, ps, QuadraticInterpolation(xs,ps))


# Accessors
"""
    support(d::ContNonparamDist)

Get a sorted AbstractVector defining the support of `d`.
"""
support(d::ContNonparamDist) = d.support

"""
    probs(d::ContNonparamDist)

Get the vector of probabilities associated with the support of `d`.
"""
probs(d::ContNonparamDist)  = d.p
"""
    get_interpol(d::ContNonparamDist)

Get the interpolation function
"""
get_interpol(d::ContNonparamDist)  = d.interpol

"""
    Base.rand(d::ContNonparamDist)

Generate a random number.
"""
function Base.rand(d::ContNonparamDist)
    interpol = get_interpol(d)
    interpol.(rand())
end

"""
    Base.rand(d::ContNonparamDist,n::Int64)

Generate a vextor of n random numbers
"""
function Base.rand(d::ContNonparamDist,n::Int64)
    interpol = get_interpol(d)
    interpol.(rand(n))
end

"""
    Distributions.ccdf(d::ContNonparamDist, x::Real)

Complementary cummulative distribution function, also called qunatile function
"""
function Distributions.ccdf(d::ContNonparamDist, x::Real)
    interpol = get_interpol(d)
    interpol.(x)
end

"""
    StatsPlots.plot(d::ContNonparamDist)

Plot the distribution
"""
function StatsPlots.plot(d::ContNonparamDist)
    scatter(support(d),probs(d),label="data")
    ps = 0:0.02:1
    plot!(Distributions.ccdf.(d,ps),ps,label="interpolation")
end


#############
# test code #
#############

# xs = [.0,1.0,2.0,3.0,4.0]
# ps = [0,.1,.5,.9,1.0]   
# d = ContNonparamDist(xs,ps)
# plot(d)
# s = rand(d,10000)
# histogram(s)
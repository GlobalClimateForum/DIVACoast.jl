function expected_damage(hspf::HypsometricProfile{DT}, dist::GeneralizedPareto, wl_lower_limit::Real, s::Array{String}, ddfs::Vector{StandardDDF}, im::IM) where {DT<:Real,IM<:InundationModel}
    if dist.ξ == 0
        println("Special case! ξ==0")
        tol::Real = 1e-3
        x_low = max(minimum(dist), wl_lower_limit)

        inds = map(x -> get_position(hspf, x), s)
        ret = zeros(DT, size(inds, 1))
        for ind in 1:size(inds, 1)
            ret[ind] = expected_damage_integral_computation(x -> f_to_integrate(hspf, dist, x, ddfs[ind], s[ind], im, tol), x_low, maximum(dist), tol)
        end
        return ret
    elseif dist.ξ > 0
        println("Special case! ξ>0")
    else
        dist.ξ < 0
        println("Special case! ξ<0")
    end
end
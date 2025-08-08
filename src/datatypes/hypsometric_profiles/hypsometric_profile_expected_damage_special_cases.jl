using SpecialFunctions

function expected_damage(hpsf::HypsometricProfile{DT}, dist::DIST, wl_lower_limit::Real, inds::Array{Int}, ddfs::Vector{StandardDDF}, im::IM=BathtubInundation(); rtol::Real=1e-3) where {DT<:Real,DIST<:GeneralizedPareto,IM<:BathtubInundation}
    if dist.ξ == 0
        expected_damage_exponential_standard_ddf(hpsf, dist, wl_lower_limit, inds, ddfs, im)
    elseif dist.ξ > 0
        #println("Special case! ξ>0")
        x_low = max(minimum(dist), wl_lower_limit)
        expected_damage_integral_computation(x -> f_to_integrate(hspf, dist, x, inds, ddfs, im; rtol), x_low, maximum(dist), rtol, hspf.width)
    else
        dist.ξ < 0
        #println("Special case! ξ<0")
        x_low = max(minimum(dist), wl_lower_limit)
        expected_damage_integral_computation(x -> f_to_integrate(hspf, dist, x, inds, ddfs, im; rtol), x_low, maximum(dist), rtol, hspf.width)
    end
end


function expected_damage_exponential_standard_ddf(hpsf::HypsometricProfile{DT}, dist::DIST, wl_lower_limit::Real, inds::Array{Int}, ddfs::Vector{StandardDDF}, im::IM=BathtubInundation(); rtol::Real=1e-3) where {DT<:Real,DIST<:GeneralizedPareto,IM<:BathtubInundation}
    wl_lowest = max(minimum(dist), wl_lower_limit)
    ret = zeros(DT, size(inds, 1))

    exp_dist_μ_div_dist_σ = exp(dist.μ / dist.σ)
    log_ddfs_hdd = map(x -> log(x.hdd), ddfs)

    for el_ind in 1:size(hpsf.elevation, 1)-1
        el_high = hpsf.elevation[el_ind+1]
        el_low = hpsf.elevation[el_ind]
        sl = slope(hpsf, el_ind + 1)
        exposure_low = exposure(hpsf, el_low, inds)
        exposure_high = exposure(hpsf, el_high, inds)

        Δ_area = exposure(hpsf, el_high, :area) - exposure(hpsf, el_low, :area)
        if (Δ_area != 0)
            Δ_exp = exposure_high - exposure_low
            ρ_area = hpsf.width / 1000
            ρ_exp = (Δ_exp / (Δ_area / hpsf.width)) / 1000

            for ind in 1:size(inds, 1)
                ret_temp = 0.0
                if (ddfs[ind].hdd > 0)
                    if el_high > wl_lowest
                        l = max(wl_lowest, el_low)
                        ret_temp += ddfs[ind].hdd * log_ddfs_hdd[ind] * (exp((dist.μ - l) / dist.σ) - exp((dist.μ - el_high) / dist.σ))
                        ret_temp -= ddfs[ind].hdd * exp_dist_μ_div_dist_σ *
                                    ((exp(-(el_low - ddfs[ind].hdd) / dist.σ) * expint((l - el_low + ddfs[ind].hdd) / dist.σ) + exp(-l / dist.σ) * log(l - el_low + ddfs[ind].hdd))
                                     -
                                     (exp(-(el_low - ddfs[ind].hdd) / dist.σ) * expint((el_high - el_low + ddfs[ind].hdd) / dist.σ) + exp(-el_high / dist.σ) * log(el_high - el_low + ddfs[ind].hdd)))
                        ret_temp += (-dist.σ - el_high + el_low) * exp((dist.μ - el_high) / dist.σ)
                        ret_temp += (dist.σ + l - el_low) * exp((dist.μ - l) / dist.σ)
                    end

                    l = max(wl_lowest, el_high)
                    ret_temp += ddfs[ind].hdd * exp_dist_μ_div_dist_σ * ((exp(-(el_high - ddfs[ind].hdd) / dist.σ) * expint((l - el_high + ddfs[ind].hdd) / dist.σ) + exp(-l / dist.σ) * log(l - el_high + ddfs[ind].hdd)))
                    ret_temp -= ddfs[ind].hdd * exp_dist_μ_div_dist_σ * ((exp(-(el_low - ddfs[ind].hdd) / dist.σ) * expint((l - el_low + ddfs[ind].hdd) / dist.σ) + exp(-l / dist.σ) * log(l - el_low + ddfs[ind].hdd)))
                    ret_temp += (el_high - el_low) * exp((dist.μ - l) / dist.σ)
                else
                    if el_high > wl_lowest
                        l = max(wl_lowest, el_low)
                        ret_temp -= ((dist.σ + el_high-el_low) * exp((dist.μ - el_high) / dist.σ) - (dist.σ + l-el_low) * exp((dist.μ - l) / dist.σ))
                    end
                    l = max(wl_lowest, el_high)
                    ret_temp += (el_high - el_low) * exp((dist.μ - l) / dist.σ)
                end
                ret[ind] += (ρ_exp[ind] / sl) * ret_temp
            end
        end

    end
    return ret
end

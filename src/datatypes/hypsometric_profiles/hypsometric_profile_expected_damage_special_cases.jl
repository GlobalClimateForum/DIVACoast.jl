using SpecialFunctions

function expected_damage(hpsf::HypsometricProfile{DT}, dist::GeneralizedPareto, wl_lower_limit::Real, s::Array{String}, ddfs::Vector{StandardDDF}, im::IM) where {DT<:Real,IM<:InundationModel}
    if dist.ξ == 0
        println("Special case! ξ==0")
        tol::Real = 1e-3
        x_low = max(minimum(dist), wl_lower_limit)

        inds = map(x -> get_position(hpsf, x), s)
        ret = zeros(DT, size(inds, 1))

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
                println("el_low=", el_low, " el_high=", el_high, " sl=", sl, " ρ_exp =", ρ_exp)

                for ind in 1:size(inds, 1)
                    ret_temp = 0.0
                    if el_high > dist.μ
                        l = max(dist.μ, el_low)
                        ret_temp += ddfs[ind].hdd * log(ddfs[ind].hdd) * (exp((dist.μ - l) / dist.σ) - exp((dist.μ - el_high) / dist.σ))
                        ret_temp -= ddfs[ind].hdd * exp(dist.μ / dist.σ) *
                                    ((exp(-(el_low - ddfs[ind].hdd) / dist.σ) * expint((l - el_low + ddfs[ind].hdd) / dist.σ) + exp(-l / dist.σ) * log(l - el_low + ddfs[ind].hdd))
                                     -
                                     (exp(-(el_low - ddfs[ind].hdd) / dist.σ) * expint((el_high - el_low + ddfs[ind].hdd) / dist.σ) + exp(-el_high / dist.σ) * log(el_high - el_low + ddfs[ind].hdd)))
                        ret_temp += (-dist.σ - el_high + el_low) * exp((dist.μ - el_high) / dist.σ)
                        ret_temp += (dist.σ + l - el_low) * exp((dist.μ - l) / dist.σ)
                    end

                    l = max(dist.μ, el_high)
                    ret_temp += ddfs[ind].hdd * exp(dist.μ / dist.σ) * ((exp(-(el_high - ddfs[ind].hdd) / dist.σ) * expint((l - el_high + ddfs[ind].hdd) / dist.σ) + exp(-l / dist.σ) * log(l - el_high + ddfs[ind].hdd)))
                    ret_temp -= ddfs[ind].hdd * exp(dist.μ / dist.σ) * ((exp(-(el_low - ddfs[ind].hdd) / dist.σ) * expint((l - el_low + ddfs[ind].hdd) / dist.σ) + exp(-l / dist.σ) * log(l - el_low + ddfs[ind].hdd)))
                    ret_temp += (el_high - el_low) * exp((dist.μ - l) / dist.σ)
                    ret[ind] += (ρ_exp[ind] / sl) * ret_temp
                    #ret[ind] += expected_damage_integral_computation(x -> f_to_integrate(hpsf, dist, x, ddfs[ind], s[ind], im, tol), x_low, maximum(dist), tol)
                end
            end

        end
        return ret
    elseif dist.ξ > 0
        println("Special case! ξ>0")
    else
        dist.ξ < 0
        println("Special case! ξ<0")
    end
end
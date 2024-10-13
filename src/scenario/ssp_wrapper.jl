export SSPWrapper, SSPType, AnnualGrowthPercentage, AnnualGrowth, GrowthFactor, SSPWrapper
export ssp_get_growth_factor

using DataFrames

abstract type SSPType end
struct AnnualGrowthPercentage <: SSPType end
struct AnnualGrowth <: SSPType end
struct GrowthFactor <: SSPType end

"""
Wraps SSP Dataset (CSV file).
"""
mutable struct SSPWrapper{T<:SSPType}
    df_ssp::DataFrame
end

# function 
ssp_get_growth(sw::SSPWrapper{AnnualGrowthPercentage}, g::Real) = g / 100
ssp_get_growth(sw::SSPWrapper{AnnualGrowth}, g::Real) = g
ssp_get_growth(sw::SSPWrapper{GrowthFactor}, g::Real) = g - 1

function ssp_get_growth_factor(wrapped_ssp::SSPWrapper{T}, variable::String, country::String, ssp_scenario::String, year1::Int, year2::Int, do_warn = true) where {T<:SSPType}

    function flt(v, r, s)
        v_filter = !ismissing(v) && v == variable
        r_filter = !ismissing(r) && r == country
        s_filter = !ismissing(s) && s == ssp_scenario
        return (v_filter && r_filter && s_filter)
    end

    if (year2 < year1)
        year2, year1 = year1, year2
    end

    ny = year2 - year1
    if (ny == 0)
        return 1.0
    end

    years_available = sort(unique(wrapped_ssp.df_ssp.year))
    ind_y1 = searchsortedfirst(years_available, year1)
    ind_y2 = searchsortedfirst(years_available, year2)

    filtered_df = filter([:Variable, :Region, :Scenario] => flt, wrapped_ssp.df_ssp)
    if (nrow(filtered_df)==0)
        if (do_warn) println("WARNING: $variable for $country in $ssp_scenario not found!") end
        return 1.0
    end

    ret = 1.0
    if (year1 <= years_available[1])
        if (year2 <= years_available[2])
            return ret * (1 + ssp_get_growth(wrapped_ssp, filtered_df[1, :].growth))^(ny)
        else
            ret = ret * (1 + ssp_get_growth(wrapped_ssp, filtered_df[1, :].growth))^(years_available[1] - year1)
        end
    end

    if (ind_y1 == ind_y2)
        return ret * (1 + ssp_get_growth(wrapped_ssp, filtered_df[ind_y1-1, :].growth))^(ny)
    else
        if (ind_y1 > 1)
            ret = ret * (1 + ssp_get_growth(wrapped_ssp, filtered_df[ind_y1-1, :].growth))^(years_available[ind_y1] - year1)
        end
        for ind in (ind_y1+1):ind_y2
            if ind <= size(years_available, 1)
                y2 = years_available[ind]
                if y2 <= year2
                    ret = ret * (1 + ssp_get_growth(wrapped_ssp, filtered_df[ind-1, :].growth))^(years_available[ind] - years_available[ind-1])
                else
                    return ret * (1 + ssp_get_growth(wrapped_ssp, filtered_df[ind-1, :].growth))^(year2 - years_available[ind-1])
                end
            else
                return ret * (1 + ssp_get_growth(wrapped_ssp, filtered_df[ind-1, :].growth))^(year2 - years_available[ind-1])
            end
        end
    end
    return ret
end

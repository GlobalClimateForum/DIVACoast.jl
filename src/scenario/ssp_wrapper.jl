export ssp_get_growth

using DataFrames

function ssp_get_growth(df_ssp::DataFrame, variable::String, country::String, ssp_scenario::String, year1::Int, year2::Int)

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

    years_available = sort(unique(df_ssp.year))
    ind_y1 = searchsortedfirst(years_available, year1)
    ind_y2 = searchsortedfirst(years_available, year2)

    filtered_df = filter([:Variable, :Region, :Scenario] => flt, df_ssp)

    ret = 1.0
    if (year1 < years_available[1])
        if (years2 < years_available[2])
            return ret * (1 + filtered_df[1, :].growth)^(ny)
        else
            ret = ret * (1 + filtered_df[1, :].growth)^(years_available[1] - year1)
        end
    end

    if (ind_y1 == ind_y2)
        return ret * (1 + filtered_df[ind_y1-1, :].growth)^(ny)
    else
        ret = ret * (1 + filtered_df[ind_y1-1, :].growth)^(years_available[ind_y1]-year1)
        for ind in (ind_y1+1):ind_y2
            y2 = years_available[ind]
            if y2<=year2
                ret  = ret * (1 + filtered_df[ind-1, :].growth)^(years_available[ind] - years_available[ind-1])
            else
                return ret * (1 + filtered_df[ind-1, :].growth)^(year2 - years_available[ind-1])
            end
        end
    end
    return ret
end

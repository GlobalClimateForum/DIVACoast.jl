Base.@kwdef struct DIVA_configuration_classic
    maintenance_factor::Float64 = 0.01
    exdam_rtol::Float64 = 0.1
    deconstruction_cost_factor::Float64 = 0.0
end

slrcost_under_given_protection(lcm::LocalCoastalImpactModel{DT,IDT,DATA,DIST}, migration::Bool,
    time_trajectory::Vector{Int}, slr_trajectory::Vector{Float64}, popgrowth_trajectory::Vector{Float64}, assetsgrowth_trajectory::Vector{Float64},
    coast_length::Real, dike_unitcost::Real, discount_rate::Real, conf::DIVA_configuration_classic=DIVA_configuration_classic()) where {DT<:Real,IDT,DATA,DIST<:Distribution} = function (pl::Float64)
    lcm_copy = deepcopy(lcm)
    if (size(time_trajectory, 1) == 0)
        return 0.0
    end

    # here we do the initial dike raising (if appropriate) - cost are store in ret
    start_t = time_trajectory[1]
    initial_dikeheigth = (lcm_copy.protection_level > 0) ? quantile(lcm_copy.surge_model, 1 - 1 / lcm_copy.protection_level) : 0
    target_dikeheigth = (pl > 0) ? quantile(lcm_copy.surge_model, 1 - 1 / pl) : 0
    # the case after the ":" is dike lowering - by now we do not associate cost with that
    ret = (target_dikeheigth >= initial_dikeheigth) ? (target_dikeheigth - initial_dikeheigth) * lcm_copy.data.coast_length * dike_unitcost : ((target_dikeheigth - initial_dikeheigth) * lcm_copy.data.coast_length * dike_unitcost * conf.deconstruction_cost_factor)
    lcm_copy.protection_level = pl
    sea_dike_cost_investment = 0.0
    sea_dike_cost_maintenance = 0.0
    migration_cost = 0.0

    for i in 1:size(time_trajectory, 1)
        lcm_copy.surge_model = DIST(lcm.surge_model.μ + slr_trajectory[i], lcm.surge_model.σ, lcm.surge_model.ξ)
        pop_gf = (i == 1) ? popgrowth_trajectory[i] : popgrowth_trajectory[i] / popgrowth_trajectory[i-1]
        assets_gf = (i == 1) ? assetsgrowth_trajectory[i] : assetsgrowth_trajectory[i] / assetsgrowth_trajectory[i-1]
        time_span = (i == 1) ? 1 : time_trajectory[i] - time_trajectory[i-1]
        multiply_exposure!(lcm_copy.coastal_plain_model, (population=pop_gf, assets=assets_gf))
        if pl > 0
            sea_dike_cost_investment = (i == 1) ? 0 : lcm_copy.data.coast_length * abs((slr_trajectory[i] - slr_trajectory[i-1])) * dike_unitcost
            sea_dike_cost_maintenance = quantile(lcm_copy.surge_model, 1 - 1 / pl) * lcm_copy.data.coast_length * dike_unitcost * conf.maintenance_factor * time_span
        else
            # migrate
            if migration
                migration_data = remove_exposure_below!(lcm_copy.coastal_plain_model, quantile(lcm_copy.surge_model, 0.01))
                migration_cost = migration_data[2] / 1000000
            end
        end
        exdam = expected_damage(lcm_copy, ["assets"], [StandardDDF(1.0)], BathtubInundation(); rtol=conf.exdam_rtol)[1] * time_span / 1000000


        ret += (exdam + sea_dike_cost_investment + sea_dike_cost_maintenance + migration_cost) * (1 - discount_rate)^(time_trajectory[i] - start_t)
    end
    ret
end

function optimal_protection_level_computation(lcm::LocalCoastalImpactModel, migration::Bool,
    slr_trajectory::Vector{T1}, popgrowth_trajectory::Vector{T2}, assetsgrowth_trajectory::Vector{T3}, time_trajectory::Vector{Int},
    coast_length::Real, dike_unitcost::Real, discount_rate::Real, conf::DIVA_configuration_classic=DIVA_configuration_classic()) where {T1,T2,T3<:Real}

    result = optimize(x -> slrcost_under_given_protection(lcm, migration, time_trajectory, slr_trajectory, popgrowth_trajectory, assetsgrowth_trajectory,
            coast_length, dike_unitcost, discount_rate, conf)(x), 1.0, 10000.0)

    cost_no_protection = slrcost_under_given_protection(lcm, migration, time_trajectory, slr_trajectory, popgrowth_trajectory, assetsgrowth_trajectory,
        coast_length, dike_unitcost, discount_rate, conf)(0.0)
    min_pl = if cost_no_protection < result.minimum
        0
    else
        result.minimizer
    end

    return min_pl
end

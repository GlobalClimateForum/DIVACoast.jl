struct DIVA_configuration_classic
  maintenance_factor :: Float64
end


slrcost_under_given_protection(lcm::LocalCoastalImpactModel{DT,IDT,DATA,DIST}, migration :: Bool, time_trajectory :: Vector{Int}, slr_trajectory, popgrowth_trajectory, assetsgrowth_trajectory, coast_length :: Float64, dike_unitcost :: Float64, discount_rate :: Float64) where {DT<:Real,IDT,DATA,DIST<:Distribution} = function(pl :: Float64)
  lcm_copy = deepcopy(lcm)
  if (size(time_trajectory,1)==0) return 0.0 end

  # here we do the initial dike raising (if appropriate) - cost are store in ret
  start_t = time_trajectory[1]
  initial_dikeheigth = (lcm_copy.protection_level>0) ? quantile(lcm_copy.surge_model,1-1/lcm_copy.protection_level) : 0
  target_dikeheigth = (pl>0) ? quantile(lcm_copy.surge_model,1-1/pl) : 0
  # the case after the ":" is dike lowering - by now we do not associate cost with that
  ret = (target_dikeheigth >= initial_dikeheigth) ? (target_dikeheigth-initial_dikeheigth) * lcm_copy.data.coast_length * dike_unitcost : 0
  lcm_copy.protection_level = pl
  sea_dike_cost_investment  = 0.0
  sea_dike_cost_maintenance = 0.0
  migration_cost = 0.0

  for i in 1:size(time_trajectory,1)
    lcm_copy.surge_model = DIST(lcm.surge_model.μ + slr_trajectory[i], lcm.surge_model.σ, lcm.surge_model.ξ)
    pop_gf = (i==1)    ? popgrowth_trajectory[i] : popgrowth_trajectory[i] / popgrowth_trajectory[i-1]
    assets_gf = (i==1) ? assetsgrowth_trajectory[i] : assetsgrowth_trajectory[i] / assetsgrowth_trajectory[i-1]
    time_span = (i==1) ? 1 : time_trajectory[i] - time_trajectory[i-1]
    multiply_exposure!(lcm_copy.coastal_plain_model, (population=pop_gf, assets=assets_gf))
    exdam = expected_damage(lcm_copy, ["assets"], [StandardDDF(1.0)], BathtubInundation(); rtol=0.01)[1]  * time_span / 1000000
    if pl > 0
      sea_dike_cost_investment  = (i==1) ? 0 : lcm_copy.data.coast_length * abs((slr_trajectory[i]-slr_trajectory[i-1])) * dike_unitcost[1]
      sea_dike_cost_maintenance = quantile(lcm_copy.surge_model,1-1/pl) * lcm_copy.data.coast_length * dike_unitcost[1] * 0.01 * time_span
    else
      # migrate
      if migration
        migration_data = remove_exposure_below!(lcm_copy.coastal_plain_model, quantile(lcm_copy.surge_model,0.01))
        migration_cost = migration_data[2] / 1000000
      end
    end

    ret += (exdam + sea_dike_cost_investment + sea_dike_cost_maintenance + migration_cost) * (1-discount_rate)^(time_trajectory[i] - start_t)
  end
  ret
end

optimal_protection_computation(migration :: Bool, 
  slr_trajectory, popgrowth_trajectory, assetsgrowth_trajectory, time_trajectory :: Vector{Int}, dike_unitcost :: Float64, discount_rate :: Real, ref_year :: Int)  where {T1<:SSPType,T2<:SSPType} = function (lcm::LocalCoastalImpactModel)
  result = optimize(x -> slrcost_under_given_protection(lcm, migration, time_trajectory, slr_trajectory, popgrowth_trajectory, assetsgrowth_trajectory, dike_unitcost, discount_rate)(x), 1.0, 10000.0)
  
end

## compute optimal protection levels
optimal_protection_computation(migration :: Bool, slr_scenario::SLRScenarioReader, vlm :: Dict, quantile_ind::Int, slr_cell_indices_fp :: Dict{Int,Tuple{Int, Int}}, slr_cell_indices_cls :: Dict{Int,Tuple{Int, Int}}, sw_pop::SSPScenarioReader{T1}, sw_assets::SSPScenarioReader{T2}, ssp::String, dike_unitcost :: Tuple{Float64, Float64}, countryid :: String, time_trajectory :: Vector{Int}, discount_rate :: Real, ref_year :: Int, mtlock)  where {T1<:SSPType,T2<:SSPType} = function (lcm::LocalCoastalImpactModel)

  protection_level_old = lcm.protection_level
  time_span = time_trajectory[1] - ref_year

  local_exposure = exposure(lcm, Distributions.quantile(lcm.surge_model,0.99) + get_slr_value(slr_scenario, get_slr_scenario_index(slr_scenario, lcm, slr_cell_indices_fp, slr_cell_indices_cls, mtlock)[1], get_slr_scenario_index(slr_scenario, lcm, slr_cell_indices_fp, slr_cell_indices_cls, mtlock)[2], quantile_ind, time_trajectory[size(time_trajectory,1)])/1000);
  if ((local_exposure[2][1]<1) || (lcm.data.type=="CLS"))
    lcm.protection_level = 0
    sea_dike_heigth_old = lcm.data.sea_dike_heigth
    lcm.data.sea_dike_heigth=0
    lcm.data.sea_dike_cost_investment = abs(lcm.data.sea_dike_heigth - sea_dike_heigth_old) * lcm.data.coast_length * dike_unitcost[1] / time_span
    lcm.data.sea_dike_cost_maintenance = 0
  else
    slr_trajectory = map(t -> get_slr_value(slr_scenario, get_slr_scenario_index(slr_scenario, lcm, slr_cell_indices_fp, slr_cell_indices_cls, mtlock)[1], get_slr_scenario_index(slr_scenario, lcm, slr_cell_indices_fp, slr_cell_indices_cls, mtlock)[2], quantile_ind, t)/1000, time_trajectory)
    popgrowth_trajectory = map(t -> ssp_get_growth_factor(sw_pop, "Population", countryid, ssp, ref_year, t, false), time_trajectory)
    assetsgrowth_trajectory = map(t -> ssp_get_growth_factor(sw_assets, "GDP|PPP", countryid, ssp, ref_year, t, false), time_trajectory)

    # if we minimize here from 0.0 instead of 1.0 there is a fail (logarithm of negative) 
        
    cost_no_protection = slrcost_under_given_protection(lcm, migration, time_trajectory, slr_trajectory, popgrowth_trajectory, assetsgrowth_trajectory, dike_unitcost, discount_rate)(0.0)
    min_pl = if cost_no_protection<result.minimum 0 else result.minimizer end

    lcm.protection_level = min_pl
    sea_dike_heigth_old = lcm.data.sea_dike_heigth
    lcm.data.sea_dike_heigth = (lcm.protection_level>0) ? Distributions.quantile(lcm.surge_model,1-1/lcm.protection_level) : 0
    # the case after the ":" is dike lowering - by now we do not associate cost with that
    lcm.data.sea_dike_cost_investment = ((lcm.data.sea_dike_heigth >= sea_dike_heigth_old) ? abs(lcm.data.sea_dike_heigth - sea_dike_heigth_old) * lcm.data.coast_length * dike_unitcost[1] : 0) / time_span
    lcm.data.sea_dike_cost_maintenance = lcm.data.sea_dike_heigth * lcm.data.coast_length * dike_unitcost[1] * 0.01
  end

  if (lcm.protection_level==0)
    lcm.data.land_loss = max(0, exposure(lcm, Distributions.quantile(lcm.surge_model,0.01))[1] - lcm.data.total_land_loss) / time_span
    lcm.data.total_land_loss = max(0, exposure(lcm, quantile(lcm.surge_model,0.01))[1])
    if migration
      migration_data = remove_exposure_below!(lcm.coastal_plain_model, Distributions.quantile(lcm.surge_model,0.01))
      lcm.data.population_migration = migration_data[1] / time_span
      lcm.data.migration_cost = (migration_data[2]/1000000) / time_span
      lcm.data.sea_dike_cost_investment = 0
      lcm.data.sea_dike_cost_maintenance = 0
    end
  end

end